//
//  LidarTestView.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/28.
//

import SwiftUI
import ARKit
import AVFoundation
import Combine

enum DepthMode {
    case rearLiDAR
    case frontTrueDepth
}

struct LidarTestView: View {
    @StateObject private var arDelegate = LidarSessionDelegate()
    @State private var isRunning = false
    @State private var maxDepth: Float = 1.0   // <-- 可調整的最大深度
    
    // 依模式檢查支援
    @State private var supportsDepth = false
    @State private var mode: DepthMode = .rearLiDAR
    
    var body: some View {
        VStack {
            VStack {
                if !supportsDepth {
                    ContentUnavailableView("此模式的裝置不支援深度", systemImage: "cube.transparent")
                } else if let uiImage = arDelegate.grayMapImage {
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
                    .disabled(!supportsDepth)
            }
            .padding(.horizontal)
            .padding(.horizontal)
            
            // 開始/暫停 + 切換鏡頭按鈕
            ZStack {
                Button {
                    isRunning.toggle()
                    if isRunning {
                        arDelegate.startSession()
                    } else {
                        arDelegate.pauseSession()
                    }
                } label: {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.background)
                        .padding()
                        .glassEffect(.clear.tint(isRunning ? .red : .green), in: .circle)
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                }
                .buttonStyle(.plain)
                .disabled(!supportsDepth)
                
                HStack {
                    Spacer()
                    Button {
                        // 切換模式
                        let newMode: DepthMode = (mode == .rearLiDAR) ? .frontTrueDepth : .rearLiDAR
                        mode = newMode
                        supportsDepth = Self.isModeSupported(newMode)
                        arDelegate.setMode(newMode)
                        
                        if isRunning && !supportsDepth {
                            isRunning = false
                            arDelegate.pauseSession()
                        } else if isRunning && supportsDepth {
                            arDelegate.restartSession()
                        }
                    } label: {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.camera.fill")
                            .padding()
                            .glassEffect(in: .circle)
                    }
                    .buttonStyle(.plain)
                    .disabled(!Self.hasAnyDepthSupport)
                    .padding()
                }
            }
            .padding(.bottom)
        }
        .onChange(of: maxDepth) { _, newValue in
            arDelegate.maxDepth = newValue  // <-- 傳給 delegate
        }
        .onAppear {
            arDelegate.maxDepth = maxDepth  // 初始化同步
            arDelegate.setMode(mode)
            supportsDepth = Self.isModeSupported(mode)
        }
    }
}

extension LidarTestView {
    static func isModeSupported(_ mode: DepthMode) -> Bool {
        switch mode {
        case .rearLiDAR:
            return ARWorldTrackingConfiguration.isSupported
            && ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
        case .frontTrueDepth:
            return ARFaceTrackingConfiguration.isSupported
        }
    }
    
    static var hasAnyDepthSupport: Bool {
        isModeSupported(.rearLiDAR) || isModeSupported(.frontTrueDepth)
    }
}

class LidarSessionDelegate: NSObject, ObservableObject, ARSessionDelegate {
    private var session: ARSession?
    @Published var grayMapImage: UIImage? = nil
    
    // 讓 View 可以改變的參數
    var maxDepth: Float = 1.0
    private(set) var mode: DepthMode = .rearLiDAR
    
    func setMode(_ newMode: DepthMode) {
        self.mode = newMode
    }
    
    func startSession() {
        switch mode {
        case .rearLiDAR:
            guard ARWorldTrackingConfiguration.isSupported,
                  ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) else {
                grayMapImage = nil
                return
            }
            let configuration = ARWorldTrackingConfiguration()
            configuration.frameSemantics = .sceneDepth
            let session = ARSession()
            session.delegate = self
            session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            self.session = session
            
        case .frontTrueDepth:
            guard ARFaceTrackingConfiguration.isSupported else {
                grayMapImage = nil
                return
            }
            let configuration = ARFaceTrackingConfiguration()
            let session = ARSession()
            session.delegate = self
            session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            self.session = session
        }
    }
    
    func restartSession() {
        pauseSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.startSession()
        }
    }
    
    func pauseSession() {
        session?.pause()
        session = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.grayMapImage = nil
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        switch mode {
        case .rearLiDAR:
            guard let sceneDepth = frame.sceneDepth else { return }
            let depthMap = sceneDepth.depthMap
            if let img = convertToGrayImage(from: depthMap, orientation: .right) {
                DispatchQueue.main.async {
                    self.grayMapImage = img
                }
            }
        case .frontTrueDepth:
            guard var depthData = frame.capturedDepthData else { return }
            if depthData.depthDataType != kCVPixelFormatType_DepthFloat32 {
                depthData = depthData.converting(toDepthDataType: kCVPixelFormatType_DepthFloat32)
            }
            let depthMap = depthData.depthDataMap
            // 前鏡頭做水平鏡像（不旋轉）：upMirrored
            if let img = convertToGrayImage(from: depthMap, orientation: .right) {
                DispatchQueue.main.async {
                    self.grayMapImage = img
                }
            }
        }
    }
    
    // 將深度轉為灰階影像：
    // - 無效深度（NaN/Inf/<=0）直接映射為黑色，避免邊界白邊
    // - 有效深度：近=白、遠=黑（可用 maxDepth 控制範圍）
    private func convertToGrayImage(from pixelBuffer: CVPixelBuffer, orientation: UIImage.Orientation) -> UIImage? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let buffer = baseAddress.assumingMemoryBound(to: Float32.self)
        
        let depthValues = UnsafeBufferPointer(start: buffer, count: width * height)
        
        var pixels = [UInt8](repeating: 0, count: width * height)
        let localMaxDepth = max(self.maxDepth, 0.001)
        let count = width * height
        
        for i in 0..<count {
            let d = depthValues[i]
            // 無效/無深度：黑色（0）
            if !d.isFinite || d <= 0 {
                pixels[i] = 0
                continue
            }
            // 正常映射
            let depth = min(d, localMaxDepth)
            let normalizedFloat = (1.0 - depth / localMaxDepth) * 255.0
            let clamped = max(0, min(255, normalizedFloat))
            pixels[i] = UInt8(clamped)
        }
        
        // 建立 CGImage（8-bit 灰階，無 alpha）
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
        
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
    }
}

#Preview {
    LidarTestView()
}
