//
//  FlashlightTestView.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/28.
//

import SwiftUI
import AVFoundation

// 讓 TorchError 可被 .alert(item:) 使用
extension TorchError: Identifiable {
    public var id: String { errorDescription ?? String(describing: self) }
}

struct FlashlightTestView: View {
    // 使用 @StateObject 讓 SwiftUI 觀察 TorchModel 狀態改變
    @StateObject private var torch = TorchModel()
    
    @State private var lastError: TorchError?
    @State private var desiredLevel: Float = 1.0
    
    var body: some View {
        List {
            row("Has Torch:", torch.hasTorch ? "Yes" : "No")
            row("Is Torch Available:", torch.isTorchAvailable ? "Yes" : "No")
            row("Is Torch Active:", torch.isTorchActive ? "Yes" : "No")
            row("Current Level:", String(format: "%.2f", torch.torchLevel))
            row("Mode:", String(describing: torch.torchMode))
            
            VStack {
                Text("Set brightness: \(String(format: "%.2f", desiredLevel))")
                Slider(
                    value: Binding(
                        get: { Double(desiredLevel) },
                        set: { desiredLevel = Float($0) }
                    ),
                    in: 0...1
                )
                .onChange(of: desiredLevel) { _, _ in
                    do {
                        try torch.setTorchModeOn(level: desiredLevel)
                    } catch {
                        handle(error)
                    }
                }
            }
            .padding(.vertical)
        }
        .monospacedDigit()
        .scrollDisabled(true)
        .onAppear {
            // 將 UI 切換狀態與目前硬體狀態對齊
            desiredLevel = max(torch.torchLevel, 0.0)
        }
        .alert(item: $lastError) { err in
            Alert(
                title: Text("錯誤"),
                message: Text(err.localizedDescription),
                dismissButton: .default(Text("好"))
            )
        }
    }
    
    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
        }
    }
    
    private func handle(_ error: Error) {
        if let torchError = error as? TorchError {
            lastError = torchError
        } else {
            lastError = .configurationFailed(underlying: error)
        }
    }
}
