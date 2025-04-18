import SwiftUI

// Color utility extension
extension Color {
    func isBright() -> Bool {
        // Simple approximation to determine if a color is bright
        // More sophisticated implementations can be used for better results
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 0]
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
        return brightness > 0.6
    }
}
