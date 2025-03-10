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