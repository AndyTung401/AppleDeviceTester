//
//  ContentView.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/23.
//

import SwiftUI

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
                GridRow {
                    navLink("Display Color", "iphone.pattern.diagonalline", ColorTestView(hideStatusBar: $hideStatusBar))
                    
                    navLink("Screen Border", "rectangle.expand.diagonal", ScreenBorderTestView(hideStatusBar: $hideStatusBar))
                    
                    navLink("Screen Border", "rectangle.expand.diagonal", ScreenBorderTestView(hideStatusBar: $hideStatusBar))
                }
                GridRow {
                }
            }
            .padding(20)
            
        }
        .statusBarHidden(hideStatusBar)
    }
}

#Preview {
    ContentView()
}

