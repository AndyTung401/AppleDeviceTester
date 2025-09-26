//
//  AudioEngine.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/26.
//

import Foundation
import AVFoundation
import Accelerate
import Combine

final class AudioEngine: ObservableObject {
    @Published var spectrum: [Float] = []
    @Published var freqs: [Float] = []
    
    private let engine = AVAudioEngine()
    private var inputFormat: AVAudioFormat!
    private var fftSetup: OpaquePointer? = nil
    private let fftSize: Int
    private let halfSize: Int
    private let log2n: vDSP_Length
    private var hannWindow: [Float]
    
    private var lastUpdate = Date(timeIntervalSince1970: 0)
    private let minUpdateInterval: TimeInterval = 0.05 // ~20 FPS cap
    
    init(fftSize: Int = 4096) {
        // fftSize must be power of 2
        self.fftSize = fftSize
        self.halfSize = fftSize / 2
        self.log2n = vDSP_Length(log2(Float(fftSize)))
        self.hannWindow = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&hannWindow, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        
        // FFT setup (vDSP C API)
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
    }
    
    deinit {
        if let s = fftSetup {
            vDSP_destroy_fftsetup(s)
        }
    }
    
    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers])
        try session.setActive(true, options: [])
        session.requestRecordPermission { granted in
            // 這裡你可以檢查 granted
        }

        let inputNode = engine.inputNode   // ✅ 不用 Optional 綁定
        inputFormat = inputNode.outputFormat(forBus: 0)
        let sampleRate = Float(inputFormat.sampleRate)

        // precompute frequency axis
        freqs = (0..<halfSize).map { i in
            Float(i) * sampleRate / Float(fftSize)
        }

        let bufferSize = AVAudioFrameCount(fftSize)
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] (buffer, time) in
            self?.process(buffer: buffer, sampleRate: sampleRate)
        }

        engine.prepare()
        try engine.start()
    }
    
    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch { }
        freqs = []
        spectrum = []
    }
    
    private func process(buffer: AVAudioPCMBuffer, sampleRate: Float) {
        // Throttle UI updates
        if Date().timeIntervalSince(lastUpdate) < minUpdateInterval { return }
        lastUpdate = Date()
        
        guard let channelData = buffer.floatChannelData else { return }
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        // We'll mix down channels to mono by averaging first channel(s)
        var input = [Float](repeating: 0, count: fftSize)
        // If frameLength < fftSize, zero-pad (we already had input initialized as zeros)
        let copyCount = min(frameLength, fftSize)
        
        if channelCount == 1 {
            // mono: 安全 memcpy 到 input 的緩衝
            input.withUnsafeMutableBufferPointer { dstPtr in
                guard let base = dstPtr.baseAddress else { return }
                let src = channelData[0]
                memcpy(base, src, copyCount * MemoryLayout<Float>.size)
                // rest of input already zero-padded
            }
        } else {
            // average channels into mono (累加到 input，剩餘位置為 0)
            for ch in 0..<channelCount {
                let ptr = channelData[ch]
                // 把每個 channel 的前 copyCount 樣本累加到 input
                input.withUnsafeMutableBufferPointer { dstPtr in
                    guard let dst = dstPtr.baseAddress else { return }
                    for i in 0..<copyCount {
                        dst[i] += ptr[i]
                    }
                }
            }
            // 平均 -- 使用新的輸出緩衝 scaled（不要原地修改 input）
            var scaled = [Float](repeating: 0, count: fftSize)
            var inv = 1.0 / Float(channelCount)
            // scale 全長 fftSize（未被填過的部分就是 0）
            vDSP_vsmul(input, 1, &inv, &scaled, 1, vDSP_Length(fftSize))
            input = scaled
        }
        
        // apply window (Hann)  -> windowed is separate buffer
        var windowed = [Float](repeating: 0, count: fftSize)
        vDSP_vmul(input, 1, hannWindow, 1, &windowed, 1, vDSP_Length(fftSize))
        
        // Prepare complex buffer for FFT: convert real vector to split-complex
        let nOver2 = fftSize / 2
        var realp = [Float](repeating: 0, count: nOver2)
        var imagp = [Float](repeating: 0, count: nOver2)
        realp.withUnsafeMutableBufferPointer { realPtr in
            imagp.withUnsafeMutableBufferPointer { imagPtr in
                var split = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                
                // Pack real input into complex form required by vDSP_fft_zrip
                windowed.withUnsafeBufferPointer { wptr in
                    // reinterpret as DSPComplex pairs and convert to split
                    wptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: nOver2) { typeConvertedTransferBuffer in
                        vDSP_ctoz(typeConvertedTransferBuffer, 2, &split, 1, vDSP_Length(nOver2))
                    }
                }
                
                // Execute FFT
                if let setup = fftSetup {
                    vDSP_fft_zrip(setup, &split, 1, log2n, FFTDirection(FFT_FORWARD))
                    
                    // After forward, need to scale the results
                    var scale: Float = 1.0 / Float(fftSize)
                    vDSP_vsmul(split.realp, 1, &scale, split.realp, 1, vDSP_Length(nOver2))
                    vDSP_vsmul(split.imagp, 1, &scale, split.imagp, 1, vDSP_Length(nOver2))
                    
                    // magnitude
                    var magnitudes = [Float](repeating: 0.0, count: nOver2)
                    vDSP_zvabs(&split, 1, &magnitudes, 1, vDSP_Length(nOver2))
                    
                    // threshold floor (避免 log(0)) - 以簡單迴圈處理
                    let floorVal: Float = 1e-20
                    for i in 0..<nOver2 {
                        if magnitudes[i] < floorVal { magnitudes[i] = floorVal }
                    }
                    
                    // convert to dB (20 * log10)
                    var db = [Float](repeating: 0, count: nOver2)
                    for i in 0..<nOver2 {
                        db[i] = 20.0 * log10f(magnitudes[i])
                    }
                    
                    // publish on main thread
                    DispatchQueue.main.async { [weak self] in
                        self?.spectrum = db
                        // freqs already set at start
                    }
                }
            }
        }
    }
}
