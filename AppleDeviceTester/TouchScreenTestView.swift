//
//  TouchScreenTestView.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/24.
//

import SwiftUI

struct TouchScreenTestView: View {
    @Binding var hideStatusBar: Bool
    @State private var lines: [[CGPoint]] = [] // 多條線，每條線是 [CGPoint]
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white // 背景
                
                // 畫出所有線條
                ForEach(0..<lines.count, id: \.self) { index in
                    Path { path in
                        guard let first = lines[index].first else { return }
                        path.move(to: first)
                        for point in lines[index].dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(Color.red, lineWidth: 5)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let location = value.location
                        if geo.frame(in: .local).contains(location) {
                            if lines.isEmpty || value.translation == .zero {
                                // 開始新的一條線
                                lines.append([location])
                            } else {
                                // 在目前的線條加上新的點
                                lines[lines.count - 1].append(location)
                            }
                        }
                    }
                    .onEnded { _ in
                        // 結束時什麼都不用清除，保留線條
                    }
            )
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation {
                hideStatusBar = true
            }
        }
        .onDisappear {
            withAnimation {
                hideStatusBar = false
            }
        }
    }
}

#Preview {
    TouchScreenTestView(hideStatusBar: .constant(true))
}
