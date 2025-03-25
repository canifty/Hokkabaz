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
        
        loadPianoPresetFromBundle()
    }

    func loadPianoPresetFromBundle() {
        if let dlsURL = Bundle.main.url(forResource: "gs_instruments", withExtension: "dls") {
            do {
                // Try loading the piano preset from the app bundle
                try sampler.loadInstrument(at: dlsURL)
                print("✅ Loaded piano preset from bundle.")
            } catch {
                print("❌ Failed to load piano preset from bundle: \(error)")
            }
        }
    }
    
    func loadGuitarPreset() {
        // Ensure we're using the sampler
        if !usingSampler {
            switchToSampler()
        }
                
        // Try to load from GeneralUser GS soundfont
        if let bundledSoundfontURL = Bundle.main.url(forResource: "GeneralUser GS", withExtension: "sf2") {
            
            // Try direct method first
            if loadInstrumentDirectMethod(soundfontURL: bundledSoundfontURL, program: 24, instrumentEmoji: "🎸", instrumentName: "guitar") {
                return
            }
        }
        loadPianoPreset()
    }
    
    func loadSaxophonePreset() {
        // Ensure we're using the sampler
        if !usingSampler {
            switchToSampler()
        }
                
        // Try to load from GeneralUser GS soundfont
        if let bundledSoundfontURL = Bundle.main.url(forResource: "GeneralUser GS", withExtension: "sf2") {
            
            // Try direct method first
            if loadInstrumentDirectMethod(soundfontURL: bundledSoundfontURL, program: 65, instrumentEmoji: "🎷", instrumentName: "saxophone") {
                return
            }
        }
        loadPianoPreset()
    }

    func loadViolinPreset() {
        // Ensure we're using the sampler
        if !usingSampler {
            switchToSampler()
        }
                
        // Try to load from GeneralUser GS soundfont
        if let bundledSoundfontURL = Bundle.main.url(forResource: "GeneralUser GS", withExtension: "sf2") {
            
            // Try direct method first
            if loadInstrumentDirectMethod(soundfontURL: bundledSoundfontURL, program: 40, instrumentEmoji: "🎻", instrumentName: "violin") {
                return
            }
        }
        loadPianoPreset()
    }
    

    func loadFlutePreset() {
        // Ensure we're using the sampler
        if !usingSampler {
            switchToSampler()
        }
                
        // Try to load from GeneralUser GS soundfont
        if let bundledSoundfontURL = Bundle.main.url(forResource: "GeneralUser GS", withExtension: "sf2") {
            
            // Try direct method first
            if loadInstrumentDirectMethod(soundfontURL: bundledSoundfontURL, program: 73, instrumentEmoji: "🎵", instrumentName: "flute") {
                return
            }
        }
        loadPianoPreset()
    }
    
    func loadTrumpetPreset() {
        // Ensure we're using the sampler
        if !usingSampler {
            switchToSampler()
        }
                
        // Try to load from GeneralUser GS soundfont
        if let bundledSoundfontURL = Bundle.main.url(forResource: "GeneralUser GS", withExtension: "sf2") {
            
            // Try direct method first
            if loadInstrumentDirectMethod(soundfontURL: bundledSoundfontURL, program: 56, instrumentEmoji: "🎺", instrumentName: "trumpet") {
                return
            }
        }
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
            return false
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
    

    
    func playInstrument(colorIndex: Int) {
        let noteNumber = midiNotes[min(colorIndex, midiNotes.count - 1)]
        
        // If a sound is already playing, create a smooth transition
        if isPlaying {
            if usingSampler {
                // For sampler, we can simply stop the previous note and start the new one
                // The sampler instruments have natural attack/decay characteristics
                stopSound()
                startSound(colorIndex: colorIndex)
            }
        } else {
            // No previous sound playing, just start the new sound
            startSound(colorIndex: colorIndex)
        }
    }
    
    // Helper function to actually start the sound
    private func startSound(colorIndex: Int) {
        let noteNumber = midiNotes[min(colorIndex, midiNotes.count - 1)]
        
        // Play the note - using sampler or oscillator
        print("🎵 Playing note: \(noteNumber) for color index: \(colorIndex)")
        
        if usingSampler {
            // Using sampler (Apple Sampler)
            sampler.play(noteNumber: noteNumber, velocity: 120)
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
            }
            
            isPlaying = false
        }
    }
    
    // Helper to load the appropriate instrument based on instrument name
    func loadInstrumentByName(_ instrumentName: String) {
        switch instrumentName {
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
