//
//  SpeakerTestView.swift
//  AppleDeviceTester
//
//  Created by Andy on 2025/09/26.
//

import SwiftUI
import AVFoundation
import Combine

struct SpeakerTestView: View {
    @StateObject private var audioManager = SpeakerAudioManager()
    @State private var log2Frequency: Double = log2(440) // 初始是 440Hz
    
    var body: some View {
        ZStack {
            VStack {
                Image(systemName: "arrow.up")
                Text("Speaker Here")
                Spacer()
            }
            
            VStack {
                Spacer()
                Text("Speaker Here")
                Image(systemName: "arrow.down")
            }
            .padding()
            .ignoresSafeArea()
            
            VStack {
                Text("Sine Wave Generator")
                    .font(.title)
                    .bold()
                    .padding()
                
                Text("\(Int(pow(2, log2Frequency))) Hz")
                    .font(.title2)
                
                Slider(value: $log2Frequency,
                       in: log2(20)...log2(20000),
                       step: 0.01)
                .onChange(of: log2Frequency) { _, newValue in
                    audioManager.frequency = pow(2, newValue)
                }
                .padding()
                
                Button {
                    audioManager.togglePlay()
                } label: {
                    Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(audioManager.isPlaying ? .red : .green)
                }
                
                Text("Swipe right on the left edge to exit.")
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .padding()
            }
            .padding()
            .onAppear {
                audioManager.frequency = pow(2, log2Frequency) // 初始就設定頻率
            }
        }
        .navigationBarBackButtonHidden()
    }
}

// MARK: - 音訊管理
class SpeakerAudioManager: ObservableObject {
    private var engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!
    private var sampleRate: Double = 44100.0
    private var theta: Double = 0.0
    private var isSetup = false
    
    @Published var isPlaying = false
    @Published var frequency: Double = 440.0
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        // ⚡ 強制繞過靜音開關
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("❌ 無法設定 AVAudioSession: \(error)")
        }
        
        let output = engine.outputNode
        let format = output.inputFormat(forBus: 0)
        sampleRate = format.sampleRate
        
        sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            let freq = max(20.0, self.frequency) // 確保不會是 0
            let thetaIncrement = 2.0 * Double.pi * freq / self.sampleRate
            
            for frame in 0..<Int(frameCount) {
                let sampleVal = Float32(sin(self.theta))
                self.theta += thetaIncrement
                if self.theta > 2.0 * Double.pi {
                    self.theta -= 2.0 * Double.pi
                }
                
                for buffer in ablPointer {
                    let buf = buffer.mData!.assumingMemoryBound(to: Float32.self)
                    buf[frame] = sampleVal
                }
            }
            return noErr
        }
        
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: output, format: format)
        isSetup = true
    }
    
    func togglePlay() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }
    
    private func play() {
        guard isSetup else { return }
        do {
            theta = 0 // 確保每次播放從頭開始，不會靜音
            try engine.start()
            isPlaying = true
        } catch {
            print("❌ Engine start failed: \(error)")
        }
    }
    
    private func stop() {
        engine.pause()
        isPlaying = false
    }
}

#Preview {
    SpeakerTestView()
}
