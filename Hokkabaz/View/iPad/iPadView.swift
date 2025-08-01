import SwiftUI

struct iPadView: View {
    // MARK: Properties
    @Environment(\.requestReview) var requestReview
    @AppStorage("playButtonTapCount") private var playButtonTapCount = 0
    
    @StateObject private var viewModel = SoundCanvasViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var scalePercentage: String = ""
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    var foregroundStyle: Color {
        switch viewModel.appTheme {
        case .canvas: return .black
        case .night: return .white
        case .colorful: return .white
        case .system: return colorScheme == .dark ? .white : .black
        }
    }
    
    // MARK: Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                if viewModel.appTheme == .canvas {
                    Image("canvas")
                        .resizable()
                        .ignoresSafeArea()
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: viewModel.backgroundColors),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
                
                // Canvas with zoom and pan
                CanvasView(viewModel: viewModel, size: geometry.size)
                    .scaleEffect(viewModel.canvasScale)
                    .offset(x: viewModel.canvasOffset.width, y: viewModel.canvasOffset.height)
//                    .gesture(
//                        MagnificationGesture()
//                            .onChanged { value in
//                                // If user was drawing, end the current stroke before zooming
//                                if !viewModel.currentStroke.isEmpty {
//                                    viewModel.endDrawing()
//                                }
//                                
//                                let delta = value / viewModel.canvasScale
//                                viewModel.canvasScale = min(max(viewModel.canvasScale * delta, 0.5), 3.0)
//                                
//                                scalePercentage = String(format: "%.0f", viewModel.canvasScale * 100)  // Update the scale percentage
//                            }
//                            .onEnded { _ in
//                                // Clear the scale percentage when zooming ends
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                                    scalePercentage = ""
//                                }
//                            }
//                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                if viewModel.currentStroke.isEmpty {
                                    viewModel.startDrawing(at: viewModel.convertPointForCanvas(value.location, size: geometry.size))
                                } else {
                                    viewModel.continueDrawing(at: viewModel.convertPointForCanvas(value.location, size: geometry.size))
                                }
                            }
                            .onEnded { _ in
                                viewModel.endDrawing()
                            }
                    )
                
                // UI Overlay
                VStack {
                    // Header
                    HStack {
                        Spacer()
                        
                        HeaderView(viewModel: viewModel, foregroundStyle: foregroundStyle)
                        
                    }
                    Spacer()
                    
                    // Controls and indicator
                    VStack {
                        // Control panel toggle indicator - always visible
                        controlPanelIndicator(viewModel: viewModel, safeAreaBottom: geometry.safeAreaInsets.bottom)
                            .offset(y: viewModel.isControlPanelHidden ? 0 : 15) // Move down more to overlap better with panel
                            .zIndex(1) // Keep on top
                        
                        // Controls - can be hidden
                        if !viewModel.isControlPanelHidden {
                            ControlPanel(viewModel: viewModel)
                                .padding(.top, -5) // Increase negative padding to create more overlap
                                .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 5 : 20)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.35), value: viewModel.isControlPanelHidden)
                }
                .padding(.horizontal)
                
                
                
                
                Button {
                    viewModel.showPlaybackControls ? viewModel.stopReplay() : viewModel.replayStrokes()
                    
                    playButtonTapCount += 1
                    
                    // Request review after 3 taps
                    if playButtonTapCount == 3 {
                        requestReview()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.showPlaybackControls ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                        Text(viewModel.showPlaybackControls ? "Stop" : "Replay")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 18)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .accessibilityLabel(viewModel.showPlaybackControls ? "Stop playback" : "Replay Drawing")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding( 30)
                .buttonStyle(ScalingButtonStyle())
                
                
                // Settings panel (slide in from right)
                if viewModel.showSettings {
                    SettingsView(viewModel: viewModel) {
                        withAnimation {
                            viewModel.showSettings = false
                        }
                    }
                    .transition(.move(edge: .trailing))
                    .zIndex(2)
                }
                
                // Export panel (slides up from bottom)
                if viewModel.showExportMenu, let image = viewModel.exportImage {
                    ExportView(image: image) {
                        withAnimation {
                            viewModel.showExportMenu = false
                        }
                    }
                    .transition(.move(edge: .bottom))
                    .zIndex(3)
                }
            }
            .onChange(of: viewModel.showExportMenu) { _, newValue in
                if newValue {
                    viewModel.exportImage = viewModel.renderCanvasToImage(size: geometry.size)
                }
            }
        }
        
        .preferredColorScheme(preferredColorScheme)
        
        .animation(.interactiveSpring(duration: 0.5), value: viewModel.showSettings)
        .animation(.interactiveSpring(duration: 0.5), value: viewModel.showExportMenu)
        .animation(.easeInOut(duration: 0.3), value: viewModel.appTheme)
        .animation(.easeInOut(duration: 0.3), value: viewModel.activeStrokeId)
        .animation(.spring(response: 0.35), value: viewModel.isControlPanelHidden)
        .animation(.spring(response: 0.1), value: viewModel.showNoteLetters)
    }
    
    var preferredColorScheme: ColorScheme? {
        switch viewModel.appTheme {
        case .system: return nil
        case .canvas: return .light
        case .night: return .dark
        case .colorful: return .dark
        }
    }
}


#Preview("English") {
    iPadView()
}

//#Preview("Turkish") {
//    iPadView()
//        .environment(\.locale, Locale(identifier: "TR"))
//}
//
//#Preview("Persian") {
//    iPadView()
//        .environment(\.locale, Locale(identifier: "FA"))
//}
//
//#Preview("Chinese") {
//    iPadView()
//        .environment(\.locale, Locale(identifier: "ZH"))
//}
//
//#Preview("Italian") {
//    iPadView()
//        .environment(\.locale, Locale(identifier: "ITA"))
//}
//
//#Preview("Japanese") {
//    iPadView()
//        .environment(\.locale, Locale(identifier: "JPN"))
//}
//
//#Preview("Spanish") {
//    iPadView()
//        .environment(\.locale, Locale(identifier: "ES"))
//}
//
//#Preview("Arabic") {
//    iPadView()
//        .environment(\.locale, Locale(identifier: "AR"))
//}
//
//#Preview("Portuguese") {
//    iPadView()
//        .environment(\.locale, Locale(identifier: "PT"))
//}
