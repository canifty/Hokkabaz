//import SwiftUI
//
//struct TutorialView: View {
//    @Environment(\.dismiss) private var dismiss
//    var theme: AppTheme
//    var colorScheme: ColorScheme
//    
//    var foregroundStyle: Color {
//        switch theme {
//        case .light: return .black
//        case .dark: return .white
//        case .colorful: return .white
//        case .system: return colorScheme == .dark ? .white : .black
//        }
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            HStack {
//                Text("How to use Sound Canvas")
//                    .font(.title2.bold())
//                    .foregroundColor(foregroundStyle)
//                Spacer()
//                Button(action: { dismiss() }) {
//                    Image(systemName: "xmark.circle.fill")
//                        .font(.title2)
//                        .foregroundColor(foregroundStyle.opacity(0.6))
//                }
//                .accessibilityLabel("Close tutorial")
//            }
//            
//            VStack(alignment: .leading, spacing: 18) {
//                TutorialItem(
//                    icon: "hand.draw.fill",
//                    title: "Draw to create music",
//                    description: "Draw on the canvas to play different instrument sounds based on the selected color.",
//                    theme: theme,
//                    colorScheme: colorScheme
//                )
//                
//                TutorialItem(
//                    icon: "paintpalette.fill",
//                    title: "Choose instruments",
//                    description: "Each color represents a different musical instrument playing a unique note.",
//                    theme: theme,
//                    colorScheme: colorScheme
//                )
//                
//                TutorialItem(
//                    icon: "play.fill",
//                    title: "Replay your drawing",
//                    description: "Play back your musical creation with the Replay button.",
//                    theme: theme,
//                    colorScheme: colorScheme
//                )
//                
//                TutorialItem(
//                    icon: "trash",
//                    title: "Clear the canvas",
//                    description: "Start fresh with the Clear button to create a new composition.",
//                    theme: theme,
//                    colorScheme: colorScheme
//                )
//                
//                TutorialItem(
//                    icon: "hand.tap",
//                    title: "Pinch to zoom",
//                    description: "Pinch with two fingers to zoom in and out of your drawing.",
//                    theme: theme,
//                    colorScheme: colorScheme
//                )
//                
//                TutorialItem(
//                    icon: "square.and.arrow.up",
//                    title: "Export your creation",
//                    description: "Save your musical drawing to your photos or share it.",
//                    theme: theme,
//                    colorScheme: colorScheme
//                )
//
//                TutorialItem(
//                    icon: "chevron.up.chevron.down",
//                    title: "Hide/Show Controls",
//                    description: "Tap the indicator at the bottom to hide or show the control panel for more drawing space.",
//                    theme: theme,
//                    colorScheme: colorScheme
//                )
//            }
//            .padding()
//            
//            Spacer()
//            
//            Button(action: { dismiss() }) {
//                Text("Got it!")
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(Color.blue)
//                    .clipShape(RoundedRectangle(cornerRadius: 12))
//            }
//            .padding(.horizontal)
//        }
//        .padding()
//    }
//} 
