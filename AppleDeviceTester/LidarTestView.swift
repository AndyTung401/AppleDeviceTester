//
//  LidarTestView.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/28.
//

import SwiftUI
import ARKit
import Combine

struct LidarTestView: View {
    @StateObject private var arDelegate = LidarSessionDelegate()
    @State private var isRunning = false
    @State private var maxDepth: Float = 1.0   // <-- 可調整的最大深度
    
    var body: some View {
        VStack {
            VStack {
                if let uiImage = arDelegate.grayMapImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    ContentUnavailableView("Session paused.", systemImage: "pause.fill")
                }
            }
            .cornerRadius(8)
            .glassEffect(in: .rect(cornerRadius: 8))
            .containerRelativeFrame(.vertical, count: 3, span: 2, spacing: 0)
            .padding()
            
            
            // 控制 maxDepth 的 slider
            VStack {
                Text(String(format: "Max depth: %.2f m", maxDepth))
                Slider(value: $maxDepth, in: 0.2...5.0, step: 0.1)
            }
            .padding(.horizontal)
            .padding(.horizontal)
            
            Button {
                isRunning.toggle()
                if isRunning {
                    arDelegate.startSession()
                } else {
                    arDelegate.pauseSession()
                }
            } label: {
                Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(isRunning ? .red : .green)
                    .padding()
            }
            .padding(.bottom)
        }
        .onChange(of: maxDepth) { _, newValue in
            arDelegate.maxDepth = newValue  // <-- 傳給 delegate
        }
        .onAppear {
            arDelegate.maxDepth = maxDepth  // 初始化同步
        }
    }
}

class LidarSessionDelegate: NSObject, ObservableObject, ARSessionDelegate {
    private var session: ARSession?
    @Published var grayMapImage: UIImage? = nil
    
    // 讓 View 可以改變的參數
    var maxDepth: Float = 1.0
    
    func startSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth // 要求深度
        let session = ARSession()
        session.delegate = self
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        self.session = session
    }
    
    func pauseSession() {
        session?.pause()
        session = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { 
            self.grayMapImage = nil
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let sceneDepth = frame.sceneDepth else { return }
        let depthMap = sceneDepth.depthMap
        self.grayMapImage = convertToGrayImage(from: depthMap)
    }
    
    private func convertToGrayImage(from pixelBuffer: CVPixelBuffer) -> UIImage? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let buffer = baseAddress.assumingMemoryBound(to: Float32.self)
        
        let depthValues = UnsafeBufferPointer(start: buffer, count: width * height)
        
        var pixels = [UInt8](repeating: 0, count: width * height)
        for i in 0..<width*height {
            let depth = min(depthValues[i], maxDepth)
            let normalizedFloat = (1.0 - depth / maxDepth) * 255.0
            let clamped = max(0, min(255, normalizedFloat))
            pixels[i] = UInt8(clamped)
        }
        
        // 建立 CGImage
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let provider = CGDataProvider(data: NSData(bytes: pixels, length: pixels.count)) else { return nil }
        
        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else { return nil }
        
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
    }
}

#Preview {
    LidarTestView()
}
