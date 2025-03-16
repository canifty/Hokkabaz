import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SoundCanvasViewModel
    @Environment(\.colorScheme) var colorScheme
    var closeAction: () -> Void
    
    var foregroundStyle: Color {
        switch viewModel.appTheme {
        case .light: return .black
        case .dark: return .white
        case .colorful: return .white
        case .system: return colorScheme == .dark ? .white : .black
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2.bold())
                    .foregroundColor(foregroundStyle)
                
                Spacer()
                
                Button {
                    closeAction()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(foregroundStyle.opacity(0.6))
                }
                .accessibilityLabel("Close settings")
            }
            .padding(.bottom, 5)
            
            // Theme selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Theme")
                    .font(.headline)
                    .foregroundColor(foregroundStyle)
                
                Picker("Theme", selection: $viewModel.appTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.title)
                            .tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Stroke Width
            VStack(alignment: .leading, spacing: 8) {
                Text("Stroke Width")
                    .font(.headline)
                    .foregroundColor(foregroundStyle)
                
                HStack {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(foregroundStyle.opacity(0.7))
                    
                    Slider(value: $viewModel.strokeWidthMultiplier, in: 0.5...2.0)
                        .accentColor(viewModel.currentColor)
                    
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .foregroundColor(foregroundStyle.opacity(0.7))
                }
            }
            
            // Show Note Letters Toggle
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Options")
                    .font(.headline)
                    .foregroundColor(foregroundStyle)
                
                Toggle(isOn: $viewModel.showNoteLetters) {
                    Text("Show Note Letters")
                        .foregroundColor(foregroundStyle)
                }
                .tint(viewModel.currentColor)
            }
            
            Spacer()
            
            // Version info
            Text("SonaStroke v1.0")
                .font(.caption)
                .foregroundColor(foregroundStyle.opacity(0.6))
        }
        .padding(20)
        .frame(width: 300)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 0)
        )
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 20)
    }
} 
