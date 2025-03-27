import SwiftUI

// Data structure for a stroke
struct Stroke: Identifiable {
    let id: UUID
    let points: [CGPoint]
    let color: Color
    
    init(id: UUID = UUID(), points: [CGPoint], color: Color) {
        self.id = id
        self.points = points
        self.color = color
    }
}

// Color Note mapping used in the app
struct ColorNote {
    let color: Color
    let noteName: LocalizedStringKey
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
