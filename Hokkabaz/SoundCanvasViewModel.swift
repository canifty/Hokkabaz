import SwiftUI
import Combine

class SoundCanvasViewModel: ObservableObject {
    // Audio engine
    @Published var conductor = Conductor()
    
    // Drawing data
    @Published var strokes: [Stroke] = []
    @Published var currentStroke: [CGPoint] = []
    @Published var activeStrokeId: UUID? = nil
    
    // UI State
    @Published var currentColorIndex = 2 // Default to green (index 2)
    @Published var currentInstrument = "Piano" // Default to Piano
    @Published var showTutorial = false
    @Published var showSettings = false
    @Published var showExportMenu = false
    @Published var exportImage: UIImage? = nil
    @Published var showClearConfirmation = false
    @Published var isControlPanelHidden = false
    @Published var showNoteLetters = false // Show note letters on colors by default
    
    // Canvas view state
    @Published var canvasScale: CGFloat = 1.0
    @Published var canvasOffset = CGSize.zero
    @Published var strokeWidthMultiplier: CGFloat = 1.0
    
    // Theme
    @Published var appTheme: AppTheme = .canvas
    
    // Colors and notes
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, Color(red: 255/255, green: 105/255, blue: 180/255)]
    let colorNames: [LocalizedStringKey] = ["C", "D", "E", "F", "G", "A", "B"]
    let instrumentNames: [String] = ["Piano", "Guitar", "Flute", "Violin", "Trumpet", "Harp", "Cello"]
    
    // Track instrument changes
    var instrumentCancellable: AnyCancellable?
    
    init() {
        // Initialize with piano sound
        conductor.loadPianoPreset()
        
        // Set up observer for instrument changes
        instrumentCancellable = $currentInstrument
            .dropFirst() // Skip initial value
            .sink { [weak self] instrumentName in
                self?.conductor.loadInstrumentByName(instrumentName)
            }
    }
    
    // Computed properties
    var currentColor: Color {
        colors[currentColorIndex]
    }
    
    var backgroundColors: [Color] {
        switch appTheme {
        case .canvas:
            return [Color(white: 0.9), Color(white: 0.95)]
        case .night:
            return [Color.black.opacity(0.8), Color(red: 0.1, green: 0.1, blue: 0.3)]
        case .colorful:
            return [Color.purple.opacity(0.7), Color.blue.opacity(0.5)]
        case .system:
            // This needs to be handled differently since we don't have access to colorScheme here
            return [Color(UIColor.systemBackground), Color(UIColor.secondarySystemBackground)]
        }
    }
    
    var colorNotes: [ColorNote] {
        zip(zip(zip(zip(colors, colorNames), instrumentNames), conductor.midiNotes), conductor.noteFrequencies).map { 
            ColorNote(
                color: $0.0.0.0.0, 
                noteName: $0.0.0.0.1,
                instrument: $0.0.0.1, 
                midiNote: Int($0.0.1), 
                frequency: Double($0.1)
            )
        }
    }
    
//    Array<Color>.Element, Array<LocalizedStringKey>.Element
    
    // MARK: - Functions
    
    func startDrawing(at point: CGPoint) {
        currentStroke.append(point)
        startSoundForColor()
        
    }
    
    func continueDrawing(at point: CGPoint) {
        currentStroke.append(point)
    }
    
    func endDrawing() {
        if !currentStroke.isEmpty {
            let newStroke = Stroke(points: currentStroke, color: currentColor)
            strokes.append(newStroke)
            currentStroke.removeAll()
            conductor.stopSound()
        }
    }
    
    func startSoundForColor() {
        conductor.playInstrument(colorIndex: currentColorIndex)
    }
    
    func replayStrokes() {
        guard !strokes.isEmpty else { return }
        
        Task {
            for (index, stroke) in strokes.enumerated() {
                activeStrokeId = stroke.id
                
                if let colorIndex = colors.firstIndex(of: stroke.color) {
                    conductor.playInstrument(colorIndex: colorIndex)
                }
                
                // Add visual feedback for the stroke being replayed
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
                
                // Stop sound after the last stroke
                if index == strokes.count - 1 {
                    conductor.stopSound()
                    activeStrokeId = nil
                }
            }
        }
    }
    
    func clearCanvas() {
//        let generator = UIImpactFeedbackGenerator(style: .medium)
//        generator.impactOccurred()
        
        strokes.removeAll()
    }
    
    func resetCanvasView() {
        canvasScale = 1.0
        canvasOffset = .zero
    }
    
    func undoLastStroke() {
        guard !strokes.isEmpty else { return }
        
        // Remove the last stroke
        _ = strokes.popLast()
    }
    
    func convertPointForCanvas(_ point: CGPoint, size: CGSize) -> CGPoint {
        // Convert point from screen coordinates to canvas coordinates accounting for zoom and pan
        let adjustedX = (point.x - size.width/2 - canvasOffset.width) / canvasScale + size.width/2
        let adjustedY = (point.y - size.height/2 - canvasOffset.height) / canvasScale + size.height/2
        return CGPoint(x: adjustedX, y: adjustedY)
    }
    
    func midPoint(_ p1: CGPoint, _ p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }
    
    func renderCanvasToImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Draw background
            if appTheme == .canvas {
                // Use paper background for light theme
                if let paperImage = UIImage(named: "canvas") {
                    paperImage.draw(in: CGRect(origin: .zero, size: size))
                } else {
                    // Fallback if image is not found
                    let backgroundPath = UIBezierPath(rect: CGRect(origin: .zero, size: size))
                    UIColor(backgroundColors[0]).setFill()
                    backgroundPath.fill()
                }
            } else {
                // Use color background for other themes
                let backgroundPath = UIBezierPath(rect: CGRect(origin: .zero, size: size))
                UIColor(backgroundColors[0]).setFill()
                backgroundPath.fill()
            }
            
            // Draw strokes
            for stroke in strokes {
                guard stroke.points.count > 1 else { continue }
                
                let path = UIBezierPath()
                path.move(to: stroke.points[0])
                
                for i in 1..<stroke.points.count {
                    let midPoint = midPoint(stroke.points[i-1], stroke.points[i])
                    path.addQuadCurve(to: midPoint, controlPoint: stroke.points[i-1])
                    if i == stroke.points.count - 1 {
                        path.addLine(to: stroke.points[i])
                    }
                }
                
                path.lineWidth = 8 * strokeWidthMultiplier
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                
                UIColor(stroke.color).setStroke()
                path.stroke()
            }
        }
    }
} 
