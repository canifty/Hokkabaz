import SwiftUI

struct Phone: View {
    // MARK: Properties
    @StateObject private var viewModel = SoundCanvasViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showInstruments = false // New state for showing/hiding instruments
    
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
                // Background (unchanged)
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
                
                // Canvas with zoom and pan (unchanged)
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
                
                
                // UI Overlay - Modified to include collapsible instrument panel
                HStack(alignment: .bottom) {
                    // Instruments Panel - Now collapsible
                    VStack {
                        if showInstruments {
                            VStack(spacing: 12) {
                                InstrumentButtonWithoutName(
                                    iconName: "piano.png",
                                    isSelected: viewModel.currentInstrument == "Piano",
                                    action: {
                                        viewModel.currentInstrument = "Piano"
                                        viewModel.conductor.loadPianoPreset()
                                    }
                                )
                                
                                InstrumentButtonWithoutName(
                                    iconName: "guitar.png",
                                    isSelected: viewModel.currentInstrument == "Guitar",
                                    action: {
                                        viewModel.currentInstrument = "Guitar"
                                        viewModel.conductor.loadGuitarPreset()
                                    }
                                )
                                
                                InstrumentButtonWithoutName(
                                    iconName: "saks",
                                    isSelected: viewModel.currentInstrument == "Saxophone",
                                    action: {
                                        viewModel.currentInstrument = "Saxophone"
                                        viewModel.conductor.loadSaxophonePreset()
                                    }
                                )
                                
                                InstrumentButtonWithoutName(
                                    iconName: "violin.png",
                                    isSelected: viewModel.currentInstrument == "Violin",
                                    action: {
                                        viewModel.currentInstrument = "Violin"
                                        viewModel.conductor.loadViolinPreset()
                                    }
                                )
                                
                                InstrumentButtonWithoutName(
                                    iconName: "flute.png",
                                    isSelected: viewModel.currentInstrument == "Flute",
                                    action: {
                                        viewModel.currentInstrument = "Flute"
                                        viewModel.conductor.loadFlutePreset()
                                    }
                                )
                                
                                InstrumentButtonWithoutName(
                                    iconName: "trumpet.png",
                                    isSelected: viewModel.currentInstrument == "Trumpet",
                                    action: {
                                        viewModel.currentInstrument = "Trumpet"
                                        viewModel.conductor.loadTrumpetPreset()
                                    }
                                )
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .shadow(radius: 5)
                            )
//                            .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                        
                        // Chevron button - now functional
                        Button {
//                            withAnimation(.spring()) {
                                showInstruments.toggle()
//                            }
                        } label: {
                            Image(systemName: showInstruments ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.top, showInstruments ? 8 : 0)
                        .accessibilityLabel(showInstruments ? "Hide instruments" : "Show instruments")
                    }
                    .frame(width: showInstruments ? 80 : nil)
                    
                    Spacer()
                    
                    // Rest of your UI (unchanged)
                    VStack {
                        // Header
                        headerView
                            .padding(.top)
                        
                        Spacer()
                        
                        // Controls and indicator
                        HStack {
                            Spacer()
                            VStack {
                                // Control panel toggle indicator
//                                controlPanelIndicator(safeAreaBottom: geometry.safeAreaInsets.bottom)
//                                    .offset(y: viewModel.isControlPanelHidden ? 0 : 15)
//                                    .zIndex(1)
                                
                                // Controls
                                if !viewModel.isControlPanelHidden {
                                    colorPanel
                                        .padding(.top, -5)
//                                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 5 : 20)
//                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                            }
//                            .animation(.spring(response: 0.35), value: viewModel.isControlPanelHidden)
                            
                            Spacer()
                            
                            Button {
                                viewModel.showPlaybackControls ? viewModel.stopReplay() : viewModel.replayStrokes()
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
                            .padding(30)
                            .buttonStyle(ScalingButtonStyle())
                        }
                    }
                }
                
                // Settings and export panels (unchanged)
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
        .animation(.spring(), value: showInstruments) // Added for instrument panel
    }
    
    // Rest of your code remains unchanged...
    var preferredColorScheme: ColorScheme? {
        switch viewModel.appTheme {
        case .system: return nil
        case .canvas: return .light
        case .night: return .dark
        case .colorful: return .dark
        }
    }
    
    private var headerView: some View {
        HStack {
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
    
    private var colorPanel: some View {
        VStack {
            VStack {
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
                                viewModel.conductor.playInstrument(colorIndex: index)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    viewModel.conductor.stopSound()
                                }
                            }
                        )
                        .accessibilityLabel(String(describing: viewModel.colorNames[index]) + " note")
                        .accessibilityValue("Color: \(viewModel.colors[index].description)")
                        .accessibilityHint("Tap to select this note and color")
                    }
                }
//                .background(
//                    RoundedRectangle(cornerRadius: 16)
//                        .fill(.ultraThinMaterial)
//                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 15)
    }
    
//    private func controlPanelIndicator(safeAreaBottom: CGFloat) -> some View {
//        Button {
//            withAnimation(.spring(response: 0.35)) {
//                viewModel.isControlPanelHidden.toggle()
//            }
//        } label: {
//            Capsule()
//                .fill(Color.white.opacity(0.4))
//                .frame(width: 36, height: 5)
//                .padding(10)
//                .background(
//                    Capsule()
//                        .fill(.ultraThinMaterial)
//                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: viewModel.isControlPanelHidden ? 1 : 0)
//                )
//        }
//        .accessibilityLabel(viewModel.isControlPanelHidden ? "Show controls" : "Hide controls")
//        .contentShape(Rectangle())
//        .padding(.bottom, viewModel.isControlPanelHidden ? (safeAreaBottom > 0 ? 10 : 25) : 0)
//    }
}

//struct InstrumentButtonWithoutName: View {
//    let iconName: String
//    let isSelected: Bool
//    let action: () -> Void
//    @Environment(\.colorScheme) private var colorScheme
//    
//    var body: some View {
//        Button(action: action) {
//            Image(iconName)
//                .resizable()
//                .scaledToFit()
//                .frame(width: 50, height: 50)
//                .font(.system(size: 18, weight: .semibold))
//                .frame(minWidth: 30, minHeight: 20)
//                .padding(10)
//                .background(
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(isSelected ? Color.gray.opacity(0.3) : Color.black.opacity(0.0))
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 12)
//                                .stroke(
//                                    isSelected ?
//                                        (colorScheme == .light ? Color.black.opacity(0.5) : Color.white.opacity(0.6))
//                                        : Color.clear,
//                                    lineWidth: 1
//                                )
//                        )
//                )
//        }
//        .scaleEffect(isSelected ? 1.08 : 1.0)
//        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
//    }
//}

#Preview {
    Phone()
}
