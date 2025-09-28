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
                        .foregroundStyle(title == "Success" ? .green :
                                            (title == "Warning" ? .yellow :
                                                (title == "Error" ? .red :
                                                        .accentColor
                                                )
                                            )
                        )
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
                    buttonLabel("Impact (Soft)", "arrow.down.circle.dotted")
                }
                .sensoryFeedback(.impact(flexibility: .soft), trigger: impact_soft)
                Button {
                    impact_rigid.toggle()
                } label: {
                    buttonLabel("Impact (Rigid)", "arrow.down.circle")
                }
                .sensoryFeedback(.impact(flexibility: .rigid), trigger: impact_rigid)
                Button {
                    impact_solid.toggle()
                } label: {
                    buttonLabel("Impact (Solid)", "arrow.down.circle.fill")
                }
                .sensoryFeedback(.impact(flexibility: .solid), trigger: impact_solid)
            }
            
            GridRow {
                Button {
                    impact.toggle()
                } label: {
                    buttonLabel("Impact", "arrow.down.square.fill")
                }
                .sensoryFeedback(.impact, trigger: impact)
                
                Button {
                    increase.toggle()
                } label: {
                    buttonLabel("Increase", "plus.square.fill")
                }
                .sensoryFeedback(.increase, trigger: increase)
                Button {
                    decrease.toggle()
                } label: {
                    buttonLabel("Decrease", "minus.square.fill")
                }
                .sensoryFeedback(.decrease, trigger: decrease)
                
            }
            
            GridRow {
                Button {
                    success.toggle()
                } label: {
                    buttonLabel("Success", "checkmark.seal.fill")
                }
                .sensoryFeedback(.success, trigger: success)
                Button {
                    warning.toggle()
                } label: {
                    buttonLabel("Warning", "exclamationmark.triangle.fill")
                }
                .sensoryFeedback(.warning, trigger: warning)
                Button {
                    error.toggle()
                } label: {
                    buttonLabel("Error", "xmark.circle.fill")
                }
                .sensoryFeedback(.error, trigger: error)
            }
            
            
            
            GridRow {
                Button {
                    selection.toggle()
                } label: {
                    buttonLabel("Selection", "pointer.arrow.ipad.rays")
                }
                .sensoryFeedback(.selection, trigger: selection)
            }
            
            HStack {
                VStack {
                    Divider()
                }
                Text("The below section may have no feedback.")
                    .foregroundStyle(.gray)
                    .font(.caption)
                    .layoutPriority(1)
                VStack {
                    Divider()
                }
            }
            
            GridRow {
                Button {
                    start.toggle()
                } label: {
                    buttonLabel("Start", "play.fill")
                }
                .sensoryFeedback(.start, trigger: start)
                Button {
                    stop.toggle()
                } label: {
                    buttonLabel("Stop", "stop.fill")
                }
                .sensoryFeedback(.stop, trigger: stop)
                
                
                Button {
                    levelChange.toggle()
                } label: {
                    buttonLabel("Level Change", "arrow.up.and.line.horizontal.and.arrow.down")
                }
                .sensoryFeedback(.levelChange, trigger: levelChange)
            }
            
            GridRow {
                Button {
                    alignment.toggle()
                } label: {
                    buttonLabel("Alignment", "arrow.forward.to.line.compact")
                }
                .sensoryFeedback(.alignment, trigger: alignment)
                Button {
                    pathComplete.toggle()
                } label: {
                    buttonLabel("Path Complete", "pencil.and.outline")
                }
                .sensoryFeedback(.pathComplete, trigger: pathComplete)
            }
            Spacer()
        }
        .padding(20)
        .buttonStyle(.plain)
    }
}

#Preview {
    HapticTestView()
}
