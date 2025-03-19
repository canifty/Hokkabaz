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
                if viewModel.appTheme == .light {
                    Image("canvas")
                        .resizable()
                        .scaledToFill()
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
                                .padding(.top, -5) // Increase negative padding to create more overlap
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
                
                // bottom-right replay button
                Button {
                    viewModel.replayStrokes()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                        Text("Replay")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 18)
                    .background(
                        Capsule()
                            .fill(
                                .ultraThinMaterial
                            )
                            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .accessibilityLabel("Replay Drawing")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(30)
                .buttonStyle(ScalingButtonStyle())
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
        case .light: return .light
        case .dark: return .dark
        case .colorful: return .dark
        }
    }
    
    // MARK: - Component Views
    private var headerView: some View {
        HStack {

            
//            Spacer()
            //            !!!!!
            // Reset zoom/pan button
            
            Button {
                withAnimation(.spring(response: 0.4)) {
                    viewModel.showClearConfirmation = true
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(foregroundStyle)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.1))
                    )
            }
            .accessibilityLabel("Clear the Canvas")
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
            
            Button {
                withAnimation(.spring(response: 0.4)) {
                    viewModel.undoLastStroke()
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
            .accessibilityLabel("Undo the stroke")
            
            Button {
                withAnimation(.spring(response: 0.4)) {
                    viewModel.showExportMenu = true
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(foregroundStyle)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.1))
                    )
            }
            .accessibilityLabel("Export Drawing")
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
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    private var controlPanel: some View {
        VStack(spacing: 20) {
            // Color buttons - removed header and ScrollView
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ForEach(0..<viewModel.colors.count, id: \.self) { index in
                        ColorButton(
                            color: viewModel.colors[index],
                            note: viewModel.colorNames[index],
                            instrument: viewModel.instrumentNames[index],
                            isSelected: viewModel.currentColorIndex == index,
                            showNote: viewModel.showNoteLetters,
                            action: {
                                viewModel.currentColorIndex = index
                                // Short preview of the sound
                                viewModel.conductor.playInstrument(colorIndex: index)
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    viewModel.conductor.stopSound()
                                }
                            }
                        )
                        .accessibilityLabel(String(describing: viewModel.colorNames[index]) + " note")
                        .accessibilityValue("Color: \(viewModel.colors[index].description)")
                        .accessibilityHint("Double tap to select this note and color")
                    }
                }
//                .padding(.horizontal, 16)
//                .padding(.vertical, 6)
//                .background(
//                    RoundedRectangle(cornerRadius: 16)
//                        .fill(.ultraThinMaterial)
//                )
            }
            
            // Instruments section - removed header, ScrollView, and picker
            VStack(alignment: .leading, spacing: 8) {
                // Main instrument buttons in a row - replaced picker with buttons
                HStack {
                    
                    InstrumentButton(
                        iconName: "piano1.png",
                        instrumentName: "Piano",
                        isSelected: viewModel.currentInstrument == "Piano",
                        action: {
                            viewModel.currentInstrument = "Piano"
                            viewModel.conductor.loadPianoPreset()
                        }
                    )
                    .foregroundColor(foregroundStyle)
                    .accessibilityLabel("Switch to Piano")
                    
                    InstrumentButton(
                        iconName: "guitar.png",
                        instrumentName: "Guitar",
                        isSelected: viewModel.currentInstrument == "Guitar",
                        action: {
                            viewModel.currentInstrument = "Guitar"
                            viewModel.conductor.loadGuitarPreset()
                        }
                    )
                    .foregroundColor(foregroundStyle)
                    .accessibilityLabel("Switch to Guitar")
                
                    InstrumentButton(
                        iconName: "saxaphone.png",
                        instrumentName: "Saxophone",
                        isSelected: viewModel.currentInstrument == "Saxophone",
                        action: {
                            viewModel.currentInstrument = "Saxophone"
                            viewModel.conductor.loadSaxophonePreset()
                        }
                    )
                    .foregroundColor(foregroundStyle)
                    .accessibilityLabel("Switch to Saxophone")
                    
                    InstrumentButton(
                        iconName: "violin.png",
                        instrumentName: "Violin",
                        isSelected: viewModel.currentInstrument == "Violin",
                        action: {
                            viewModel.currentInstrument = "Violin"
                            viewModel.conductor.loadViolinPreset()
                        }
                    )
                    .foregroundColor(foregroundStyle)
                    .accessibilityLabel("Switch to Violin")
                    
                    InstrumentButton(
                        iconName: "flute.png",
                        instrumentName: "Flute",
                        isSelected: viewModel.currentInstrument == "Flute",
                        action: {
                            viewModel.currentInstrument = "Flute"
                            viewModel.conductor.loadFlutePreset()
                        }
                    )
                    .foregroundColor(foregroundStyle)
                    .accessibilityLabel("Switch to Flute")
                    
                    InstrumentButton(
                        iconName: "trumpet1.png",
                        instrumentName: "Trumpet", 
                        isSelected: viewModel.currentInstrument == "Trumpet",
                        action: {
                            viewModel.currentInstrument = "Trumpet"
                            viewModel.conductor.loadTrumpetPreset()
                        }
                    )
                    .foregroundColor(foregroundStyle)
                    .accessibilityLabel("Switch to Trumpet")
                }
                .padding(.horizontal, 16)
                .padding(.vertical)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 15)
        .padding(.top)
        .frame(width: 680, height: 220, alignment: .bottom)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
    
    private func controlPanelIndicator(safeAreaBottom: CGFloat) -> some View {
        Button {
            withAnimation(.spring(response: 0.35)) {
                viewModel.isControlPanelHidden.toggle()
            }
            // Add haptic feedback
//            let generator = UIImpactFeedbackGenerator(style: .light)
//            generator.impactOccurred()
        } label: {
            Capsule()
                .fill(Color.white.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(10)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: viewModel.isControlPanelHidden ? 1 : 0)
                )
        }
        .accessibilityLabel(viewModel.isControlPanelHidden ? "Show controls" : "Hide controls")
        .contentShape(Rectangle())
        .padding(.bottom, viewModel.isControlPanelHidden ? (safeAreaBottom > 0 ? 10 : 25) : 0)
    }
}

// Add this custom button style to the ContentView struct (outside the body but inside ContentView)
struct ScalingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .brightness(configuration.isPressed ? 0.05 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
} 

#Preview("English") {
    ContentView()
}

#Preview("Turkish") {
    ContentView()
        .environment(\.locale, Locale(identifier: "TR"))
}

#Preview("Persian") {
    ContentView()
        .environment(\.locale, Locale(identifier: "FA"))
}

#Preview("Chinese") {
    ContentView()
        .environment(\.locale, Locale(identifier: "ZH"))
}

#Preview("Italian") {
    ContentView()
        .environment(\.locale, Locale(identifier: "ITA"))
}

#Preview("Japanese") {
    ContentView()
        .environment(\.locale, Locale(identifier: "JPN"))
}

#Preview("Spanish") {
    ContentView()
        .environment(\.locale, Locale(identifier: "SP"))
}

#Preview("Arabic") {
    ContentView()
        .environment(\.locale, Locale(identifier: "AR"))
}

#Preview("Portuguese") {
    ContentView()
        .environment(\.locale, Locale(identifier: "PT"))
}

