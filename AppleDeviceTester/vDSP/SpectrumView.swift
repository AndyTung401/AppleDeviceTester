//
//  SpectrumView.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/26.
//

import SwiftUI

struct SpectrumView: View {
    let freqs: [Float]      // frequency axis in Hz
    let dbs: [Float]        // dB values (length should match freqs)
    
    // Display ranges
    let dbMin: Float = -120
    let dbMax: Float = 0
    
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                guard freqs.count > 1, dbs.count == freqs.count else { return }
                // draw axis grid
                let w = size.width
                let h = size.height
                
                // background
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(uiColor: .systemGray6)))
                
                // draw spectrum polyline
                var path = Path()
                let maxFreq = freqs.last ?? 1
                for i in 0..<freqs.count {
                    let x = xPosition(forFreq: freqs[i], width: w, maxFreq: maxFreq)
                    let y = yPosition(forDB: dbs[i], height: h)
                    let pt = CGPoint(x: x, y: y)
                    if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                }
                ctx.stroke(path, with: .color(.accentColor), lineWidth: 1.2)
                
                // horizontal lines for dB ticks
                let tickDBs: [Float] = stride(from: dbMin, through: dbMax, by: 20).map { $0 }
                for t in tickDBs {
                    let y = yPosition(forDB: t, height: h)
                    var p = Path()
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: w, y: y))
                    ctx.stroke(p, with: .color(.gray.opacity(0.2)), lineWidth: 0.5)
                    
                    if t > dbMin {
                        // label
                        let text = Text("\(Int(t)) dB").font(.caption2)
                        ctx.draw(text, at: CGPoint(x: 30, y: y - 8))
                    }
                }
                
                // frequency label ticks (log or linear?). use linear for simplicity
                let freqTicksHz: [Float] = [20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000]
                for f in freqTicksHz {
                    guard let maxFreq = freqs.last else { continue }
                    if f > maxFreq { continue }
                    let x = xPosition(forFreq: f, width: w, maxFreq: maxFreq)
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: h))
                    ctx.stroke(p, with: .color(.gray.opacity(0.15)), lineWidth: 0.3)

                    let labelText: String
                    if f >= 1000 {
                        labelText = "\(Int(f/1000))k"
                    } else {
                        labelText = "\(Int(f))"
                    }
                    let label = Text(labelText).font(.caption2)
                    ctx.draw(label, at: CGPoint(x: x, y: h-5), anchor: .bottom)
                }
                
                
            }
        }
        .cornerRadius(8)
        .glassEffect(in: .rect(cornerRadius: 8))
    }
    
    private func xPosition(forFreq f: Float, width: CGFloat, maxFreq: Float) -> CGFloat {
        // 避免 log(0)，把 0Hz 視為 20Hz
        let fMin: Float = 20
        let fClamped = max(f, fMin)
        let logMin = log10(fMin)
        let logMax = log10(maxFreq)
        let logF = log10(fClamped)
        let ratio = CGFloat((logF - logMin) / (logMax - logMin))
        return ratio * width
    }
    
    private func yPosition(forDB db: Float, height: CGFloat) -> CGFloat {
        // map dbMax -> y=0 and dbMin -> y=height
        let clipped = min(max(db, dbMin), dbMax)
        let ratio = CGFloat((dbMax - clipped) / (dbMax - dbMin))
        return ratio * height
    }
}
