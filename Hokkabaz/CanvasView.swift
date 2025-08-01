import SwiftUI

struct CanvasView: View {
    @ObservedObject var viewModel: SoundCanvasViewModel
    var size: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Draw saved strokes
            for stroke in viewModel.strokes {
                let isActive = stroke.id == viewModel.activeStrokeId
                drawEnhancedStroke(stroke, in: &context, isActive: isActive)
            }

            // Draw current stroke
            if !viewModel.currentStroke.isEmpty {
                let currentStroke = Stroke(
                    points: viewModel.currentStroke,
                    color: viewModel.currentColor,
                    brushProperties: viewModel.currentBrushProperties
                )
                drawEnhancedStroke(currentStroke, in: &context, isActive: true)
            }
        }
        .accessibility(label: Text("Drawing canvas with musical sounds"))
        .accessibility(hint: Text("Draw with your finger to create sounds"))
    }

    func drawEnhancedStroke(_ stroke: Stroke, in context: inout GraphicsContext, isActive: Bool) {
        guard !stroke.points.isEmpty else { return }

        let brush = stroke.brushProperties
        let baseWidth = brush.width * (isActive ? 1.2 : 1.0)
        let opacity = brush.opacity * (isActive ? 1.0 : 0.9)
        let glowWidth: CGFloat = isActive ? 4.0 : 0.0

        switch brush.type {
        case .pencil:
            drawPencilStroke(stroke, in: &context, width: baseWidth, opacity: opacity, glowWidth: glowWidth)
        case .pen:
            drawPenStroke(stroke, in: &context, width: baseWidth, opacity: opacity, glowWidth: glowWidth)
        case .marker:
            drawMarkerStroke(stroke, in: &context, width: baseWidth, opacity: opacity, glowWidth: glowWidth)
        case .brush:
            drawBrushStroke(stroke, in: &context, width: baseWidth, opacity: opacity, glowWidth: glowWidth)
        case .charcoal:
            drawCharcoalStroke(stroke, in: &context, width: baseWidth, opacity: opacity, glowWidth: glowWidth)
        case .watercolor:
            drawWatercolorStroke(stroke, in: &context, width: baseWidth, opacity: opacity, glowWidth: glowWidth)
        }
    }

    // MARK: - Glow Helper

    func drawGlow(path: Path, in context: inout GraphicsContext, color: Color, width: CGFloat, glowWidth: CGFloat) {
        guard glowWidth > 0 else { return }
        context.stroke(
            path,
            with: .color(color.opacity(0.3)),
            style: StrokeStyle(
                lineWidth: width + glowWidth,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }

    // MARK: - Brush Drawing Methods

    func drawPencilStroke(_ stroke: Stroke, in context: inout GraphicsContext, width: CGFloat, opacity: Double, glowWidth: CGFloat) {
        let path = createSmoothPath(from: stroke.points)
        drawGlow(path: path, in: &context, color: stroke.color, width: width, glowWidth: glowWidth)
        for i in 0..<3 {
            let alpha = opacity * (1.0 - Double(i) * 0.2)
            let strokeWidth = width * (1.0 - CGFloat(i) * 0.1)
            context.stroke(path, with: .color(stroke.color.opacity(alpha)),
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
        }
    }

    func drawPenStroke(_ stroke: Stroke, in context: inout GraphicsContext, width: CGFloat, opacity: Double, glowWidth: CGFloat) {
        let path = createSmoothPath(from: stroke.points)
        drawGlow(path: path, in: &context, color: stroke.color, width: width, glowWidth: glowWidth)
        context.stroke(path, with: .color(stroke.color.opacity(opacity)),
            style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    func drawMarkerStroke(_ stroke: Stroke, in context: inout GraphicsContext, width: CGFloat, opacity: Double, glowWidth: CGFloat) {
        let path = createSmoothPath(from: stroke.points)
        drawGlow(path: path, in: &context, color: stroke.color, width: width, glowWidth: glowWidth)
        context.stroke(path, with: .color(stroke.color.opacity(opacity * 0.3)),
            style: StrokeStyle(lineWidth: width * 1.5, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(stroke.color.opacity(opacity)),
            style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    func drawBrushStroke(_ stroke: Stroke, in context: inout GraphicsContext, width: CGFloat, opacity: Double, glowWidth: CGFloat) {
        guard stroke.points.count > 1 else { return }
        for i in 0..<stroke.points.count - 1 {
            let start = stroke.points[i]
            let end = stroke.points[i + 1]
            let distance = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2))
            let speedFactor = min(1.0, max(0.3, 10.0 / distance))
            let segmentWidth = width * speedFactor
            let path = Path { $0.move(to: start); $0.addLine(to: end) }
            drawGlow(path: path, in: &context, color: stroke.color, width: segmentWidth, glowWidth: glowWidth)
            context.stroke(path, with: .color(stroke.color.opacity(opacity)),
                style: StrokeStyle(lineWidth: segmentWidth, lineCap: .round, lineJoin: .round))
        }
    }

    func drawCharcoalStroke(_ stroke: Stroke, in context: inout GraphicsContext, width: CGFloat, opacity: Double, glowWidth: CGFloat) {
        let path = createSmoothPath(from: stroke.points)
        drawGlow(path: path, in: &context, color: stroke.color, width: width, glowWidth: glowWidth)
        for i in 0..<5 {
            let alpha = opacity * (0.3 + Double(i) * 0.15)
            let strokeWidth = width * (0.8 + CGFloat(i) * 0.1)
            context.stroke(path, with: .color(stroke.color.opacity(alpha)),
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
        }
    }

    func drawWatercolorStroke(_ stroke: Stroke, in context: inout GraphicsContext, width: CGFloat, opacity: Double, glowWidth: CGFloat) {
        let path = createSmoothPath(from: stroke.points)
        drawGlow(path: path, in: &context, color: stroke.color, width: width, glowWidth: glowWidth)
        context.stroke(path, with: .color(stroke.color.opacity(opacity * 0.2)),
            style: StrokeStyle(lineWidth: width * 2.0, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(stroke.color.opacity(opacity * 0.4)),
            style: StrokeStyle(lineWidth: width * 1.3, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(stroke.color.opacity(opacity)),
            style: StrokeStyle(lineWidth: width * 0.6, lineCap: .round, lineJoin: .round))
    }

    // MARK: - Path Helper

    func createSmoothPath(from points: [CGPoint]) -> Path {
        guard points.count > 1 else {
            return Path { path in
                if let first = points.first {
                    path.move(to: first)
                }
            }
        }

        return Path { path in
            path.move(to: points[0])
            for i in 1..<points.count {
                let midPoint = CGPoint(
                    x: (points[i-1].x + points[i].x) / 2,
                    y: (points[i-1].y + points[i].y) / 2
                )
                path.addQuadCurve(to: midPoint, control: points[i-1])
                if i == points.count - 1 {
                    path.addLine(to: points[i])
                }
            }
        }
    }
}

//COMPARE BEFORE DELETING
//import SwiftUI
//
//struct CanvasView: View {
//    @ObservedObject var viewModel: SoundCanvasViewModel
//    var size: CGSize
//    
//    var body: some View {
//        Canvas { context, size in
//            // Draw previously saved strokes
//            for stroke in viewModel.strokes {
//                let isActive = stroke.id == viewModel.activeStrokeId
//                drawEnhancedStroke(
//                    stroke,
//                    in: &context,
//                    isActive: isActive
//                )
//            }
//            
//            // Draw current stroke
//            if !viewModel.currentStroke.isEmpty {
//                let currentStroke = Stroke(
//                    points: viewModel.currentStroke,
//                    color: viewModel.currentColor,
//                    brushProperties: viewModel.currentBrushProperties
//                )
//                drawEnhancedStroke(
//                    currentStroke,
//                    in: &context,
//                    isActive: true
//                )
//            }
//        }
//        .accessibility(label: Text("Drawing canvas with musical sounds"))
//        .accessibility(hint: Text("Draw with your finger to create sounds"))
//    }
//    
//    func drawEnhancedStroke(_ stroke: Stroke, in context: inout GraphicsContext, isActive: Bool) {
//        guard !stroke.points.isEmpty else { return }
//        
//        let brush = stroke.brushProperties
//        let baseWidth = brush.width * (isActive ? 1.2 : 1.0)
//        let opacity = brush.opacity * (isActive ? 1.0 : 0.9)
//        
//        switch brush.type {
//        case .pencil:
//            drawPencilStroke(stroke, in: &context, width: baseWidth, opacity: opacity)
//        case .pen:
//            drawPenStroke(stroke, in: &context, width: baseWidth, opacity: opacity)
//        case .marker:
//            drawMarkerStroke(stroke, in: &context, width: baseWidth, opacity: opacity)
//        case .brush:
//            drawBrushStroke(stroke, in: &context, width: baseWidth, opacity: opacity)
//        case .charcoal:
//            drawCharcoalStroke(stroke, in: &context, width: baseWidth, opacity: opacity)
//        case .watercolor:
//            drawWatercolorStroke(stroke, in: &context, width: baseWidth, opacity: opacity)
//        }
//    }
//    
//    // MARK: - Brush-specific drawing methods
//    
//    func drawPencilStroke(_ stroke: Stroke, in context: inout GraphicsContext, width: CGFloat, opacity: Double) {
//        let path = createSmoothPath(from: stroke.points)
//        
//        // Multiple passes for pencil texture
//        for i in 0..<3 {
//            let alpha = opacity * (1.0 - Double(i) * 0.2)
//            let strokeWidth = width * (1.0 - CGFloat(i) * 0.1)
//            
//            context.stroke(
//                path,
//                with: .color(stroke.color.opacity(alpha)),
//                style: StrokeStyle(
//                    lineWidth: strokeWidth,
//                    lineCap: .round,
//                    lineJoin: .round
//                )
//            )
//        }
//    }
//    
//    func drawPenStroke(_ stroke: Stroke, in context: inout GraphicsContext, width: CGFloat, opacity: Double) {
//        let path = createSmoothPath(from: stroke.points)
//        
//        context.stroke(
//            path,
//            with: .color(stroke.color.opacity(opacity)),
//            style: StrokeStyle(
//                lineWidth: width,
//                lineCap: .round,
//                lineJoin: .round
//            )
//        )
//    }
//    
//    func drawMarkerStroke(_ stroke: Stroke, in context: inout GraphicsContext, width: CGFloat, opacity: Double) {
//        let path = createSmoothPath(from: stroke.points)
//        
//        // Soft outer edge
//        context.stroke(
//            path,
//            with: .color(stroke.color.opacity(opacity * 0.3)),
//            style: StrokeStyle(
//                lineWidth: width * 1.5,
//                lineCap: .round,
//                lineJoin: .round
//            )
//        )
//        
//        // Solid inner core
//        context.stroke(
//            path,
//            with: .color(stroke.color.opacity(opacity)),
//            style: StrokeStyle(
//                lineWidth: width,
//                lineCap: .round,
//                lineJoin: .round
//            )
//        )
//    }
//    
//    func drawBrushStroke(_ stroke: Stroke, in context: inout GraphicsContext, width: CGFloat, opacity: Double) {
//        // Variable width brush stroke
//        guard stroke.points.count > 1 else { return }
//        
//        for i in 0..<stroke.points.count - 1 {
//            let start = stroke.points[i]
//            let end = stroke.points[i + 1]
//            
//            // Vary width based on speed (simulate pressure)
//            let distance = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2))
//            let speedFactor = min(1.0, max(0.3, 10.0 / distance))
//            let segmentWidth = width * speedFactor
//            
//            let path = Path { path in
//                path.move(to: start)
//                path.addLine(to: end)
//            }
//            
//            context.stroke(
//                path,
//                with: .color(stroke.color.opacity(opacity)),
//                style: StrokeStyle(
//                    lineWidth: segmentWidth,
//                    lineCap: .round,
//                    lineJoin: .round
//                )
//            )
//        }
//    }
//    
//    func drawCharcoalStroke(_ stroke: Stroke, in context: inout GraphicsContext, width: CGFloat, opacity: Double) {
//        let path = createSmoothPath(from: stroke.points)
//        
//        // Multiple rough passes for charcoal texture
//        for i in 0..<5 {
//            let alpha = opacity * (0.3 + Double(i) * 0.15)
//            let strokeWidth = width * (0.8 + CGFloat(i) * 0.1)
//            
//            context.stroke(
//                path,
//                with: .color(stroke.color.opacity(alpha)),
//                style: StrokeStyle(
//                    lineWidth: strokeWidth,
//                    lineCap: .round,
//                    lineJoin: .round
//                )
//            )
//        }
//    }
//    
//    func drawWatercolorStroke(_ stroke: Stroke, in context: inout GraphicsContext, width: CGFloat, opacity: Double) {
//        let path = createSmoothPath(from: stroke.points)
//        
//        // Outer wash
//        context.stroke(
//            path,
//            with: .color(stroke.color.opacity(opacity * 0.2)),
//            style: StrokeStyle(
//                lineWidth: width * 2.0,
//                lineCap: .round,
//                lineJoin: .round
//            )
//        )
//        
//        // Medium wash
//        context.stroke(
//            path,
//            with: .color(stroke.color.opacity(opacity * 0.4)),
//            style: StrokeStyle(
//                lineWidth: width * 1.3,
//                lineCap: .round,
//                lineJoin: .round
//            )
//        )
//        
//        // Inner pigment
//        context.stroke(
//            path,
//            with: .color(stroke.color.opacity(opacity)),
//            style: StrokeStyle(
//                lineWidth: width * 0.6,
//                lineCap: .round,
//                lineJoin: .round
//            )
//        )
//    }
//    
//    // MARK: - Helper methods
//    
//    func createSmoothPath(from points: [CGPoint]) -> Path {
//        guard points.count > 1 else {
//            return Path { path in
//                if let first = points.first {
//                    path.move(to: first)
//                }
//            }
//        }
//        
//        return Path { path in
//            path.move(to: points[0])
//            
//            for i in 1..<points.count {
//                let midPoint = CGPoint(
//                    x: (points[i-1].x + points[i].x) / 2,
//                    y: (points[i-1].y + points[i].y) / 2
//                )
//                path.addQuadCurve(to: midPoint, control: points[i-1])
//                if i == points.count - 1 {
//                    path.addLine(to: points[i])
//                }
//            }
//        }
//    }
//}
//
