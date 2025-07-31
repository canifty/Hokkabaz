import SwiftUI
import StoreKit

struct PhoneView: View {
    // MARK: Properties
    @Environment(\.requestReview) var requestReview
    @AppStorage("playButtonTapCount") private var playButtonTapCount = 0
    
    @StateObject private var viewModel = SoundCanvasViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showInstruments = false // New state for showing/hiding instruments
    @State private var scalePercentage: String = ""
    
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
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                // If user was drawing, end the current stroke before zooming
                                if !viewModel.currentStroke.isEmpty {
                                    viewModel.endDrawing()
                                }
                                
                                let delta = value / viewModel.canvasScale
                                viewModel.canvasScale = min(max(viewModel.canvasScale * delta, 0.5), 3.0)
                                
                                scalePercentage = String(format: "%.0f", viewModel.canvasScale * 100)  // Update the scale percentage
                            }
                            .onEnded { _ in
                                // Clear the scale percentage when zooming ends
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    scalePercentage = ""
                                }
                            }
                    )
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
 
                // 1. Top right: headerView
                VStack {
                    HStack {
                        Spacer()
                        Spacer()
                        Spacer()

                        if !scalePercentage.isEmpty {
                            Text("Zoom: \(scalePercentage)%")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.1))
                                .cornerRadius(20)
                                .transition(.opacity)
                        }
                        Spacer()
                        HeaderView(viewModel: viewModel, foregroundStyle: foregroundStyle)
                    }
                    Spacer()
                }
                .padding()

                // 2. Bottom left: instrument button panel
                VStack {
                    Spacer()
                    HStack {
                        InstrumentPanelView(showInstruments: $showInstruments, viewModel: viewModel)
                        Spacer()
                    }
                }
                .padding()

                // 3. Bottom center: colorPanel
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ColorPanel(viewModel: viewModel)
                        Spacer()
                    }
                }
                .padding(.bottom)

                // 4. Bottom right: Play button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            viewModel.showPlaybackControls ? viewModel.stopReplay() : viewModel.replayStrokes()
                             
                            playButtonTapCount += 1
                            
                            // Request review after 3 taps
                            if playButtonTapCount == 3 {
                                requestReview()
                            }
                            
                        } label: {
                            Image(systemName: viewModel.showPlaybackControls ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
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
                        .buttonStyle(PressableButtonStyle())
                        .frame(width: 75, height: 75, alignment: .bottomTrailing)
                    }
                }
                .padding()
                if viewModel.showSettings {
                    SettingsView(viewModel: viewModel) {
                        withAnimation {
                            viewModel.showSettings = false
                        }
                    }
                    .transition(.move(edge: .trailing))
                    .zIndex(2)
                }
                
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
        .animation(.spring(), value: showInstruments)
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

#Preview {
    PhoneView()
}
