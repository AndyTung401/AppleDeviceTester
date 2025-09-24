//
//  SwiftUIView.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/23.
//

import SwiftUI

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

enum P3Color {
    case red
    case green
    case blue
    case black
    case white
    
    func toColor() -> Color {
        switch self {
        case .red:
            return Color(.displayP3, red: 1, green: 0, blue: 0)
        case .green:
            return Color(.displayP3, red: 0, green: 1, blue: 0)
        case .blue:
            return Color(.displayP3, red: 0, green: 0, blue: 1)
        case .black:
            return Color(.displayP3, red: 0, green: 0, blue: 0)
        case .white:
            return Color(.displayP3, red: 1, green: 1, blue: 1)
        }
    }
}

struct ColorTestView: View {
    @State var color: P3Color = .white
    @Binding var hideStatusBar: Bool
    @State private var initialAlert: Bool = false
    var body: some View {
            ZStack {
                Color(color.toColor())
                    .onTapGesture {
                        switch color {
                        case .red:
                            color = .green
                        case .green:
                            color = .blue
                        case .blue:
                            color = .white
                        case .white:
                            color = .black
                        case .black:
                            color = .red
                        }
                    }
            }
            .navigationBarBackButtonHidden(true)
            .ignoresSafeArea()
            .onAppear {
                withAnimation {
                    initialAlert = true
                    hideStatusBar = true
                }
            }
            .onDisappear {
                withAnimation {
                    hideStatusBar = false
                }
            }
            .alert("Tap anywhere to change color.\nSwipe right on the left edge to exit.", isPresented: $initialAlert) {
                Button("OK", role: .cancel) { }
            }
    }
}


#Preview("ContentView") {
    ContentView()
}
