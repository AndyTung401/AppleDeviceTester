//
//  ScreenBorderTestView.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/24.
//

import SwiftUI


struct ScreenBorderTestView: View {
    @Binding var hideStatusBar: Bool
    @State private var borderWidth = 3.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                ConcentricRectangle(corners: .concentric, isUniform: true)
                    .stroke(style: StrokeStyle(lineWidth: CGFloat(borderWidth)))
                    .foregroundStyle(.red)
                VStack(spacing: 10) {
                    VStack {
                        HStack {
                            Text("Border Width:")
                            Text(String(format: "%.2f", borderWidth))
                        }
                        
                        Slider(value: $borderWidth, in: 1...10, step: 1.0)
                            .padding(.horizontal)
                    }
                    .padding()
                    .glassEffect()
                    .containerRelativeFrame(.horizontal, count: 5, span: 4, spacing: 0)
                    
                    
                }
                
                VStack {
                    Spacer()
                    Label("Swipe right on the left edge to exit.", systemImage: "hand.draw")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .padding()
                        .glassEffect()
                        .padding()
                }
                .padding()
            }
            .navigationBarBackButtonHidden()
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
    ContentView()
}
