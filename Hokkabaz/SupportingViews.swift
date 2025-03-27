import SwiftUI

// MARK: - Color Button
struct ColorButton: View {
    let color: Color
    let note: LocalizedStringKey
    let instrument: String
    let isSelected: Bool
    let showNote: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                    .shadow(color: color.opacity(0.6), radius: isSelected ? 8 : 2, x: 0, y: isSelected ? 3 : 1)
                
                Circle()
                    .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                    .frame(width: 50, height: 50)
                
                Text(note)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 1)
                    .opacity(showNote ? 1 : 0)
                    .scaleEffect(showNote ? 1 : 0.7)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showNote)
            }
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Instrument Button
struct InstrumentButton: View {
    let iconName: String
    let instrumentName: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
//                    .frame(width: 32, height: 32)
                    .font(.system(size: 18, weight: .semibold))
                Text(instrumentName)
                    .font(.caption)
            }
            .frame(minWidth: 70, minHeight: 50)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.gray.opacity(0.3) : Color.black.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? 
                                    (colorScheme == .light ? Color.black.opacity(0.5) : Color.white.opacity(0.6)) 
                                    : Color.clear, 
                                lineWidth: 2
                            )
                    )
            )
        }
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

