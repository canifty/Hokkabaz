import SwiftUI

struct CanvasView: View {
    @ObservedObject var viewModel: SoundCanvasViewModel
    var size: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Draw previously saved strokes
            for stroke in viewModel.strokes {
                let isActive = stroke.id == viewModel.activeStrokeId
                let strokeWidth = isActive ? 12 * viewModel.strokeWidthMultiplier : 8 * viewModel.strokeWidthMultiplier
                let glowWidth = isActive ? 4.0 : 0.0
                
                drawStroke(
                    stroke.points,
                    in: &context,
                    color: stroke.color,
                    strokeWidth: strokeWidth,
                    glowWidth: glowWidth
                )
            }
            
            // Draw current stroke
            if !viewModel.currentStroke.isEmpty {
                drawStroke(
                    viewModel.currentStroke,
                    in: &context,
                    color: viewModel.currentColor,
                    strokeWidth: 8 * viewModel.strokeWidthMultiplier,
                    glowWidth: 2.0
                )
            }
        }
        .accessibility(label: Text("Drawing canvas with musical sounds"))
        .accessibility(hint: Text("Draw with your finger to create sounds"))
        .accessibilityAction(named: Text("Clear Canvas")) {
            viewModel.clearCanvas()
        }
    }
    
    func drawStroke(_ stroke: [CGPoint], in context: inout GraphicsContext, color: Color, strokeWidth: CGFloat, glowWidth: CGFloat = 0) {
        guard !stroke.isEmpty else { return }
        var path = Path()
        path.move(to: stroke[0])
        
        for i in 1..<stroke.count {
            let midPoint = viewModel.midPoint(stroke[i-1], stroke[i])
            path.addQuadCurve(to: midPoint, control: stroke[i-1])
            if i == stroke.count - 1 {
                path.addLine(to: stroke[i])
            }
        }
        
        // Draw glow if specified
        if glowWidth > 0 {
            context.stroke(
                path,
                with: .color(color.opacity(0.3)),
                style: StrokeStyle(
                    lineWidth: strokeWidth + glowWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
        
        // Draw main stroke
        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(
                lineWidth: strokeWidth,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }
} 