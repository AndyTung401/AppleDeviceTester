//
//  MicrophoneTestView2.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/26.
//

import SwiftUI

struct MicrophoneTestView: View {
    @StateObject private var audio = AudioEngine(fftSize: 4096)
    @State private var running = false
    
    var body: some View {
        VStack {
            SpectrumView(freqs: audio.freqs, dbs: audio.spectrum)
                .containerRelativeFrame(.vertical, count: 3, span: 2, spacing: 0)
                .padding()
            Spacer()
            Button {
                toggle()
            } label: {
                Image(systemName: running ? "pause.fill" : "play.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.background)
                    .padding()
                    .glassEffect(.clear.tint(running ? .red : .green), in: .circle)
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
            }
            .buttonStyle(.plain)
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
