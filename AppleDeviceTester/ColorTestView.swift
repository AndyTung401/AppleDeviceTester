//
//  SwiftUIView.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/23.
//

import SwiftUI

private enum P3Color {
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
    @State private var color: P3Color = .black
    @Binding var hideStatusBar: Bool
    @State private var initialAlert: Bool = false
    var body: some View {
            ZStack {
                Color(color.toColor())
                    .onTapGesture {
                        switch color {
                        case .black:
                            color = .white
                        case .white:
                            color = .red
                        case .red:
                            color = .green
                        case .green:
                            color = .blue
                        case .blue:
                            color = .black
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
            .alert("Note:", isPresented: $initialAlert, actions: {
                Button("OK", role: .confirm) { }
            }, message: {
                Text("Tap anywhere to change color.\nSwipe right on the left edge to exit.")
            })
    }
}


#Preview("ContentView") {
    ContentView()
}
