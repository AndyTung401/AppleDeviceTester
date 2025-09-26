//
//  MicrophoneTestView.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/26.
//

import SwiftUI
import AVFoundation
import Accelerate
import Combine

final class SpectrumAudioManager: ObservableObject {
    @Published var magnitudes: [Float] = [] // normalized 0...1
    private let engine = AVAudioEngine()
    private var fftSetup: FFTSetup?
    private let fftSize: Int = 1024 // power of two
    private let log2n: vDSP_Length
    private var window: [Float]
    private let inputFormat: AVAudioFormat
    private var isRunning = false

    init() {
        log2n = vDSP_Length(log2(Float(fftSize)))
        fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))
        window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))

        let inputNode = engine.inputNode
        inputFormat = inputNode.inputFormat(forBus: 0)

        // prepare initial empty magnitudes
        magnitudes = [Float](repeating: 0.0, count: fftSize / 2)
    }

    deinit {
        if let setup = fftSetup { vDSP_destroy_fftsetup(setup) }
    }

    func requestPermissionAndStart() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted { try? self.start() }
                }
            }
        case .granted:
            try? start()
        case .denied:
            // permission denied - app should instruct user to enable in Settings
            break
        @unknown default:
            break
        }
    }

    func startStoppingToggle() {
        if isRunning { stop() } else { requestPermissionAndStart() }
    }

    func start() throws {
        guard !isRunning else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default, options: [])
        try session.setActive(true, options: [])

        let inputNode = engine.inputNode
        let bus = 0
        let inputFormat = inputNode.inputFormat(forBus: bus)

        let desiredFrames: AVAudioFrameCount = AVAudioFrameCount(fftSize)

        // 不要再 connect 到 mainMixerNode，避免播放
        inputNode.removeTap(onBus: bus)
        inputNode.installTap(onBus: bus,
                             bufferSize: desiredFrames,
                             format: inputFormat) { [weak self] (buffer, when) in
            self?.process(buffer: buffer)
        }

        engine.prepare()
        try engine.start()
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        // zero out magnitudes
        DispatchQueue.main.async { self.magnitudes = [Float](repeating: 0.0, count: self.fftSize/2) }
    }

    private func process(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let channelDataPointer = channelData
        let frameLength = Int(buffer.frameLength)

        // If incoming frame length < fftSize, create a local buffer with zero padding
        var samples = [Float](repeating: 0, count: fftSize)

        // copy min(frameLength, fftSize)
        let copyCount = min(frameLength, fftSize)
        for i in 0..<copyCount { samples[i] = channelDataPointer[i] }

        // apply window
        vDSP_vmul(samples, 1, window, 1, &samples, 1, vDSP_Length(fftSize))

        // convert to split complex
        var realp = [Float](repeating: 0, count: fftSize/2)
        var imagp = [Float](repeating: 0, count: fftSize/2)
        samples.withUnsafeBufferPointer { ptr in
            ptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: fftSize/2) { complexPtr in
                // prepare split complex
                var split = DSPSplitComplex(realp: &realp, imagp: &imagp)
                // convert interleaved to split
                vDSP_ctoz(complexPtr, 2, &split, 1, vDSP_Length(fftSize/2))

                // perform FFT
                if let setup = fftSetup {
                    vDSP_fft_zrip(setup, &split, 1, log2n, FFTDirection(FFT_FORWARD))

                    // compute magnitudes
                    var magnitudes = [Float](repeating: 0.0, count: fftSize/2)
                    vDSP_zvmags(&split, 1, &magnitudes, 1, vDSP_Length(fftSize/2))

                    // convert to dB
                    var zero: Float = 1.0e-10
                    vDSP_vsmsa(magnitudes, 1, [1.0], &zero, &magnitudes, 1, vDSP_Length(fftSize/2))
                    var roots = [Float](repeating: 0.0, count: fftSize/2)
                    vvsqrtf(&roots, magnitudes, [Int32(fftSize/2)])

                    var asdB = [Float](repeating: 0.0, count: fftSize/2)
                    var one: Float = 1
                    // 20*log10(roots)
                    vvlog10f(&asdB, roots, [Int32(fftSize/2)])
                    vDSP_vsmul(asdB, 1, [20.0], &asdB, 1, vDSP_Length(fftSize/2))

                    // normalize dB to 0...1 range for display
                    let minDb: Float = -50
                    let maxDb: Float = 50
                    var normalized = [Float](repeating: 0.0, count: fftSize/2)
                    for i in 0..<fftSize/2 {
                        let v = (asdB[i] - minDb) / (maxDb - minDb)
                        normalized[i] = max(0, min(1, v))
                    }

                    DispatchQueue.main.async {
                        self.magnitudes = normalized
                    }
                }
            }
        }
    }
}

struct MicrophoneTestView: View {
    @StateObject private var audioManager = SpectrumAudioManager()
    @State private var isRunning = false

    var body: some View {
        VStack(spacing: 24) {
            Text("實時頻譜顯示")
                .font(.title)
                .padding(.top, 40)

            SpectrumView(bands: audioManager.magnitudes)
                .frame(height: 240)
                .padding(.horizontal)

            HStack(spacing: 20) {
                Button(action: {
                    audioManager.requestPermissionAndStart()
                    isRunning = true
                }) {
                    Text("開始")
                        .frame(minWidth: 100)
                        .padding()
                        .background(isRunning ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    audioManager.stop()
                    isRunning = false
                }) {
                    Text("暫停")
                        .frame(minWidth: 100)
                        .padding()
                        .background(isRunning ? Color.red : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            Spacer()

            Text("請確認 Info.plist 已包含 NSMicrophoneUsageDescription")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.bottom)
        }
    }
}

struct SpectrumView: View {
    var bands: [Float]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let bandCount = max(1, min(bands.count, 64))
            let samplesPerBand = max(1, bands.count / bandCount)

            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<bandCount, id: \.self) { i in
                    let start = i * samplesPerBand
                    let end = min(start + samplesPerBand, bands.count)
                    let slice = bands[start..<end]
                    let avg = slice.reduce(0, +) / Float(slice.count)

                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: (width / CGFloat(bandCount)) - 2,
                               height: CGFloat(avg) * height)
                        .opacity(0.9)
                }
            }
            .frame(width: width, height: height, alignment: .bottom)
            .background(Color(uiColor: .systemGray6))
            .cornerRadius(8)
        }
    }
}

#Preview {
    MicrophoneTestView()
}
