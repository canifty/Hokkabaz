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
    let noteName: String
    let instrument: String
    let midiNote: Int
    let frequency: Double
    
    init(color: Color, noteName: String, instrument: String, midiNote: Int, frequency: Double) {
        self.color = color
        self.noteName = noteName
        self.instrument = instrument
        self.midiNote = midiNote
        self.frequency = frequency
    }
}

// App theme enum
enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark, colorful
    var id: Self { self }
    
    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .colorful: return "Colorful"
        }
    }
} 