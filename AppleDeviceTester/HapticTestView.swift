//
//  HapticTestView.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/26.
//

import SwiftUI

struct HapticTestView: View {
    @State private var impact_soft: Bool = false
    @State private var impact_rigid: Bool = false
    @State private var impact_solid: Bool = false
    
    @State private var success: Bool = false
    @State private var warning: Bool = false
    @State private var error: Bool = false
    
    @State private var increase: Bool = false
    @State private var decrease: Bool = false
    @State private var levelChange: Bool = false
    
    @State private var alignment: Bool = false
    @State private var selection: Bool = false
    @State private var pathComplete: Bool = false
    
    @State private var start: Bool = false
    @State private var stop: Bool = false
    @State private var impact: Bool = false
    
    func buttonLabel(_ title: String, _ icon: String) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .foregroundStyle(.background)
            .aspectRatio(1, contentMode: .fit)
            .glassEffect(in: .rect(cornerRadius: 20))
            .overlay {
                VStack(spacing: 5) {
                    Image(systemName: icon)
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                        .frame(height: 40)
                    Text(title)
                        .font(.subheadline)
                }
            }
    }
    
    
    var body: some View {
        Grid {
            GridRow {
                Button {
                    impact_soft.toggle()
                } label: {
                    buttonLabel("Impact (Soft)", "chevron.compact.down")
                }
                .sensoryFeedback(.impact(flexibility: .soft), trigger: impact_soft)
                Button {
                    impact_rigid.toggle()
                } label: {
                    buttonLabel("Impact (Rigid)", "chevron.compact.down")
                }
                .sensoryFeedback(.impact(flexibility: .rigid), trigger: impact_rigid)
                Button {
                    impact_solid.toggle()
                } label: {
                    buttonLabel("Impact (Solid)", "chevron.compact.down")
                }
                .sensoryFeedback(.impact(flexibility: .solid), trigger: impact_solid)
            }
            
            GridRow {
                Button {
                    success.toggle()
                } label: {
                    buttonLabel("Success", "chevron.compact.down")
                }
                .sensoryFeedback(.success, trigger: success)
                Button {
                    warning.toggle()
                } label: {
                    buttonLabel("Warning", "chevron.compact.down")
                }
                .sensoryFeedback(.warning, trigger: warning)
                Button {
                    error.toggle()
                } label: {
                    buttonLabel("Error", "chevron.compact.down")
                }
                .sensoryFeedback(.error, trigger: error)
            }
            
            GridRow {
                Button {
                    increase.toggle()
                } label: {
                    buttonLabel("Increase", "chevron.compact.down")
                }
                .sensoryFeedback(.increase, trigger: increase)
                Button {
                    decrease.toggle()
                } label: {
                    buttonLabel("Decrease", "chevron.compact.down")
                }
                .sensoryFeedback(.decrease, trigger: decrease)
                Button {
                    levelChange.toggle()
                } label: {
                    buttonLabel("Level Change", "chevron.compact.down")
                }
                .sensoryFeedback(.levelChange, trigger: levelChange)
            }
            
            GridRow {
                Button {
                    alignment.toggle()
                } label: {
                    buttonLabel("Alignment", "chevron.compact.down")
                }
                .sensoryFeedback(.alignment, trigger: alignment)
                Button {
                    selection.toggle()
                } label: {
                    buttonLabel("Selection", "chevron.compact.down")
                }
                .sensoryFeedback(.selection, trigger: selection)
                Button {
                    pathComplete.toggle()
                } label: {
                    buttonLabel("Path Complete", "chevron.compact.down")
                }
                .sensoryFeedback(.pathComplete, trigger: pathComplete)
            }
            
            GridRow {
                Button {
                    start.toggle()
                } label: {
                    buttonLabel("Start", "chevron.compact.down")
                }
                .sensoryFeedback(.start, trigger: start)
                Button {
                    stop.toggle()
                } label: {
                    buttonLabel("Stop", "chevron.compact.down")
                }
                .sensoryFeedback(.stop, trigger: stop)
                Button {
                    impact.toggle()
                } label: {
                    buttonLabel("Impact", "chevron.compact.down")
                }
                .sensoryFeedback(.impact, trigger: impact)
            }
            
            Spacer()
        }
        .padding(20)
    }
}

#Preview {
    HapticTestView()
}
