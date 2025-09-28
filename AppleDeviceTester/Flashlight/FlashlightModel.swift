//
//  FlashlightModel.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/28.
//

import AVFoundation
import Combine

public enum TorchError: LocalizedError {
    case deviceUnavailable
    case noTorchHardware
    case torchUnavailable
    case modeNotSupported(AVCaptureDevice.TorchMode)
    case configurationFailed(underlying: Error)
    
    public var errorDescription: String? {
        switch self {
        case .deviceUnavailable:
            return "找不到可用的相機裝置。"
        case .noTorchHardware:
            return "此裝置沒有手電筒硬體。"
        case .torchUnavailable:
            return "目前無法使用手電筒（可能是相機配置不允許）。"
        case .modeNotSupported(let mode):
            return "此裝置不支援手電筒模式：\(mode)。"
        case .configurationFailed(let underlying):
            return "相機配置鎖定失敗：\(underlying.localizedDescription)"
        }
    }
}

/// 可觀察的手電筒 Model（使用 KVO 同步硬體狀態）
public final class TorchModel: ObservableObject {
    // Published 狀態，供 SwiftUI 綁定
    @Published public private(set) var hasTorch: Bool = false
    @Published public private(set) var isTorchAvailable: Bool = false
    @Published public private(set) var isTorchActive: Bool = false
    @Published public private(set) var torchLevel: Float = 0
    @Published public private(set) var torchMode: AVCaptureDevice.TorchMode = .off
    
    public static var maxAvailableTorchLevel: Float {
        AVCaptureDevice.maxAvailableTorchLevel
    }
    
    private let device: AVCaptureDevice?
    private var observers: [NSKeyValueObservation] = []
    
    public init(position: AVCaptureDevice.Position = .back) {
        if let specified = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            self.device = specified
        } else {
            self.device = AVCaptureDevice.default(for: .video)
        }
        syncFromDevice()
        setupObservers()
    }
    
    deinit {
        observers.forEach { $0.invalidate() }
        observers.removeAll()
    }
    
    // MARK: - Public API
    
    public func toggleTorch(on: Bool) throws {
        try setTorchMode(on ? .on : .off)
    }
    
    public func setTorchMode(_ mode: AVCaptureDevice.TorchMode) throws {
        guard let device = device else { throw TorchError.deviceUnavailable }
        guard device.hasTorch else { throw TorchError.noTorchHardware }
        guard device.isTorchModeSupported(mode) else { throw TorchError.modeNotSupported(mode) }
        if mode != .off && !device.isTorchAvailable { throw TorchError.torchUnavailable }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = mode
            device.unlockForConfiguration()
            
            // 立即同步一次，並在極短延遲後再同步一次（硬體可能是非同步生效）
            syncFromDevice()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.syncFromDevice()
            }
        } catch {
            throw TorchError.configurationFailed(underlying: error)
        }
    }
    
    /// 設定亮度（>0 會自動開啟）
    public func setTorchModeOn(level: Float) throws {
        guard let device = device else { throw TorchError.deviceUnavailable }
        guard device.hasTorch else { throw TorchError.noTorchHardware }
        
        let maxLevel = min(1.0, Self.maxAvailableTorchLevel)
        let clamped = max(0.0, min(level, maxLevel))
        
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            
            if clamped <= 0 {
                device.torchMode = .off
            } else {
                guard device.isTorchAvailable else { throw TorchError.torchUnavailable }
                try device.setTorchModeOn(level: clamped)
            }
            
            // 同步狀態（含短延遲以等待硬體數值就緒）
            syncFromDevice()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.syncFromDevice()
            }
        } catch {
            throw TorchError.configurationFailed(underlying: error)
        }
    }
    
    public func isTorchModeSupported(_ mode: AVCaptureDevice.TorchMode) -> Bool {
        guard let device = device else { return false }
        return device.isTorchModeSupported(mode)
    }
    
    // MARK: - Private
    
    private func syncFromDevice() {
        guard let device = device else {
            hasTorch = false
            isTorchAvailable = false
            isTorchActive = false
            torchLevel = 0
            torchMode = .off
            return
        }
        DispatchQueue.main.async {
            self.hasTorch = device.hasTorch
            self.isTorchAvailable = device.isTorchAvailable
            self.isTorchActive = device.isTorchActive
            self.torchLevel = device.torchLevel
            self.torchMode = device.torchMode
        }
    }
    
    private func setupObservers() {
        guard let device = device else { return }
        
        let obs1 = device.observe(\.isTorchActive, options: [.initial, .new]) { [weak self] dev, _ in
            DispatchQueue.main.async { self?.isTorchActive = dev.isTorchActive }
        }
        let obs2 = device.observe(\.torchLevel, options: [.initial, .new]) { [weak self] dev, _ in
            DispatchQueue.main.async { self?.torchLevel = dev.torchLevel }
        }
        let obs3 = device.observe(\.isTorchAvailable, options: [.initial, .new]) { [weak self] dev, _ in
            DispatchQueue.main.async { self?.isTorchAvailable = dev.isTorchAvailable }
        }
        let obs4 = device.observe(\.torchMode, options: [.initial, .new]) { [weak self] dev, _ in
            DispatchQueue.main.async { self?.torchMode = dev.torchMode }
        }
        // hasTorch 幾乎不會在執行時變動，直接同步即可
        hasTorch = device.hasTorch
        
        observers = [obs1, obs2, obs3, obs4]
    }
}
