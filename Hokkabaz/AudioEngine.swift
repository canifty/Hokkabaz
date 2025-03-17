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
    
    func loadGuitarPreset() {
        // Ensure we're using the sampler
        if !usingSampler {
            switchToSampler()
        }
        
        print("🎸 Attempting to load guitar preset from GeneralUser GS.sf2...")
        
        // Debug all available resources in the bundle
        print("📦 Checking all resources in the bundle:")
        let allTypes = ["sf2", "dls", "wav", "aif"]
        for type in allTypes {
            if let urls = Bundle.main.urls(forResourcesWithExtension: type, subdirectory: nil) {
                print("   - Found \(urls.count) files with extension .\(type):")
                for url in urls {
                    print("      • \(url.lastPathComponent)")
                }
            } else {
                print("   - No files with extension .\(type) found")
            }
        }
        
        // First try direct AVAudioUnitSampler method (based on the Flutter plugin approach)
        if let bundledSoundfontURL = Bundle.main.url(forResource: "GeneralUser GS", withExtension: "sf2") {
            print("✅ Found GeneralUser GS soundfont at path: \(bundledSoundfontURL.path)")
            
            // Try the direct AVAudioUnitSampler approach
            if loadGuitarDirectMethod(soundfontURL: bundledSoundfontURL) {
                print("✅ SUCCESS! Guitar loaded using direct AVAudioUnitSampler method")
                return
            }
            
            // If direct method fails, try multiple presets and banks as fallback
            let guitarPresets = [24, 25, 26, 27, 28] // Various guitar presets
            let banks = [0, 128]
            
            for preset in guitarPresets {
                for bank in banks {
                    do {
                        print("   - Attempting to load guitar with preset: \(preset), bank: \(bank)")
                        try sampler.loadSoundFont(bundledSoundfontURL.path, preset: preset, bank: bank)
                        print("✅ SUCCESS! Guitar sound loaded from GeneralUser GS with preset: \(preset), bank: \(bank)")
                        return
                    } catch {
                        print("   - Failed with preset: \(preset), bank: \(bank), error: \(error)")
                    }
                }
            }
            
            print("❌ Tried all guitar presets but couldn't load from GeneralUser GS soundfont")
        } else {
            print("❌ GeneralUser GS.sf2 file not found in the bundle!")
            print("Please add the GeneralUser GS.sf2 file to your project as described in the README:")
            print("1. Download from: https://schristiancollins.com/generaluser.php")
            print("2. Add to your Xcode project with filename 'GeneralUser GS.sf2'")
            print("3. Ensure it's included in Copy Bundle Resources build phase")
        }
        
        // Try looking for any SF2 file as a last resort
        if let anyFiles = Bundle.main.urls(forResourcesWithExtension: "sf2", subdirectory: nil), !anyFiles.isEmpty {
            let firstFile = anyFiles[0]
            print("🔍 Trying to load from found soundfont: \(firstFile.lastPathComponent)")
            
            // Try direct method first with any soundfont
            if loadGuitarDirectMethod(soundfontURL: firstFile) {
                print("✅ SUCCESS! Guitar loaded from alternative soundfont using direct method")
                return
            }
            
            // Fall back to AudioKit method
            do {
                try sampler.loadSoundFont(firstFile.path, preset: 24, bank: 0)
                print("✅ Loaded guitar sound from alternative soundfont")
                return
            } catch {
                print("❌ Failed to load from alternative soundfont: \(error)")
            }
        }
        
        print("⚠️ Could not load guitar sound from any soundfont")
        print("⚠️ Falling back to piano sound")
        // If all attempts fail, fall back to piano
        loadPianoPreset()
    }
    
    // Helper method to load guitar using direct AVAudioUnitSampler approach
    func loadGuitarDirectMethod(soundfontURL: URL) -> Bool {
        print("🎸 Trying direct AVAudioUnitSampler method with: \(soundfontURL.lastPathComponent)")
        
        // Get direct access to the AVAudioUnitSampler inside AudioKit's AppleSampler
        guard let avAudioUnit = sampler.avAudioNode as? AVAudioUnitSampler else {
            print("❌ Could not access AVAudioUnitSampler from AudioKit")
            return false
        }
        
        do {
            // Using constants similar to those in the Flutter plugin
            let program: UInt8 = 24  // Acoustic Guitar
            let bankMSB: UInt8 = 0x79 // kAUSampler_DefaultMelodicBankMSB
            let bankLSB: UInt8 = 0x00 // kAUSampler_DefaultBankLSB
            
            print("   - Using program: \(program), bankMSB: \(bankMSB), bankLSB: \(bankLSB)")
            try avAudioUnit.loadSoundBankInstrument(
                at: soundfontURL,
                program: program,
                bankMSB: bankMSB,
                bankLSB: bankLSB
            )
            print("✅ Successfully loaded guitar sound using direct AVAudioUnitSampler method")
            return true
        } catch {
            print("❌ Direct AVAudioUnitSampler method failed: \(error)")
            
            // Try alternative bank values
            do {
                print("   - Trying alternative bank values")
                try avAudioUnit.loadSoundBankInstrument(
                    at: soundfontURL,
                    program: 24,
                    bankMSB: 0,
                    bankLSB: 0
                )
                print("✅ Successfully loaded with alternative bank values")
                return true
            } catch {
                print("❌ Alternative bank values also failed: \(error)")
                return false
            }
        }
    }
    
    func loadSaxophonePreset() {
        // Ensure we're using the sampler
        if !usingSampler {
            switchToSampler()
        }
        
        print("🎷 Attempting to load saxophone preset from GeneralUser GS.sf2...")
        
        // Try to load from GeneralUser GS soundfont
        if let bundledSoundfontURL = Bundle.main.url(forResource: "GeneralUser GS", withExtension: "sf2") {
            print("✅ Found GeneralUser GS soundfont at path: \(bundledSoundfontURL.path)")
            
            // Try direct method first
            if loadInstrumentDirectMethod(soundfontURL: bundledSoundfontURL, program: 65, instrumentEmoji: "🎷", instrumentName: "saxophone") {
                return
            }
            
            // If direct method fails, try AudioKit method
            do {
                try sampler.loadSoundFont(bundledSoundfontURL.path, preset: 65, bank: 0) // 65 = Alto Sax
                print("✅ Saxophone sound loaded from GeneralUser GS soundfont!")
                return
            } catch {
                print("❌ Failed to load saxophone from GeneralUser GS soundfont: \(error)")
            }
        } else {
            print("❌ GeneralUser GS.sf2 file not found in the bundle!")
        }
        
        print("⚠️ Could not load saxophone sound")
        print("⚠️ Falling back to piano sound")
        loadPianoPreset()
    }
    
    func loadViolinPreset() {
        // Ensure we're using the sampler
        if !usingSampler {
            switchToSampler()
        }
        
        print("🎻 Attempting to load violin preset from GeneralUser GS.sf2...")
        
        // Try to load from GeneralUser GS soundfont
        if let bundledSoundfontURL = Bundle.main.url(forResource: "GeneralUser GS", withExtension: "sf2") {
            print("✅ Found GeneralUser GS soundfont at path: \(bundledSoundfontURL.path)")
            
            // Try direct method first
            if loadInstrumentDirectMethod(soundfontURL: bundledSoundfontURL, program: 40, instrumentEmoji: "🎻", instrumentName: "violin") {
                return
            }
            
            // If direct method fails, try AudioKit method
            do {
                try sampler.loadSoundFont(bundledSoundfontURL.path, preset: 40, bank: 0) // 40 = Violin
                print("✅ Violin sound loaded from GeneralUser GS soundfont!")
                return
            } catch {
                print("❌ Failed to load violin from GeneralUser GS soundfont: \(error)")
            }
        } else {
            print("❌ GeneralUser GS.sf2 file not found in the bundle!")
        }
        
        print("⚠️ Could not load violin sound")
        print("⚠️ Falling back to piano sound")
        loadPianoPreset()
    }
    
    func loadFlutePreset() {
        // Ensure we're using the sampler
        if !usingSampler {
            switchToSampler()
        }
        
        print("🎵 Attempting to load flute preset from GeneralUser GS.sf2...")
        
        // Try to load from GeneralUser GS soundfont
        if let bundledSoundfontURL = Bundle.main.url(forResource: "GeneralUser GS", withExtension: "sf2") {
            print("✅ Found GeneralUser GS soundfont at path: \(bundledSoundfontURL.path)")
            
            // Try direct method first
            if loadInstrumentDirectMethod(soundfontURL: bundledSoundfontURL, program: 73, instrumentEmoji: "🎵", instrumentName: "flute") {
                return
            }
            
            // If direct method fails, try AudioKit method
            do {
                try sampler.loadSoundFont(bundledSoundfontURL.path, preset: 73, bank: 0) // 73 = Flute
                print("✅ Flute sound loaded from GeneralUser GS soundfont!")
                return
            } catch {
                print("❌ Failed to load flute from GeneralUser GS soundfont: \(error)")
            }
        } else {
            print("❌ GeneralUser GS.sf2 file not found in the bundle!")
        }
        
        print("⚠️ Could not load flute sound")
        print("⚠️ Falling back to piano sound")
        loadPianoPreset()
    }
    
    func loadTrumpetPreset() {
        // Ensure we're using the sampler
        if !usingSampler {
            switchToSampler()
        }
        
        print("🎺 Attempting to load trumpet preset from GeneralUser GS.sf2...")
        
        // Try to load from GeneralUser GS soundfont
        if let bundledSoundfontURL = Bundle.main.url(forResource: "GeneralUser GS", withExtension: "sf2") {
            print("✅ Found GeneralUser GS soundfont at path: \(bundledSoundfontURL.path)")
            
            // Try direct method first
            if loadInstrumentDirectMethod(soundfontURL: bundledSoundfontURL, program: 56, instrumentEmoji: "🎺", instrumentName: "trumpet") {
                return
            }
            
            // If direct method fails, try AudioKit method
            do {
                try sampler.loadSoundFont(bundledSoundfontURL.path, preset: 56, bank: 0) // 56 = Trumpet
                print("✅ Trumpet sound loaded from GeneralUser GS soundfont!")
                return
            } catch {
                print("❌ Failed to load trumpet from GeneralUser GS soundfont: \(error)")
            }
        } else {
            print("❌ GeneralUser GS.sf2 file not found in the bundle!")
        }
        
        print("⚠️ Could not load trumpet sound")
        print("⚠️ Falling back to piano sound")
        loadPianoPreset()
    }
    
    // Generic method to load any instrument using direct AVAudioUnitSampler approach
    func loadInstrumentDirectMethod(soundfontURL: URL, program: UInt8, instrumentEmoji: String, instrumentName: String) -> Bool {
        print("\(instrumentEmoji) Trying direct AVAudioUnitSampler method for \(instrumentName) with: \(soundfontURL.lastPathComponent)")
        
        // Get direct access to the AVAudioUnitSampler inside AudioKit's AppleSampler
        guard let avAudioUnit = sampler.avAudioNode as? AVAudioUnitSampler else {
            print("❌ Could not access AVAudioUnitSampler from AudioKit")
            return false
        }
        
        do {
            // Using constants similar to those in the Flutter plugin
            let bankMSB: UInt8 = 0x79 // kAUSampler_DefaultMelodicBankMSB
            let bankLSB: UInt8 = 0x00 // kAUSampler_DefaultBankLSB
            
            print("   - Using program: \(program), bankMSB: \(bankMSB), bankLSB: \(bankLSB)")
            try avAudioUnit.loadSoundBankInstrument(
                at: soundfontURL,
                program: program,
                bankMSB: bankMSB,
                bankLSB: bankLSB
            )
            print("✅ Successfully loaded \(instrumentName) sound using direct AVAudioUnitSampler method")
            return true
        } catch {
            print("❌ Direct AVAudioUnitSampler method failed: \(error)")
            
            // Try alternative bank values
            do {
                print("   - Trying alternative bank values")
                try avAudioUnit.loadSoundBankInstrument(
                    at: soundfontURL,
                    program: program,
                    bankMSB: 0,
                    bankLSB: 0
                )
                print("✅ Successfully loaded \(instrumentName) with alternative bank values")
                return true
            } catch {
                print("❌ Alternative bank values also failed: \(error)")
                return false
            }
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
        
        // If a sound is already playing, create a smooth transition
        if isPlaying {
            if usingSampler {
                // For sampler, we can simply stop the previous note and start the new one
                // The sampler instruments have natural attack/decay characteristics
                stopSound()
                startSound(colorIndex: colorIndex)
            } else {
                // For oscillator, create a smooth transition with amplitude ramping
                smoothOscillatorTransition(to: colorIndex)
            }
        } else {
            // No previous sound playing, just start the new sound
            startSound(colorIndex: colorIndex)
        }
    }
    
    // Create a smooth transition between oscillator notes
    private func smoothOscillatorTransition(to colorIndex: Int) {
        // Only proceed if we're using oscillator
        guard !usingSampler else {
            startSound(colorIndex: colorIndex)
            return
        }
        
        let frequency = noteFrequencies[min(colorIndex, noteFrequencies.count - 1)]
        
        // First slightly reduce amplitude of current note (quick fade out)
        oscillator.amplitude = 0.5 // Start from normal amplitude
        
        // Create a smooth amplitude ramp down
        oscillator.$amplitude.ramp(to: 0.2, duration: 0.05) // Quick fade to 20% volume
        
        // After a tiny delay, change frequency and ramp amplitude back up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // Change the frequency (pitch) to the new note
            self.oscillator.frequency = frequency
            
            // Ramp the amplitude back up for a smooth transition
            self.oscillator.$amplitude.ramp(to: 0.5, duration: 0.1)
        }
        
        // We're still playing
        isPlaying = true
    }
    
    // Helper function to actually start the sound
    private func startSound(colorIndex: Int) {
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
            
            // Start with a slight ramp-up for smoother attack
            oscillator.amplitude = 0.1
            oscillator.start()
            oscillator.$amplitude.ramp(to: 0.5, duration: 0.05) // Quick fade in over 50ms
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
                // For oscillator, fade out for smoother release
                oscillator.$amplitude.ramp(to: 0.0, duration: 0.1)
                
                // Then fully stop after the fade
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.oscillator.stop()
                }
            }
            isPlaying = false
        }
    }
    
    // Helper to load the appropriate instrument based on instrument name
    func loadInstrumentByName(_ instrumentName: String) {
        switch instrumentName {
        case "Oscillator":
            switchToOscillator()
        case "Piano":
            loadPianoPreset()
        case "Guitar":
            loadGuitarPreset()
        case "Saxophone":
            loadSaxophonePreset()
        case "Violin":
            loadViolinPreset()
        case "Flute":
            loadFlutePreset()
        case "Trumpet":
            loadTrumpetPreset()
        default:
            // Default to piano if unknown instrument name
            loadPianoPreset()
        }
    }
} 
