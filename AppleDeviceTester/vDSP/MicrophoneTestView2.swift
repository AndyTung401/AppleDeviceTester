//
//  MicrophoneTestView2.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/26.
//

import SwiftUI

struct MicrophoneTestView2: View {
    @StateObject private var audio = AudioEngine(fftSize: 4096)
    @State private var running = false
    
    var body: some View {
        VStack {
            SpectrumView(freqs: audio.freqs, dbs: audio.spectrum)
                .padding()
                .containerRelativeFrame(.vertical, count: 3, span: 2, spacing: 0)
            Spacer()
            Button {
                toggle()
            } label: {
                Image(systemName: running ? "pause.circle.fill" : "play.circle.fill")
                                        .resizable()
                                        .frame(width: 80, height: 80)
                                        .foregroundStyle(running ? .red : .green)
            }
            Spacer()

        }
        .onAppear {
            // nothing here; wait for user to start
        }
        .onDisappear {
            audio.stop()
        }
    }
    
    func toggle() {
        if running {
            audio.stop()
            running = false
        } else {
            do {
                try audio.start()
                running = true
            } catch {
                print("Audio start error:", error)
            }
        }
    }
}
