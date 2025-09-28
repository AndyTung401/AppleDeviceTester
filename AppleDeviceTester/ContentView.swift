//
//  ContentView.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/23.
//

import SwiftUI

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

struct ContentView: View {
    @State var hideStatusBar: Bool = false
    
    func navLink<Destination: View>(_ title: String, _ symbol: String, _ destination: Destination) -> some View {
        NavigationLink {
            destination
        } label: {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.background)
                .aspectRatio(1, contentMode: .fit)
                .glassEffect(in: .rect(cornerRadius: 20))
                .overlay {
                    VStack(spacing: 5) {
                        Image(systemName: symbol)
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                            .frame(height: 40)
                        Text(title)
                            .font(.subheadline)
                    }
                }
        }
        .buttonStyle(.plain)
    }
    
    
    var body: some View {
        NavigationStack {
            Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                HStack {
                    Text("Screen")
                        .fontWeight(.semibold)
                        .foregroundStyle(.gray)

                    Spacer()
                        .border(.red)
                }
                .padding(.horizontal)
                GridRow {
                    navLink("Display Color", "iphone.pattern.diagonalline", ColorTestView(hideStatusBar: $hideStatusBar))
                    
                    navLink("Screen Border", "rectangle.expand.diagonal", ScreenBorderTestView(hideStatusBar: $hideStatusBar))
                    
                    navLink("Touch Screen", "hand.tap.fill", TouchScreenTestView(hideStatusBar: $hideStatusBar))
                }
                
                HStack {
                    Text("Sounds & Haptics")
                        .fontWeight(.semibold)
                        .foregroundStyle(.gray)

                    Spacer()
                        .border(.red)
                }
                .padding(.horizontal)
                GridRow {
                    navLink("Haptics", "iphone.radiowaves.left.and.right", HapticTestView())
                    
                    navLink("Speaker", "speaker.wave.3.fill", SpeakerTestView())
                    
                    navLink("Microphone", "waveform", MicrophoneTestView())
                }
                
                HStack {
                    Text("Camera")
                        .fontWeight(.semibold)
                        .foregroundStyle(.gray)

                    Spacer()
                        .border(.red)
                }
                .padding(.horizontal)
                GridRow {
                    navLink("Lidar", "wave.3.right", LidarTestView())
                    
                    navLink("Camera", "camera.fill", CameraTestView())
                    
                    navLink("Flishlight", "flashlight.off.fill", FlashlightTestView())
                }
                
                HStack {
                    Text("Others")
                        .fontWeight(.semibold)
                        .foregroundStyle(.gray)

                    Spacer()
                        .border(.red)
                }
                .padding(.horizontal)
                GridRow {
                    navLink("Biometrics", "faceid", BiometricsTestView())
                    
                    navLink("Camera", "camera.fill", CameraTestView())
                    
                    navLink("Flishlight", "flashlight.off.fill", FlashlightTestView())
                }
                
                Spacer()
            }
            .padding(20)
            
        }
        .statusBarHidden(hideStatusBar)
    }
}

#Preview {
    ContentView()
}

