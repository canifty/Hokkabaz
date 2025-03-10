import SwiftUI
import AudioKit
import AVFoundation
import SoundpipeAudioKit

class Conductor: ObservableObject {
    let engine = AudioEngine()
    let sampler = AppleSampler()
    
    // Add an oscillator as backup sound source
    let oscillator = Oscillator()
    
    var isPlaying = false
    var usingSampler = true // Flag to track which sound source we're using
    
    // Map colors to different instruments (General MIDI program numbers)
    // These correspond to: Piano, Guitar, Flute, Violin, Trumpet, Harp, Cello
    let instrumentPrograms = [0, 24, 73, 40, 56, 46, 42]
    
    // MIDI note numbers for C4 to B4 (middle C octave)
    let midiNotes: [MIDINoteNumber] = [60, 62, 64, 65, 67, 69, 71] 
    
    // Frequencies for alternative sound production
    let noteFrequencies: [AUValue] = [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88]
    
    // Current instrument program
    @Published var currentInstrument = 0
    
    init() {
        print("🔊 Initializing AudioKit engine...")
        
        // Check and configure audio session
        configureAudioSession()
        
        // Configure oscillator as backup
        oscillator.amplitude = 0.5
        oscillator.frequency = noteFrequencies[0]
        
        // Try to use sampler first
        engine.output = sampler
        
        do {
            try engine.start()
            print("✅ AudioKit engine started successfully")
            // Load default sounds
            if !loadDefaultSounds() {
                // If sampler setup fails, switch to oscillator
                switchToOscillator()
            }
        } catch {
            print("❌ AudioKit ERROR: \(error)")
            Log("AudioKit did not start: \(error)")
            // Try oscillator as fallback
            switchToOscillator()
        }
    }
    
    func switchToOscillator() {
        print("🔄 Switching to oscillator as sound source")
        engine.output = oscillator
        usingSampler = false
        
        // Make sure engine is running
        if !engine.avEngine.isRunning {
            do {
                try engine.start()
                print("✅ AudioKit engine restarted with oscillator")
            } catch {
                print("❌ Failed to restart engine with oscillator: \(error)")
            }
        }
    }
    
    func switchToSampler() {
        print("🔄 Switching to sampler as sound source")
        engine.output = sampler
        usingSampler = true
        
        // Make sure engine is running
        if !engine.avEngine.isRunning {
            do {
                try engine.start()
                print("✅ AudioKit engine restarted with sampler")
            } catch {
                print("❌ Failed to restart engine with sampler: \(error)")
            }
        }
    }
    
    func loadPianoPreset() {
        // Ensure we're using the sampler
        if !usingSampler {
            switchToSampler()
        }
        
        print("🎹 Attempting to load piano preset...")
        
        // Try multiple approaches to load a piano sound
        
        // Method 1: Try default piano instrument (GM piano is program 0)
        do {
            // The AudioKit docs say this should work, but it might not in all versions
            try sampler.loadInstrument(at: URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls"))
            print("✅ Loaded Apple DLS instrument")
            return
        } catch {
            print("❌ Failed to load Apple DLS instrument: \(error)")
        }
        
        // Method 2: Try loading default Apple piano sound
        do {
            // Force try loading a generic piano preset that should be available on all iOS devices
            let url = Bundle.main.url(forResource: "Sounds/Piano", withExtension: "sf2") ??
                      Bundle.main.url(forResource: "Piano", withExtension: "sf2") ??
                      Bundle.main.url(forResource: "Piano", withExtension: "dls")
            
            if let pianoURL = url {
                try sampler.loadSoundFont(pianoURL.path, preset: 0, bank: 0)
                print("✅ Loaded built-in Piano sound")
                return
            }
        } catch {
            print("❌ Failed to load built-in Piano sound: \(error)")
        }
        
        print("ℹ️ Piano preset loading failed, falling back to soundfont search")
        // If we couldn't load piano specifically, just try to load any soundfont again
        if !loadDefaultSounds() {
            print("⚠️ All attempts to load instrument sounds failed")
        }
    }
    
    func configureAudioSession() {
        do {
            print("🎧 Configuring audio session...")
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
            // Check audio output configuration
            if let currentRoute = session.currentRoute.outputs.first {
                print("✅ Current audio output: \(currentRoute.portName)")
            } else {
                print("⚠️ No audio output route available")
            }
            
            // Check volume
            print("📊 Current system volume: \(session.outputVolume)")
            if session.outputVolume < 0.2 {
                print("⚠️ WARNING: System volume is very low, please increase volume")
            }
            
        } catch {
            print("❌ Audio session configuration error: \(error)")
        }
    }
    
    func loadDefaultSounds() -> Bool {
        print("🔍 Searching for soundfont...")
        
        // IMPORTANT: Instead of looking for "GeneralUser GS.sf2", let's look for any .sf2 file
        let soundfontFiles = Bundle.main.urls(forResourcesWithExtension: "sf2", subdirectory: nil)
        
        if let files = soundfontFiles, !files.isEmpty {
            print("📁 Found \(files.count) SF2 files in bundle:")
            files.forEach { url in
                print("   - \(url.lastPathComponent)")
            }
            
            // Try to load each of them until one works
            for soundfontURL in files {
                print("🔄 Trying to load soundfont: \(soundfontURL.lastPathComponent)...")
                
                // Experiment with both preset 0 and preset -1
                let presets = [0, -1]
                let banks = [0, 128]
                
                for preset in presets {
                    for bank in banks {
                        do {
                            print("   - Attempting with preset: \(preset), bank: \(bank)")
                            try sampler.loadSoundFont(soundfontURL.path, preset: preset, bank: bank)
                            print("✅ SUCCESS! Loaded soundfont: \(soundfontURL.lastPathComponent) with preset: \(preset), bank: \(bank)")
                            return true
                        } catch {
                            print("   - Failed with preset: \(preset), bank: \(bank), error: \(error)")
                        }
                    }
                }
            }
            
            print("❌ Failed to load any soundfonts with any preset/bank combination")
        } else {
            print("📁 No SF2 files found in the bundle at all!")
        }
        
        // Try old method as last resort
        if let bundledSoundfontURL = Bundle.main.url(forResource: "GeneralUser GS", withExtension: "sf2") {
            print("✅ Found soundfont at path: \(bundledSoundfontURL.path)")
            do {
                try sampler.loadSoundFont(bundledSoundfontURL.path, preset: 0, bank: 0)
                print("✅ Soundfont loaded successfully!")
                return true
            } catch {
                print("❌ Failed to load soundfont: \(error)")
            }
        }
        
        // If we got here, we failed to set up the sampler properly
        print("⚠️ Falling back to oscillator for sound generation")
        return false
    }
    
    func playInstrument(colorIndex: Int) {
        let noteNumber = midiNotes[min(colorIndex, midiNotes.count - 1)]
        
        // Play the note - using sampler or oscillator
        print("🎵 Playing note: \(noteNumber) for color index: \(colorIndex)")
        
        if usingSampler {
            // Using sampler (Apple Sampler)
            sampler.play(noteNumber: noteNumber, velocity: 120)
        } else {
            // Using oscillator as fallback
            let frequency = noteFrequencies[min(colorIndex, noteFrequencies.count - 1)]
            oscillator.frequency = frequency
            oscillator.amplitude = 0.5
            oscillator.start()
        }
        
        isPlaying = true
    }
    
    func stopSound() {
        if isPlaying {
            print("🛑 Stopping sound")
            if usingSampler {
                // Stop all notes individually in sampler
                for noteNumber in midiNotes {
                    sampler.stop(noteNumber: noteNumber)
                }
            } else {
                // Stop oscillator
                oscillator.stop()
            }
            isPlaying = false
        }
    }
}

// MARK: - Main View
struct ContentView: View {
    // MARK: Properties
    @StateObject private var conductor = Conductor()
    @State private var strokes: [(id: UUID, points: [CGPoint], color: Color)] = []
    @State private var currentStroke: [CGPoint] = []
    @State private var showTutorial = false
    @State private var currentColorIndex = 2 // Default to green (index 2)
    @State private var showSettings = false
    @State private var canvasScale: CGFloat = 1.0
    @State private var canvasOffset = CGSize.zero
    @State private var activeStrokeId: UUID? = nil
    @State private var showExportMenu = false
    @State private var exportImage: UIImage? = nil
    @State private var strokeWidthMultiplier: CGFloat = 1.0
    @State private var appTheme: AppTheme = .dark
    @State private var showClearConfirmation = false
    @State private var isControlPanelHidden = false
    @Environment(\.colorScheme) private var colorScheme
    
    enum AppTheme: String, CaseIterable, Identifiable {
        case system, light, dark, colorful
        var id: Self { self }
        
        var title: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            case .colorful: return "Colorful"
            }
        }
    }
    
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    let colorNames: [String] = ["C", "D", "E", "F", "G", "A", "B"]
    let instrumentNames: [String] = ["Piano", "Guitar", "Flute", "Violin", "Trumpet", "Harp", "Cello"]
    let frequencies: [AUValue] = [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88]
    
    var currentColor: Color {
        colors[currentColorIndex]
    }
      
    var backgroundColors: [Color] {
        switch appTheme {
        case .light:
            return [Color(white: 0.9), Color(white: 0.95)]
        case .dark:
            return [Color.black.opacity(0.8), Color(red: 0.1, green: 0.1, blue: 0.3)]
        case .colorful:
            return [Color.purple.opacity(0.7), Color.blue.opacity(0.5)]
        case .system:
            return colorScheme == .dark
                ? [Color.black.opacity(0.8), Color(red: 0.1, green: 0.1, blue: 0.3)]
                : [Color(white: 0.9), Color(white: 0.95)]
        }
    }
    
    var foregroundStyle: Color {
        switch appTheme {
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
                    gradient: Gradient(colors: backgroundColors),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Canvas with zoom and pan
                canvasView(size: geometry.size)
                    .scaleEffect(canvasScale)
                    .offset(x: canvasOffset.width, y: canvasOffset.height)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / canvasScale
                                canvasScale = min(max(canvasScale * delta, 0.5), 3.0)
                            }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if currentStroke.isEmpty {
                        startSoundForColor()
                                    // Add haptic feedback
                                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                                    impactMed.impactOccurred()
                                    currentStroke.append(convertPointForCanvas(value.location, size: geometry.size))
                                } else {
                                    currentStroke.append(convertPointForCanvas(value.location, size: geometry.size))
                                }
                }
                .onEnded { _ in
                                if !currentStroke.isEmpty {
                                    let newStroke = (id: UUID(), points: currentStroke, color: currentColor)
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        strokes.append(newStroke)
                                    }
                    currentStroke.removeAll()
                    conductor.stopSound()
                                }
                            }
                    )
                
                // UI Overlay
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.top, geometry.safeAreaInsets.top > 0 ? 0 : 10)
                    
                    // Sound test button for debugging
//                    Button("🔊 Test Sound") {
//                        print("DEBUG: Testing sound...")
//                        // Try playing the piano note with verbose logging
//                        for colorIndex in 0..<7 {
//                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(colorIndex) * 0.3) {
//                                print("Testing sound for color \(colorIndex)")
//                                conductor.playInstrument(colorIndex: colorIndex)
//                                
//                                // Stop after a delay
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                                    conductor.stopSound()
//                                }
//                            }
//                        }
//                    }
//                    .padding(10)
//                    .background(Color.red.opacity(0.8))
//                    .foregroundColor(.white)
//                    .cornerRadius(8)
//                    .shadow(radius: 3)
//                    .padding()
                    
                    Spacer()
                    
                    // Controls and indicator
                    VStack(spacing: 0) {
                        // Control panel toggle indicator - always visible
                        controlPanelIndicator(safeAreaBottom: geometry.safeAreaInsets.bottom)
                            .offset(y: isControlPanelHidden ? 0 : 10) // Move down more to overlap better with panel
                            .zIndex(1) // Keep on top
                        
                        // Controls - can be hidden
                        if !isControlPanelHidden {
                            controlPanel
                                .padding(.top, -20) // Increase negative padding to create more overlap
                                .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 5 : 20)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.35), value: isControlPanelHidden)
                }
                .padding(.horizontal)
                
                // Settings panel (slide in from right)
                if showSettings {
                    settingsPanel
                        .transition(.move(edge: .trailing))
                        .zIndex(2)
                }
                
                // Export panel (slides up from bottom)
                if showExportMenu, let image = exportImage {
                    exportPanel(image: image)
                        .transition(.move(edge: .bottom))
                        .zIndex(3)
                }

                // Bottom left sound control buttons
                VStack(spacing: 10) {
                    Button("Oscillator") {
                        conductor.switchToOscillator()
                    }
                    .font(.caption)
                    .padding()
                    .background(Color.blue.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("Piano") {
                        conductor.loadPianoPreset()
                    }
                    .font(.caption)
                    .padding()
                    .background(Color.purple.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .onChange(of: showExportMenu) { _, newValue in
                if newValue {
                    exportImage = renderCanvasToImage(size: geometry.size)
                }
            }
        }
        .preferredColorScheme(preferredColorScheme)
        .sheet(isPresented: $showTutorial) {
            TutorialView(theme: appTheme, colorScheme: colorScheme)
                .preferredColorScheme(preferredColorScheme)
        }
        .animation(.interactiveSpring(duration: 0.5), value: showSettings)
        .animation(.interactiveSpring(duration: 0.5), value: showExportMenu)
        .animation(.easeInOut(duration: 0.3), value: appTheme)
        .animation(.easeInOut(duration: 0.3), value: activeStrokeId)
        .animation(.spring(response: 0.35), value: isControlPanelHidden)
    }
    
    var preferredColorScheme: ColorScheme? {
        switch appTheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        case .colorful: return .dark
        }
    }
    
    // MARK: - Component Views
    @ViewBuilder
    private func canvasView(size: CGSize) -> some View {
        Canvas { context, size in
            // Draw previously saved strokes
            for stroke in strokes {
                let isActive = stroke.id == activeStrokeId
                let strokeWidth = isActive ? 12 * strokeWidthMultiplier : 8 * strokeWidthMultiplier
                let glowWidth = isActive ? 4.0 : 0.0
                
                drawStroke(
                    stroke.points,
                    in: &context,
                    color: stroke.color,
                    strokeWidth: strokeWidth,
                    glowWidth: glowWidth
                )
            }
            
            // Draw current stroke
            if !currentStroke.isEmpty {
                drawStroke(
                    currentStroke,
                    in: &context,
                    color: currentColor,
                    strokeWidth: 8 * strokeWidthMultiplier,
                    glowWidth: 2.0
                )
            }
        }
        .accessibility(label: Text("Drawing canvas with musical sounds"))
        .accessibility(hint: Text("Draw with your finger to create sounds"))
        .accessibilityAction(named: Text("Clear Canvas")) {
            clearCanvas()
        }
    }
    
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
                    canvasScale = 1.0
                    canvasOffset = .zero
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
                    showSettings.toggle()
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
                ForEach(0..<colors.count, id: \.self) { index in
                    ColorButton(
                        color: colors[index],
                        note: colorNames[index],
                        instrument: instrumentNames[index],
                        isSelected: currentColorIndex == index,
                        action: {
                            currentColorIndex = index
                            // Short preview of the sound
                            conductor.playInstrument(colorIndex: index)
                            // Add haptic feedback
                            let impactLight = UIImpactFeedbackGenerator(style: .light)
                            impactLight.impactOccurred()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                conductor.stopSound()
                            }
                        }
                    )
                    .accessibilityLabel("\(colorNames[index]) note")
                    .accessibilityValue("Color: \(colors[index].description)")
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
                    showClearConfirmation = true
                }
                .accessibilityLabel("Clear Canvas")
                
                ActionButton(title: "Replay", systemImage: "play.fill") {
                    replayStrokes()
                }
                .accessibilityLabel("Replay Drawing")
                
                ActionButton(title: "Help", systemImage: "questionmark.circle") {
                    showTutorial = true
                }
                .accessibilityLabel("Show Tutorial")
                
                ActionButton(title: "Export", systemImage: "square.and.arrow.up") {
                    showExportMenu = true
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
        .alert(isPresented: $showClearConfirmation) {
            Alert(
                title: Text("Clear Canvas?"),
                message: Text("This will permanently delete your drawing and musical creation. This action cannot be undone."),
                primaryButton: .destructive(Text("Clear All")) {
                    clearCanvas()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2.bold())
                    .foregroundColor(foregroundStyle)
                
                Spacer()
                
                Button {
                    withAnimation {
                        showSettings = false
                    }
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
                
                Picker("Theme", selection: $appTheme) {
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
                    
                    Slider(value: $strokeWidthMultiplier, in: 0.5...2.0)
                        .accentColor(currentColor)
                    
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .foregroundColor(foregroundStyle.opacity(0.7))
                }
            }
            
            // Sound Information
            VStack(alignment: .leading, spacing: 8) {
                Text("Sound")
                    .font(.headline)
                    .foregroundColor(foregroundStyle)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Instrument Sounds")
                        .font(.subheadline)
                        .foregroundColor(foregroundStyle)
                    
                    Text("Each color is assigned a different instrument. Currently, only the piano sound is available on your device. For full instrument variety, add a soundfont as described in the README.")
                        .font(.caption)
                        .foregroundColor(foregroundStyle.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 12) {
                        ForEach(0..<min(3, instrumentNames.count), id: \.self) { i in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(colors[i])
                                    .frame(width: 12, height: 12)
                                Text(instrumentNames[i])
                                    .font(.caption)
                                    .foregroundColor(foregroundStyle.opacity(0.9))
                            }
                        }
                    }
                    .padding(.top, 2)
                    
                    HStack(spacing: 12) {
                        ForEach(3..<min(7, instrumentNames.count), id: \.self) { i in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(colors[i])
                                    .frame(width: 12, height: 12)
                                Text(instrumentNames[i])
                                    .font(.caption)
                                    .foregroundColor(foregroundStyle.opacity(0.9))
                            }
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.05))
                )
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
    
    private func exportPanel(image: UIImage) -> some View {
        VStack(spacing: 15) {
            // Header
            HStack {
                Text("Export Drawing")
                    .font(.title3.bold())
                    .foregroundColor(foregroundStyle)
                
                Spacer()
                
                Button {
                    withAnimation {
                        showExportMenu = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(foregroundStyle.opacity(0.6))
                }
                .accessibilityLabel("Close export panel")
            }
            
            // Image preview
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .cornerRadius(12)
                .padding(.vertical, 10)
            
            // Export options
            HStack(spacing: 15) {
                Button {
                    let shareActivity = UIActivityViewController(
                        activityItems: [image],
                        applicationActivities: nil
                    )
                    
                    // Find the active UIWindow to present from
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(shareActivity, animated: true)
                    }
                    
                    // Close menu after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showExportMenu = false
                    }
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    
                    // Show confirmation with haptic
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Close menu after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showExportMenu = false
                    }
                } label: {
                    Label("Save to Photos", systemImage: "photo")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 0)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
    
    // MARK: - Helper Methods
    func drawStroke(_ stroke: [CGPoint], in context: inout GraphicsContext, color: Color, strokeWidth: CGFloat, glowWidth: CGFloat = 0) {
        guard !stroke.isEmpty else { return }
        var path = Path()
        path.move(to: stroke[0])
        
        for i in 1..<stroke.count {
            let midPoint = midPoint(stroke[i-1], stroke[i])
            path.addQuadCurve(to: midPoint, control: stroke[i-1])
            if i == stroke.count - 1 {
                path.addLine(to: stroke[i])
            }
        }
        
        // Draw glow if specified
        if glowWidth > 0 {
            context.stroke(
                path,
                with: .color(color.opacity(0.3)),
                style: StrokeStyle(
                    lineWidth: strokeWidth + glowWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
        
        // Draw main stroke
        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(
                lineWidth: strokeWidth,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }
    
    func midPoint(_ p1: CGPoint, _ p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }
    
    func startSoundForColor() {
        conductor.playInstrument(colorIndex: currentColorIndex)
    }
    
    func replayStrokes() {
        guard !strokes.isEmpty else { return }
        
        Task {
            for (index, stroke) in strokes.enumerated() {
                activeStrokeId = stroke.id
                
                if let colorIndex = colors.firstIndex(of: stroke.color) {
                    conductor.playInstrument(colorIndex: colorIndex)
                }
                
                // Add visual feedback for the stroke being replayed
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
                
                // Stop sound after the last stroke
                if index == strokes.count - 1 {
                    conductor.stopSound()
                    activeStrokeId = nil
                }
            }
        }
    }
    
    func clearCanvas() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.5)) {
            strokes.removeAll()
        }
    }
    
    func convertPointForCanvas(_ point: CGPoint, size: CGSize) -> CGPoint {
        // Convert point from screen coordinates to canvas coordinates accounting for zoom and pan
        let adjustedX = (point.x - size.width/2 - canvasOffset.width) / canvasScale + size.width/2
        let adjustedY = (point.y - size.height/2 - canvasOffset.height) / canvasScale + size.height/2
        return CGPoint(x: adjustedX, y: adjustedY)
    }
    
    func renderCanvasToImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Draw background
            let backgroundPath = UIBezierPath(rect: CGRect(origin: .zero, size: size))
            UIColor(backgroundColors[0]).setFill()
            backgroundPath.fill()
            
            // Draw strokes
            for stroke in strokes {
                guard stroke.points.count > 1 else { continue }
                
                let path = UIBezierPath()
                path.move(to: stroke.points[0])
                
                for i in 1..<stroke.points.count {
                    let midPoint = midPoint(stroke.points[i-1], stroke.points[i])
                    path.addQuadCurve(to: midPoint, controlPoint: stroke.points[i-1])
                    if i == stroke.points.count - 1 {
                        path.addLine(to: stroke.points[i])
                    }
                }
                
                path.lineWidth = 8 * strokeWidthMultiplier
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                
                UIColor(stroke.color).setStroke()
                path.stroke()
            }
        }
    }
    
    // Add control panel indicator view
    private func controlPanelIndicator(safeAreaBottom: CGFloat) -> some View {
        Button {
            withAnimation(.spring(response: 0.35)) {
                isControlPanelHidden.toggle()
            }
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            VStack(spacing: 3) {
                // When panel is hidden, show up chevron
//                if isControlPanelHidden {
//                    Text("Show Controls")
//                        .font(.caption2)
//                        .foregroundColor(foregroundStyle.opacity(0.7))
//                        .padding(.vertical, 2)
//                }
                
                Image(systemName: isControlPanelHidden ? "chevron.up" : "chevron.down")
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
                RoundedRectangle(cornerRadius: isControlPanelHidden ? 12 : 12,
                                 style: isControlPanelHidden ? .continuous : .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: isControlPanelHidden ? 1 : 0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: isControlPanelHidden ? 12 : 12,
                                 style: isControlPanelHidden ? .continuous : .continuous)
                    .stroke(foregroundStyle.opacity(0.1), lineWidth: 1)
            )
        }
        .accessibilityLabel(isControlPanelHidden ? "Show controls" : "Hide controls")
        .contentShape(Rectangle())
        .padding(.bottom, isControlPanelHidden ? (safeAreaBottom > 0 ? 10 : 25) : 0)
    }
}

// MARK: - Supporting Views
struct ColorButton: View {
    let color: Color
    let note: String
    let instrument: String
    let isSelected: Bool
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
                
                VStack(spacing: 0) {
                    Text(note)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color.isBright() ? .black : .white)
                    
                    if isSelected {
                        Text(instrument)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(color.isBright() ? .black.opacity(0.7) : .white.opacity(0.7))
                            .padding(.top, 2)
                    }
                }
            }
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct ActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 22))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(width: 70, height: 65)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.6), Color.black.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    var theme: ContentView.AppTheme
    var colorScheme: ColorScheme
    
    var foregroundStyle: Color {
        switch theme {
        case .light: return .black
        case .dark: return .white
        case .colorful: return .white
        case .system: return colorScheme == .dark ? .white : .black
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("How to use Sound Canvas")
                    .font(.title2.bold())
                    .foregroundColor(foregroundStyle)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(foregroundStyle.opacity(0.6))
                }
                .accessibilityLabel("Close tutorial")
            }
            
            VStack(alignment: .leading, spacing: 18) {
                TutorialItem(
                    icon: "hand.draw.fill",
                    title: "Draw to create music",
                    description: "Draw on the canvas to play different instrument sounds based on the selected color.",
                    theme: theme,
                    colorScheme: colorScheme
                )
                
                TutorialItem(
                    icon: "paintpalette.fill",
                    title: "Choose instruments",
                    description: "Each color represents a different musical instrument playing a unique note.",
                    theme: theme,
                    colorScheme: colorScheme
                )
                
                TutorialItem(
                    icon: "play.fill",
                    title: "Replay your drawing",
                    description: "Play back your musical creation with the Replay button.",
                    theme: theme,
                    colorScheme: colorScheme
                )
                
                TutorialItem(
                    icon: "trash",
                    title: "Clear the canvas",
                    description: "Start fresh with the Clear button to create a new composition.",
                    theme: theme,
                    colorScheme: colorScheme
                )
                
                TutorialItem(
                    icon: "hand.tap",
                    title: "Pinch to zoom",
                    description: "Pinch with two fingers to zoom in and out of your drawing.",
                    theme: theme,
                    colorScheme: colorScheme
                )
                
                TutorialItem(
                    icon: "square.and.arrow.up",
                    title: "Export your creation",
                    description: "Save your musical drawing to your photos or share it.",
                    theme: theme,
                    colorScheme: colorScheme
                )

                TutorialItem(
                    icon: "chevron.up.chevron.down",
                    title: "Hide/Show Controls",
                    description: "Tap the indicator at the bottom to hide or show the control panel for more drawing space.",
                    theme: theme,
                    colorScheme: colorScheme
                )
            }
            .padding()
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Got it!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct TutorialItem: View {
    let icon: String
    let title: String
    let description: String
    var theme: ContentView.AppTheme
    var colorScheme: ColorScheme
    
    var foregroundStyle: Color {
        switch theme {
        case .light: return .black
        case .dark: return .white
        case .colorful: return .white
        case .system: return colorScheme == .dark ? .white : .black
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(foregroundStyle)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(foregroundStyle.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// For better touch feedback
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Color utility extension
extension Color {
    func isBright() -> Bool {
        // Simple approximation to determine if a color is bright
        // More sophisticated implementations can be used for better results
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 0]
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
        return brightness > 0.6
    }
}

#Preview {
    ContentView()
}
