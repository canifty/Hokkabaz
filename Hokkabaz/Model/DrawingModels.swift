import SwiftUI

// Data structure for a stroke
struct Stroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var brushProperties: BrushProperties
    var timestamp: Date = Date()
    
    // Legacy initializer for backward compatibility
    init(points: [CGPoint], color: Color) {
        self.points = points
        self.color = color
        self.brushProperties = .default
    }
    
    // New initializer with brush properties
    init(points: [CGPoint], color: Color, brushProperties: BrushProperties) {
        self.points = points
        self.color = color
        self.brushProperties = brushProperties
    }
}

// Color Note mapping used in the app
struct ColorNote {
    let color: Color
    let noteName: LocalizedStringKey
//    let noteName: String
    let instrument: String
    let midiNote: Int
    let frequency: Double
    
    init(color: Color, noteName: LocalizedStringKey, instrument: String, midiNote: Int, frequency: Double) {
        self.color = color
        self.noteName = noteName
        self.instrument = instrument
        self.midiNote = midiNote
        self.frequency = frequency
    }
}

// App theme enum
enum AppTheme: String, CaseIterable, Identifiable {
    case system, canvas, night, colorful
    var id: Self { self }
    
//    var title: String {
    var title: LocalizedStringResource {
        switch self {
        case .system: return "System"
        case .canvas: return "Canvas"
        case .night: return "Night"
        case .colorful: return "Colorful"
        }
    }
} 

// Enhanced brush types
enum BrushType: String, CaseIterable {
    case pencil = "Pencil"
//    case pen = "Pen"
    case marker = "Marker"
    case brush = "Brush"
    case charcoal = "Charcoal"
    case watercolor = "Watercolor"
    
    var icon: String {
        switch self {
        case .pencil: return "pencil"
//        case .pen: return "pencil.tip"
        case .marker: return "highlighter"
        case .brush: return "paintbrush"
        case .charcoal: return "scribble"
        case .watercolor: return "drop"
        }
    }
}

// Brush properties
struct BrushProperties {
    var type: BrushType
    var width: CGFloat
    var opacity: Double
    var pressure: Double // For future pressure sensitivity
    var tilt: Double // For future tilt sensitivity
    var hardness: Double // 0.0 = soft, 1.0 = hard
    var spacing: Double // For texture effects
    
    static let `default` = BrushProperties(
        type: .pencil,
        width: 8.0,
        opacity: 1.0,
        pressure: 1.0,
        tilt: 0.0,
        hardness: 0.8,
        spacing: 1.0
    )
}
