import SwiftUI

struct ContentView: View {
    // MARK: Properties
    @StateObject private var viewModel = SoundCanvasViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var foregroundStyle: Color {
        switch viewModel.appTheme {
        case .light: return .black
        case .dark: return .white
        case .colorful: return .white
        case .system: return colorScheme == .dark ? .white : .black
        }
    }
    
    // MARK: Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: viewModel.backgroundColors),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Canvas with zoom and pan
                CanvasView(viewModel: viewModel, size: geometry.size)
                    .scaleEffect(viewModel.canvasScale)
                    .offset(x: viewModel.canvasOffset.width, y: viewModel.canvasOffset.height)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / viewModel.canvasScale
                                viewModel.canvasScale = min(max(viewModel.canvasScale * delta, 0.5), 3.0)
                            }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
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
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.top, geometry.safeAreaInsets.top > 0 ? 0 : 10)
                    
                    Spacer()
                    
                    // Controls and indicator
                    VStack(spacing: 0) {
                        // Control panel toggle indicator - always visible
                        controlPanelIndicator(safeAreaBottom: geometry.safeAreaInsets.bottom)
                            .offset(y: viewModel.isControlPanelHidden ? 0 : 10) // Move down more to overlap better with panel
                            .zIndex(1) // Keep on top
                        
                        // Controls - can be hidden
                        if !viewModel.isControlPanelHidden {
                            controlPanel
                                .padding(.top, -20) // Increase negative padding to create more overlap
                                .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 5 : 20)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.35), value: viewModel.isControlPanelHidden)
                }
                .padding(.horizontal)
                
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

                // Bottom left sound control buttons
                VStack(spacing: 10) {
                    Button {
                        viewModel.conductor.setInstrument(2) // Oscillator
                    } label: {
                        HStack {
                            Image(systemName: "waveform")
                                .font(.system(size: 14))
                            Text("Oscillator")
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .frame(width: 120)
                    }
                    .background(viewModel.conductor.currentInstrument == 2 ? 
                        Color.blue.opacity(0.9) : Color.blue.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button {
                        viewModel.conductor.setInstrument(1) // Guitar
                    } label: {
                        HStack {
                            Image(systemName: "guitars")
                                .font(.system(size: 14))
                            Text("Guitar Oscillator")
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .frame(width: 120)
                    }
                    .background(viewModel.conductor.currentInstrument == 1 ? 
                        Color.green.opacity(0.9) : Color.green.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button {
                        viewModel.conductor.setInstrument(0) // Piano
                    } label: {
                        HStack {
                            Image(systemName: "pianokeys")
                                .font(.system(size: 14))
                            Text("Piano")
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .frame(width: 120)
                    }
                    .background(viewModel.conductor.currentInstrument == 0 ? 
                        Color.purple.opacity(0.9) : Color.purple.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button {
                        viewModel.conductor.setInstrument(3) // Drum
                    } label: {
                        HStack {
                            Image(systemName: "drum.fill")
                                .font(.system(size: 14))
                            Text("Drum")
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .frame(width: 120)
                    }
                    .background(viewModel.conductor.currentInstrument == 3 ? 
                        Color.yellow.opacity(0.9) : Color.yellow.opacity(0.6))
                    .foregroundColor(.black) // Using black text for better contrast on yellow
                    .cornerRadius(8)
                    
                    Button {
                        viewModel.conductor.setInstrument(4) // Guitar (Sampler)
                    } label: {
                        HStack {
                            Image(systemName: "guitars.fill")
                                .font(.system(size: 14))
                            Text("Guitar")
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .frame(width: 120)
                    }
                    .background(viewModel.conductor.currentInstrument == 4 ? 
                        Color.orange.opacity(0.9) : Color.orange.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .onChange(of: viewModel.showExportMenu) { _, newValue in
                if newValue {
                    viewModel.exportImage = viewModel.renderCanvasToImage(size: geometry.size)
                }
            }
        }
        .preferredColorScheme(preferredColorScheme)
        .sheet(isPresented: $viewModel.showTutorial) {
            TutorialView(theme: viewModel.appTheme, colorScheme: colorScheme)
                .preferredColorScheme(preferredColorScheme)
        }
        .animation(.interactiveSpring(duration: 0.5), value: viewModel.showSettings)
        .animation(.interactiveSpring(duration: 0.5), value: viewModel.showExportMenu)
        .animation(.easeInOut(duration: 0.3), value: viewModel.appTheme)
        .animation(.easeInOut(duration: 0.3), value: viewModel.activeStrokeId)
        .animation(.spring(response: 0.35), value: viewModel.isControlPanelHidden)
    }
    
    var preferredColorScheme: ColorScheme? {
        switch viewModel.appTheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        case .colorful: return .dark
        }
    }
    
    // MARK: - Component Views
    private var headerView: some View {
        HStack {
            // Title
            Text("Sound Canvas")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(foregroundStyle)
            
                Spacer()
            
            // Reset zoom/pan button
            Button {
                withAnimation(.spring(response: 0.4)) {
                    viewModel.resetCanvasView()
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(foregroundStyle)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.1))
                    )
            }
            .accessibilityLabel("Reset canvas view")
            
            // Settings button
            Button {
                withAnimation {
                    viewModel.showSettings.toggle()
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(foregroundStyle)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.1))
                    )
            }
            .accessibilityLabel("Open settings")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.primary.opacity(0.05))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        )
    }
    
    private var controlPanel: some View {
        VStack(spacing: 20) {
            // Color picker
            HStack(spacing: 12) {
                ForEach(0..<viewModel.colors.count, id: \.self) { index in
                    ColorButton(
                        color: viewModel.colors[index],
                        note: viewModel.colorNames[index],
                        instrument: viewModel.instrumentNames[index],
                        isSelected: viewModel.currentColorIndex == index,
                        action: {
                            viewModel.currentColorIndex = index
                            // Short preview of the sound
                            viewModel.conductor.playInstrument(colorIndex: index)
                            // Add haptic feedback
                            let impactLight = UIImpactFeedbackGenerator(style: .light)
                            impactLight.impactOccurred()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                viewModel.conductor.stopSound()
                            }
                        }
                    )
                    .accessibilityLabel("\(viewModel.colorNames[index]) note")
                    .accessibilityValue("Color: \(viewModel.colors[index].description)")
                    .accessibilityHint("Double tap to select this note and color")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            
            // Action buttons
            HStack(spacing: 15) {
                ActionButton(title: "Clear", systemImage: "trash") {
                    // Show confirmation instead of clearing immediately
                    viewModel.showClearConfirmation = true
                }
                .accessibilityLabel("Clear Canvas")
                
                ActionButton(title: "Replay", systemImage: "play.fill") {
                    viewModel.replayStrokes()
                }
                .accessibilityLabel("Replay Drawing")
                
                ActionButton(title: "Help", systemImage: "questionmark.circle") {
                    viewModel.showTutorial = true
                }
                .accessibilityLabel("Show Tutorial")
                
                ActionButton(title: "Export", systemImage: "square.and.arrow.up") {
                    viewModel.showExportMenu = true
                }
                .accessibilityLabel("Export Drawing")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .padding(.top, 10) // Additional top padding to account for the indicator overlap
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .alert(isPresented: $viewModel.showClearConfirmation) {
            Alert(
                title: Text("Clear Canvas?"),
                message: Text("This will permanently delete your drawing and musical creation. This action cannot be undone."),
                primaryButton: .destructive(Text("Clear All")) {
                    viewModel.clearCanvas()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func controlPanelIndicator(safeAreaBottom: CGFloat) -> some View {
        Button {
            withAnimation(.spring(response: 0.35)) {
                viewModel.isControlPanelHidden.toggle()
            }
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: viewModel.isControlPanelHidden ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(foregroundStyle.opacity(0.7))
                    .accessibilityHidden(true)
                
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(foregroundStyle.opacity(0.5))
                    .frame(width: 36, height: 4)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: viewModel.isControlPanelHidden ? 12 : 12,
                                 style: viewModel.isControlPanelHidden ? .continuous : .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: viewModel.isControlPanelHidden ? 1 : 0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: viewModel.isControlPanelHidden ? 12 : 12,
                                 style: viewModel.isControlPanelHidden ? .continuous : .continuous)
                    .stroke(foregroundStyle.opacity(0.1), lineWidth: 1)
            )
        }
        .accessibilityLabel(viewModel.isControlPanelHidden ? "Show controls" : "Hide controls")
        .contentShape(Rectangle())
        .padding(.bottom, viewModel.isControlPanelHidden ? (safeAreaBottom > 0 ? 10 : 25) : 0)
    }
}

#Preview {
    ContentView()
}
