import SwiftUI

struct Phone2: View {
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
                // 1. Top-right: headerView
                VStack {
                    HStack {
                        Spacer()
                        headerView
                    }
                    Spacer()
                }
                .padding()

                // 2. Bottom-left: instrument button panel
                VStack {
                    Spacer()
                    HStack {
                        VStack {
                            if showInstruments {
                                VStack {
                                    InstrumentButtonWithoutName(iconName: "piano.png", isSelected: viewModel.currentInstrument == "Piano") {
                                        viewModel.currentInstrument = "Piano"
                                        viewModel.conductor.loadPianoPreset()
                                    }
                                    InstrumentButtonWithoutName(iconName: "guitar.png", isSelected: viewModel.currentInstrument == "Guitar") {
                                        viewModel.currentInstrument = "Guitar"
                                        viewModel.conductor.loadGuitarPreset()
                                    }
                                    InstrumentButtonWithoutName(iconName: "saks", isSelected: viewModel.currentInstrument == "Saxophone") {
                                        viewModel.currentInstrument = "Saxophone"
                                        viewModel.conductor.loadSaxophonePreset()
                                    }
                                    InstrumentButtonWithoutName(iconName: "violin.png", isSelected: viewModel.currentInstrument == "Violin") {
                                        viewModel.currentInstrument = "Violin"
                                        viewModel.conductor.loadViolinPreset()
                                    }
                                    InstrumentButtonWithoutName(iconName: "flute.png", isSelected: viewModel.currentInstrument == "Flute") {
                                        viewModel.currentInstrument = "Flute"
                                        viewModel.conductor.loadFlutePreset()
                                    }
                                    InstrumentButtonWithoutName(iconName: "trumpet.png", isSelected: viewModel.currentInstrument == "Trumpet") {
                                        viewModel.currentInstrument = "Trumpet"
                                        viewModel.conductor.loadTrumpetPreset()
                                    }
                                }
                                .padding(.vertical, 12)
                            }

                            Button {
                                withAnimation(.spring()) {
                                    showInstruments.toggle()
                                }
                            } label: {
                                Image(systemName: showInstruments ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 12)
                            }
                        }
                        .buttonStyle(ScalingButtonStyle())
                        .padding(.horizontal, 12)
                        .background(Capsule().fill(.ultraThinMaterial).shadow(radius: 5))
                        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .frame(width: 75, height: 350, alignment: .bottomLeading)
                        
                        Spacer()

                    }
                }
                .padding()

                // 3. Bottom-center: colorPanel
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        colorPanel
                        Spacer()
                    }
                }
                .padding(.bottom)

                // 4. Bottom-right: Play button
                VStack {
                    Spacer()
                    HStack {
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
                        .buttonStyle(ScalingButtonStyle())
                        .frame(width: 75, height: 75, alignment: .bottomTrailing)
                    }
                }
                .padding()
//                .frame(width: 670, height: 375)
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
        //        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.vertical, 8)
//        .frame(width: 675, height: 90, alignment: .trailing)
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
            }
        }
    }
}
struct InstrumentButtonWithoutName: View {
    let iconName: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .font(.system(size: 18, weight: .semibold))
                .frame(minWidth: 30, minHeight: 20)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.gray.opacity(0.3) : Color.black.opacity(0.0))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ?
                                    (colorScheme == .light ? Color.black.opacity(0.5) : Color.white.opacity(0.6))
                                    : Color.clear,
                                    lineWidth: 1
                                )
                        )
                )
        }
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .buttonStyle(ScalingButtonStyle())
    }
}


#Preview {
    Phone2()
}
