//
//  DrawingCanvas.swift
//  Hokkabaz
//
//  Created by Can Dindar on 05/03/25.
//

import SwiftUI
import AudioKit

struct DrawingCanvas: View {
    @ObservedObject var strokeManager: StrokeManager
    @ObservedObject var conductor: Conductor

    var body: some View {
        Canvas { context, size in
            for stroke in strokeManager.strokes {
                drawStroke(stroke, in: &context)
            }
            drawStroke(strokeManager.currentStroke, in: &context)
        }
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { value in
                let newPoint = value.location
                strokeManager.addPoint(newPoint)
                conductor.playOscillator(frequency: AUValue(strokeManager.map(newPoint.y, from: 0, to: UIScreen.main.bounds.height, toLow: 200, toHigh: 800)))
            }
            .onEnded { _ in
                strokeManager.finalizeStroke()
                conductor.stopOscillator()
            })
    }

    func drawStroke(_ stroke: [CGPoint], in context: inout GraphicsContext) {
        guard !stroke.isEmpty else { return }

        var path = Path()
        for (index, point) in stroke.enumerated() {
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        context.stroke(path, with: .color(.black), lineWidth: 5)
    }
}

#Preview {
    DrawingCanvas(strokeManager: StrokeManager(), conductor: Conductor())
}
