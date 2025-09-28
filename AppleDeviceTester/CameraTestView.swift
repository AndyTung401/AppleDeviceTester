//
//  CameraTestView.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/28.
//

import UIKit
import AVFoundation
import SwiftUI

// MARK: - Camera Position & Type Enum
enum CameraType {
    case frontUlraWide
    case frontWide
    case ultraWide
    case wide
    case telephoto
}

// MARK: - UIKit Camera ViewController
class CameraViewController: UIViewController {
    var previewView: UIView!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var captureDevice: AVCaptureDevice!
    let session = AVCaptureSession()
    
    func availableCameraTypes() -> [CameraType] {
        var types: [CameraType] = []
        if getDevice(for: .frontUlraWide) != nil { types.append(.frontUlraWide) }
        if getDevice(for: .frontWide) != nil { types.append(.frontWide) }
        if getDevice(for: .ultraWide) != nil { types.append(.ultraWide) }
        if getDevice(for: .wide) != nil { types.append(.wide) }
        if getDevice(for: .telephoto) != nil { types.append(.telephoto) }
        return types
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewView = UIView(frame: view.bounds)
        previewView.contentMode = .scaleAspectFit
        view.addSubview(previewView)
        
        setupAVCapture(cameraType: .wide) // 預設廣角鏡頭
    }
    
    override var shouldAutorotate: Bool {
        if UIDevice.current.orientation == .landscapeLeft ||
            UIDevice.current.orientation == .landscapeRight ||
            UIDevice.current.orientation == .unknown {
            return false
        } else {
            return true
        }
    }
}

// MARK: - AVCapture delegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewView.frame = view.bounds
        previewLayer?.frame = previewView.bounds
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // 讓相機忽略 safe area
        previewView.frame = view.bounds
        previewLayer?.frame = previewView.bounds
    }
    
    /// 依據鏡頭類型找對應的 AVCaptureDevice
    func getDevice(for type: CameraType) -> AVCaptureDevice? {
        switch type {
        case .frontUlraWide:
            return AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .front)
        case .frontWide:
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        case .ultraWide:
            return AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
        case .wide:
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        case .telephoto:
            return AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)
        }
    }
    
    func setupAVCapture(cameraType: CameraType) {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // 移除舊的 Input
        for input in session.inputs {
            session.removeInput(input)
        }
        
        guard let device = getDevice(for: cameraType) else {
            print("找不到指定鏡頭: \(cameraType)")
            session.commitConfiguration()
            return
        }
        captureDevice = device
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
        } catch {
            print("無法建立鏡頭 Input: \(error.localizedDescription)")
        }
        
        // 移除舊的 Output
        for output in session.outputs {
            session.removeOutput(output)
        }
        
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }
        
        // 預覽畫面
        
        if previewLayer == nil {
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspect
            previewLayer.frame = previewView.bounds
            previewView.layer.addSublayer(previewLayer)
        } else {
            previewLayer.session = session
        }
        
        session.commitConfiguration()
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // do stuff here
    }
    
    func stopCamera() {
        session.stopRunning()
    }
}

// MARK: - SwiftUI Wrapper
struct CameraPreview: UIViewControllerRepresentable {
    @Binding var cameraType: CameraType
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        uiViewController.setupAVCapture(cameraType: cameraType)
    }
}

struct CameraTestView: View {
    @State var cameraType: CameraType = .wide
    @State var availableTypes: [CameraType] = []
    var body: some View {
        VStack {
            CameraPreview(cameraType: $cameraType)
                .aspectRatio(3/4, contentMode: .fit)
            VStack {
                Picker("Lens", selection: $cameraType) {
                    ForEach(availableTypes, id: \.self) { type in
                        Image(systemName: label(for: type)).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                Text(description(for: cameraType))
                    .fontDesign(.monospaced)
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .animation(.easeInOut(duration: 0.3), value: cameraType)
            }
            Spacer()
        }
        .onAppear {
            // 初始化時檢查可用鏡頭
            let vc = CameraViewController()
            availableTypes = vc.availableCameraTypes()
            if !availableTypes.contains(cameraType) {
                cameraType = availableTypes.first ?? .wide
            }
        }
    }
    
    func label(for type: CameraType) -> String {
            switch type {
            case .frontUlraWide: return "person.2.circle.fill"
            case .frontWide: return "person.circle.fill"
            case .ultraWide: return "mountain.2.circle.fill"
            case .wide: return "tree.circle.fill"
            case .telephoto: return "scope"
            }
        }
    
    func description(for type: CameraType) -> String {
            switch type {
            case .frontUlraWide: return "Ultra Wide (Front)"
            case .frontWide: return "Wide (Front)"
            case .ultraWide: return "Ultra Wide (Back)"
            case .wide: return "Wide (Back)"
            case .telephoto: return "Telephoto (Back)"
            }
        }
}
