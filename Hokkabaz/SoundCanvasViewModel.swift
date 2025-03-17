import SwiftUI
import Combine

// Enum per la velocità di riproduzione
enum PlaybackSpeed: String, CaseIterable, Identifiable {
    case slow = "Slow"
    case normal = "Normal"
    case fast = "Fast"
    
    var id: String { self.rawValue }
    
    // Moltiplicatore di tempo per la riproduzione
    var timeMultiplier: Double {
        switch self {
        case .slow: return 2.0    // Riproduci a metà velocità
        case .normal: return 1.0  // Velocità normale
        case .fast: return 0.5    // Riproduci a doppia velocità
        }
    }
}

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
    @Published var appTheme: AppTheme = .dark
    
    // Colors and notes
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    let colorNames: [String] = ["C", "D", "E", "F", "G", "A", "B"]
    let instrumentNames: [String] = ["Piano", "Guitar", "Flute", "Violin", "Trumpet", "Harp", "Cello"]
    
    // Track instrument changes
    var instrumentCancellable: AnyCancellable?
    
    // Aggiungi la proprietà per la velocità di riproduzione
    @Published var playbackSpeed: PlaybackSpeed = .normal
    
    // Aggiungi questa proprietà per memorizzare il timer
    private var replayTimer: Timer?
    
    // Aggiungi questa proprietà pubblica
    @Published var isReplaying: Bool = false
    
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
        case .light:
            return [Color(white: 0.9), Color(white: 0.95)]
        case .dark:
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
    
    // MARK: - Functions
    
    func startDrawing(at point: CGPoint) {
        currentStroke.append(point)
        startSoundForColor()
        
        // Add haptic feedback
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
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
        activeStrokeId = nil
        guard !strokes.isEmpty else { return }
        
        // Interrompi eventuali riproduzioni in corso
        stopReplay()
        
        // Indice corrente e timer per la riproduzione
        var currentIndex = 0
        let timeInterval = 0.5 * playbackSpeed.timeMultiplier
        
        // Crea e memorizza il timer per poterlo interrompere se necessario
        replayTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // Riproduci il suono corrente
            if currentIndex < self.strokes.count {
                let stroke = self.strokes[currentIndex]
                self.activeStrokeId = stroke.id
                
                let colorIndex = self.colors.firstIndex(of: stroke.color) ?? 0
                self.conductor.playInstrument(colorIndex: colorIndex)
                
                // Ferma il suono dopo un breve periodo fisso
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.conductor.stopSound()
                }
                
                currentIndex += 1
            } else {
                // Finita la riproduzione
                self.activeStrokeId = nil
                self.isReplaying = false
                timer.invalidate()
                self.replayTimer = nil
            }
        }
        
        isReplaying = true
    }
    
    // Aggiungi questo metodo per fermare la riproduzione
    func stopReplay() {
        replayTimer?.invalidate()
        replayTimer = nil
        conductor.stopSound()
        activeStrokeId = nil
        isReplaying = false
    }
    
    // Assicurati di fermare la riproduzione quando necessario
    func clearCanvas() {
        stopReplay()  // Ferma la riproduzione se è in corso
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        strokes.removeAll()
    }
    
    func resetCanvasView() {
        canvasScale = 1.0
        canvasOffset = .zero
    }
    
    func undoLastStroke() {
        guard !strokes.isEmpty else { return }
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
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
            let backgroundPath = UIBezierPath(rect: CGRect(origin: .zero, size: size))
            UIColor(backgroundColors[0]).setFill()
            backgroundPath.fill()
            
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
