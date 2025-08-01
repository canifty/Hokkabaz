import SwiftUI
import StoreKit

struct SettingsView: View {
    @ObservedObject var viewModel: SoundCanvasViewModel
    @AppStorage("hasReviewedApp") private var hasReviewedApp = false
    @Environment(\.colorScheme) var colorScheme
    var closeAction: () -> Void
    
    var foregroundStyle: Color {
        switch viewModel.appTheme {
        case .canvas: return .black
        case .night: return .white
        case .colorful: return .white
        case .system: return colorScheme == .dark ? .white : .black
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            ScrollView {
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
//                    Text("Theme")
//                        .font(.headline)
//                        .foregroundColor(foregroundStyle)
                    
                    Picker("Theme", selection: $viewModel.appTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.title)
                                .tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Show Note Letters Toggle
                VStack(alignment: .leading, spacing: 8) {
//                    Text("Display Options")
//                        .font(.headline)
//                        .foregroundColor(foregroundStyle)
                    
                    Toggle(isOn: $viewModel.showNoteLetters) {
                        Text("Show Note Letters")
                            .foregroundColor(foregroundStyle)
                    }
                    .tint(viewModel.currentColor)
                }
                
                // Brush Type Selection
                VStack(alignment: .leading, spacing: 8) {
//                    Text("Brush Type")
//                        .font(.headline)
                    
                    
                    HStack(spacing: 8) {
                        ForEach(BrushType.allCases, id: \.self) { brushType in
                            BrushTypeButton(
                                brushType: brushType,
                                isSelected: brushType == viewModel.currentBrushType,
                                action: {
                                    viewModel.setBrushType(brushType)
                                }
                            )
                        }
                    }
                    //                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                    //                        ForEach(BrushType.allCases, id: \.self) { brushType in
                    //                            BrushTypeButton(
                    //                                brushType: brushType,
                    //                                isSelected: brushType == viewModel.currentBrushType,
                    //                                action: {
                    //                                    viewModel.setBrushType(brushType)
                    //                                }
                    //                            )
                    //                        }
                    //                    }
                }
                //                .padding()
                //                .cornerRadius(12)
                
                // Brush Properties
                VStack(alignment: .leading, spacing: 8) {
//                    Text("Brush Properties")
//                        .font(.headline)
                    
                    // Width Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Width")
                            Spacer()
                            Text("\(Int(viewModel.currentBrushWidth))")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: $viewModel.currentBrushWidth,
                            in: 2...50,
                            step: 1
                        ) {
                            Text("Brush Width")
                        }
                        .accentColor(viewModel.currentColor)
                    }
                    
                    // Opacity Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Opacity")
                            Spacer()
                            Text("\(Int(viewModel.currentBrushOpacity * 100))%")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: $viewModel.currentBrushOpacity,
                            in: 0.1...1.0,
                            step: 0.1
                        ) {
                            Text("Brush Opacity")
                        }
                        .accentColor(viewModel.currentColor)
                    }
                    
                    // Hardness Slider (for applicable brush types)
                    //                    if viewModel.currentBrushType != .pen {
                    //                        VStack(alignment: .leading, spacing: 8) {
                    //                            HStack {
                    //                                Text("Hardness")
                    //                                Spacer()
                    //                                Text("\(Int(viewModel.currentBrushHardness * 100))%")
                    //                                    .foregroundColor(.secondary)
                    //                            }
                    //
                    //                            Slider(
                    //                                value: $viewModel.currentBrushHardness,
                    //                                in: 0.0...1.0,
                    //                                step: 0.1
                    //                            ) {
                    //                                Text("Brush Hardness")
                    //                            }
                    //                            .accentColor(viewModel.currentColor)
                    //                        }
                    //                    }
                }
                //                .padding()
                //                .cornerRadius(12)
                
                // Preview
                BrushPreviewView(viewModel: viewModel)
                
            }
                Spacer()
                Text("SonaStroke")
                    .font(.caption)
                    .foregroundColor(foregroundStyle.opacity(0.6))
                Button {
                    requestReview()
                    hasReviewedApp = true // hide button after tap

                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Review Us")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                    }
                        .font(.subheadline.bold())
                        .foregroundColor(foregroundStyle)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(.ultraThickMaterial)
                        .cornerRadius(10)
                }
            }
            // Version info
            
        }
        .padding(20)
        .frame(width: 280)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 0)
        )
        .frame(maxWidth: .infinity, alignment: .trailing)
        //        .frame(width: 300, height: 350, alignment: .trailing)
        //        .padding(.trailing, 20)
        //        .padding(.vertical, 20)
        
    }
    private func requestReview() {
        if let url = URL(string: "https://apps.apple.com/app/id6742818533?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsView(
        viewModel: SoundCanvasViewModel(),
        closeAction: {}
    )
}

struct BrushTypeButton: View {
    let brushType: BrushType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: brushType.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
//                Text(brushType.rawValue)
//                    .font(.caption)
//                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 45, height: 45)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .cornerRadius(12)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BrushPreviewView: View {
    @ObservedObject var viewModel: SoundCanvasViewModel
    
    var body: some View {
        VStack {
            
            Canvas { context, size in
                let previewPath = Path { path in
                    let startPoint = CGPoint(x: size.width * 0.2, y: size.height * 0.5)
                    let endPoint = CGPoint(x: size.width * 0.8, y: size.height * 0.5)
                    path.move(to: startPoint)
                    path.addLine(to: endPoint)
                }
                
                // Draw preview stroke based on current brush settings
                let brush = viewModel.currentBrushProperties
                
                switch brush.type {
                case .marker:
                    // Soft outer edge
                    context.stroke(
                        previewPath,
                        with: .color(viewModel.currentColor.opacity(brush.opacity * 0.3)),
                        style: StrokeStyle(
                            lineWidth: brush.width * 1.5,
                            lineCap: .round
                        )
                    )
                    fallthrough
                default:
                    context.stroke(
                        previewPath,
                        with: .color(viewModel.currentColor.opacity(brush.opacity)),
                        style: StrokeStyle(
                            lineWidth: brush.width,
                            lineCap: .round
                        )
                    )
                }
            }
            .frame(height: 60)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
}
