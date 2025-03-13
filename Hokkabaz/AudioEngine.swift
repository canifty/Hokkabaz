import SwiftUI
import AudioKit
import AVFoundation
import SoundpipeAudioKit

class Conductor: ObservableObject {
    let engine = AudioEngine()
    let sampler = AppleSampler()
    
    // Add an oscillator as backup sound source
    let oscillator = Oscillator()
    
    // Guitar-specific oscillators for rich guitar-like tone
    let guitarOscillator1 = Oscillator() // Fundamental
    let guitarOscillator2 = Oscillator() // First overtone
    let guitarOscillator3 = Oscillator() // Second overtone/harmonic
    let guitarMixer = Mixer() // Mixer to combine the oscillators
    
    // Additional guitar details
    let stringNoiseTime = 0.005 // Slightly longer attack time for softer pluck
    var lastGuitarFrequency: AUValue = 0.0 // Track last note for string bend effect
    var guitarStrumDirection = true // Alternate strum direction for realism
    
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
    @Published var currentInstrument = 0 // 0 for Piano, 1 for Guitar
    
    // Current sound source type
    @Published var currentSoundSource = SoundSourceType.sampler // Track which sound source we're using
    
    enum SoundSourceType {
        case sampler
        case oscillator
        case guitar
    }
    
    init() {
        print("🔊 Initializing AudioKit engine...")
        
        // Check and configure audio session
        configureAudioSession()
        
        // Configure oscillator as backup
        oscillator.amplitude = 0.5
        oscillator.frequency = noteFrequencies[0]
        
        // Configure guitar oscillators for a more complex guitar-like sound
        guitarOscillator1.amplitude = 0.0 // Start silent
        guitarOscillator1.frequency = noteFrequencies[0]
        
        guitarOscillator2.amplitude = 0.0 // Start silent
        guitarOscillator2.frequency = noteFrequencies[0] * 2 // First overtone (octave higher)
        
        guitarOscillator3.amplitude = 0.0 // Start silent
        guitarOscillator3.frequency = noteFrequencies[0] * 3 // Second overtone (octave + fifth)
        
        // Setup the guitar mixer
        guitarMixer.addInput(guitarOscillator1)
        guitarMixer.addInput(guitarOscillator2)
        guitarMixer.addInput(guitarOscillator3)
        guitarMixer.volume = 1.0
        
        // Try to use sampler first
        engine.output = sampler
        
        do {
            try engine.start()
            print("✅ AudioKit engine started successfully")
            // Load default sounds
            if !loadDefaultSounds() {
                // Try to load specific presets
                let pianoLoaded = loadPianoPreset()
                let guitarLoaded = loadGuitarPreset()
                
                // If both specific presets failed, switch to oscillator
                if !pianoLoaded && !guitarLoaded {
                    switchToOscillator()
                }
            }
        } catch {
            print("❌ AudioKit ERROR: \(error)")
            print("AudioKit did not start: \(error)") // Changed Log to print
            // Try oscillator as fallback
            switchToOscillator()
        }
    }
    
    func switchToOscillator() {
        print("🔄 Switching to oscillator as sound source")
        engine.output = oscillator
        usingSampler = false
        currentSoundSource = .oscillator
        
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
        currentSoundSource = .sampler
        
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
    
    func switchToGuitarOscillator() {
        print("🎸 Switching to guitar oscillator as sound source")
        engine.output = guitarMixer
        usingSampler = false
        currentSoundSource = .guitar
        
        // Make sure engine is running
        if !engine.avEngine.isRunning {
            do {
                try engine.start()
                print("✅ AudioKit engine restarted with guitar oscillator")
            } catch {
                print("❌ Failed to restart engine with guitar oscillator: \(error)")
            }
        }
    }
    
    func loadPianoPreset() -> Bool {
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
            return true
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
                return true
            }
        } catch {
            print("❌ Failed to load built-in Piano sound: \(error)")
        }
        
        print("ℹ️ Piano preset loading failed, falling back to soundfont search")
        // If we couldn't load piano specifically, just try to load any soundfont again
        return loadDefaultSounds()
    }
    
    func loadGuitarPreset() -> Bool {
        // Ensure we're using the sampler
        if !usingSampler {
            switchToSampler()
        }
        
        print("🎸 Attempting to load guitar preset...")
        
        // Method 1: Try loading a dedicated guitar soundfont
        print("Attempting to find guitar soundfont...")
        let possiblePaths = [
            Bundle.main.path(forResource: "Sounds/Guitar", ofType: "sf2"),
            Bundle.main.path(forResource: "Guitar", ofType: "sf2"),
            Bundle.main.path(forResource: "AcousticGuitar", ofType: "sf2")
        ]
        
        print("Checking paths:")
        possiblePaths.forEach { path in
            if let path = path {
                print("  - Found: \(path)")
            } else {
                print("  - Not found")
            }
        }
        
        do {
            if let guitarURL = Bundle.main.url(forResource: "Sounds/Guitar", withExtension: "sf2") ??
                              Bundle.main.url(forResource: "Guitar", withExtension: "sf2") ??
                              Bundle.main.url(forResource: "AcousticGuitar", withExtension: "sf2") {
                print("Attempting to load soundfont from: \(guitarURL.path)")
                try sampler.loadSoundFont(guitarURL.path, preset: 24, bank: 0)
                print("✅ Successfully loaded guitar soundfont")
                return true
            }
        } catch {
            print("❌ Failed to load guitar soundfont: \(error)")
            print("Detailed error: \(error.localizedDescription)")
        }
        
        // Method 2: Try loading from GeneralUser GS
        print("Attempting to load GeneralUser GS soundfont...")
        if let bundledSoundfontURL = Bundle.main.url(forResource: "GeneralUser GS", withExtension: "sf2") {
            print("Found GeneralUser GS at: \(bundledSoundfontURL.path)")
            do {
                try sampler.loadSoundFont(bundledSoundfontURL.path, preset: 24, bank: 0)
                print("✅ Successfully loaded GeneralUser GS with guitar preset")
                return true
            } catch {
                print("❌ Failed to load GeneralUser GS: \(error)")
                print("Detailed error: \(error.localizedDescription)")
            }
        } else {
            print("❌ GeneralUser GS soundfont not found in bundle")
        }
        
        // Method 3: Try default DLS as last resort
        do {
            let dlsURL = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
            print("Attempting to load DLS from: \(dlsURL.path)")
            
            // Check if file exists
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: dlsURL.path) {
                print("✅ DLS file exists")
                try sampler.loadInstrument(at: dlsURL)
                print("✅ Successfully loaded DLS instrument")
                return true
            } else {
                print("❌ DLS file not found at path")
            }
        } catch {
            print("❌ Failed to load Apple DLS instrument for guitar: \(error)")
            print("Detailed error: \(error.localizedDescription)")
        }
        
        print("ℹ️ All guitar preset loading attempts failed")
        return false
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
        let frequency = noteFrequencies[min(colorIndex, noteFrequencies.count - 1)]
        
        // For debugging, print the note name and instrument
        let noteNames = ["C", "D", "E", "F", "G", "A", "B"]
        let noteName = noteNames[min(colorIndex, noteNames.count - 1)]
        let instruments = ["Piano", "Guitar Oscillator", "Oscillator", "Drum", "Guitar"]
        let instrumentName = instruments[min(currentInstrument, instruments.count - 1)]
        
        print("🎵 Playing \(noteName) note on \(instrumentName) (MIDI: \(noteNumber), Freq: \(frequency)Hz)")
        
        // Play the note based on selected instrument
        switch currentInstrument {
        case 0: // Piano
            if currentSoundSource != .sampler {
                switchToSampler()
                loadPianoPreset()
            }
            sampler.play(noteNumber: noteNumber, velocity: 120)
            
        case 1: // Guitar Oscillator
            if currentSoundSource != .guitar {
                switchToGuitarOscillator()
            }
            
            // Create a realistic acoustic guitar-like sound with multiple oscillators
            
            // Calculate very subtle string bend from previous note (if any)
            if lastGuitarFrequency > 0 && lastGuitarFrequency != frequency {
                // Smoother transition between notes
                guitarOscillator1.frequency = lastGuitarFrequency * 0.999
                guitarOscillator2.frequency = lastGuitarFrequency * 2.0 * 0.999
                guitarOscillator3.frequency = lastGuitarFrequency * 3.0 * 0.999
                
                // Schedule the quick slide to target frequency
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                    // Smooth transition to actual note
                    self.guitarOscillator1.frequency = frequency
                    self.guitarOscillator2.frequency = frequency * 2.001 // Less detuning for cleaner sound
                    self.guitarOscillator3.frequency = frequency * 3.0002 // Very slight detuning for warmth
                }
            } else {
                // Set the base frequencies with minimal detuning for cleaner sound
                guitarOscillator1.frequency = frequency // Fundamental
                guitarOscillator2.frequency = frequency * 2.001 // Very slight detuning
                guitarOscillator3.frequency = frequency * 3.0002 // Very slight detuning
            }
            
            // Remember this frequency for next note's bend effect
            lastGuitarFrequency = frequency
            
            // Reset all oscillators to silent
            guitarOscillator1.amplitude = 0.0
            guitarOscillator2.amplitude = 0.0
            guitarOscillator3.amplitude = 0.0
            
            // Start all oscillators
            guitarOscillator1.start()
            guitarOscillator2.start()
            guitarOscillator3.start()
            
            // Soft attack phase - gradual increase in amplitude
            guitarOscillator1.amplitude = 0.2 // Start with moderate fundamental
            guitarOscillator2.amplitude = 0.1 // Light harmonics
            guitarOscillator3.amplitude = 0.05 // Very light upper harmonics
            
            // Phase 1: Main pluck body - smoother rise to full amplitude
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(stringNoiseTime)) {
                self.guitarOscillator1.amplitude = 0.7 // Strong but not harsh fundamental
                self.guitarOscillator2.amplitude = 0.3 // Moderate harmonics
                self.guitarOscillator3.amplitude = 0.15 // Light upper harmonics
            }
            
            // Phase 2: Early sustain - maintain warm tone
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(stringNoiseTime) + 0.1) {
                self.guitarOscillator1.amplitude = 0.6
                self.guitarOscillator2.amplitude = 0.25
                self.guitarOscillator3.amplitude = 0.12
            }
            
            // Phase 3: Mid sustain - gradual decay
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(stringNoiseTime) + 0.3) {
                self.guitarOscillator1.amplitude = 0.5
                self.guitarOscillator2.amplitude = 0.2
                self.guitarOscillator3.amplitude = 0.1
            }
            
            // Phase 4: Late sustain
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(stringNoiseTime) + 0.6) {
                self.guitarOscillator1.amplitude = 0.4
                self.guitarOscillator2.amplitude = 0.15
                self.guitarOscillator3.amplitude = 0.08
            }
            
            // Phase 5: Final decay
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(stringNoiseTime) + 1.0) {
                self.guitarOscillator1.amplitude = 0.3
                self.guitarOscillator2.amplitude = 0.1
                self.guitarOscillator3.amplitude = 0.05
            }
            
            // Phase 6: Very late decay
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(stringNoiseTime) + 1.5) {
                self.guitarOscillator1.amplitude = 0.2
                self.guitarOscillator2.amplitude = 0.07
                self.guitarOscillator3.amplitude = 0.03
            }
            
        case 2: // Oscillator
            if currentSoundSource != .oscillator {
                switchToOscillator()
            }
            oscillator.frequency = frequency
            oscillator.amplitude = 0.5
            oscillator.start()
            
        case 3: // Drum
            if currentSoundSource != .oscillator {
                switchToOscillator()
            }
            
            // Configure oscillator for drum-like sound
            oscillator.frequency = frequency * 0.5 // Lower frequency for drum sound
            oscillator.amplitude = 0.0 // Start silent for attack
            
            // Start the oscillator
            oscillator.start()
            
            // Phase 1: Sharp attack (drum hit)
            oscillator.amplitude = 0.8 // Strong initial hit
            
            // Phase 2: Quick decay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.oscillator.amplitude = 0.4
            }
            
            // Phase 3: Short sustain
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.oscillator.amplitude = 0.2
            }
            
            // Phase 4: Final decay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.oscillator.amplitude = 0.1
            }
            
            // Stop the drum sound
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.oscillator.amplitude = 0.0
                self.oscillator.stop()
            }
            
        case 4: // Guitar (Sampler)
            if currentSoundSource != .sampler {
                switchToSampler()
                loadGuitarPreset()
            }
            // Use a moderate velocity for more natural guitar sound
            let guitarVelocity: MIDIVelocity = 85
            
            // Offset the note two octaves down for more natural guitar range
            let guitarNote = noteNumber - 24
            
            // Add a slight delay between note changes for more natural guitar sound
            if isPlaying {
                sampler.stop(noteNumber: guitarNote)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self.sampler.play(noteNumber: guitarNote, velocity: guitarVelocity)
                }
            } else {
                sampler.play(noteNumber: guitarNote, velocity: guitarVelocity)
            }
            
        default:
            // Fallback to sampler with default sound
            if currentSoundSource != .sampler {
                switchToSampler()
            }
            sampler.play(noteNumber: noteNumber, velocity: 120)
        }
        
        isPlaying = true
    }
    
    // New method to change the current instrument
    func setInstrument(_ instrumentIndex: Int) {
        print("🎹 Changing instrument to: \(instrumentIndex)")
        
        switch instrumentIndex {
        case 0: // Piano
            currentInstrument = 0
            if currentSoundSource != .sampler {
                switchToSampler()
            }
            loadPianoPreset()
        case 1: // Guitar Oscillator
            currentInstrument = 1
            loadGuitarPreset() // This will handle choosing the right sound source
        case 2: // Oscillator
            currentInstrument = 2
            switchToOscillator()
        case 3: // Drum
            currentInstrument = 3
            switchToOscillator()
        case 4: // Guitar (Sampler)
            currentInstrument = 4
            if currentSoundSource != .sampler {
                switchToSampler()
            }
            loadGuitarPreset()
        default:
            // For any other instrument, use default sampler sound
            currentInstrument = 0
            if currentSoundSource != .sampler {
                switchToSampler()
            }
            loadDefaultSounds()
        }
    }
    
    func stopSound() {
        if isPlaying {
            print("🛑 Stopping sound")
            
            if currentSoundSource == .sampler {
                // Stop all notes individually in sampler
                for noteNumber in midiNotes {
                    sampler.stop(noteNumber: noteNumber)
                }
            } else if currentSoundSource == .oscillator {
                // Stop oscillator
                oscillator.stop()
            } else if currentSoundSource == .guitar {
                // Create a realistic guitar release with natural decay
                
                // Soft muting - gradual decrease in amplitude
                guitarOscillator1.amplitude *= 0.7
                guitarOscillator2.amplitude *= 0.6
                guitarOscillator3.amplitude *= 0.5
                
                // Phase 1: Initial fade
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.guitarOscillator1.amplitude *= 0.5
                    self.guitarOscillator2.amplitude *= 0.4
                    self.guitarOscillator3.amplitude *= 0.3
                }
                
                // Phase 2: Final fade
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.guitarOscillator1.amplitude = 0.0
                    self.guitarOscillator2.amplitude = 0.0
                    self.guitarOscillator3.amplitude = 0.0
                    
                    self.guitarOscillator1.stop()
                    self.guitarOscillator2.stop()
                    self.guitarOscillator3.stop()
                }
            }
            
            isPlaying = false
        }
    }
} 
