//
//  Conducter.swift
//  Hokkabaz
//
//  Created by Can Dindar on 05/03/25.
//

import AudioKit
import AVFoundation
import SoundpipeAudioKit

class Conductor: ObservableObject {
    let engine = AudioEngine()
    let oscillator = Oscillator()
    let sampler = AppleSampler()
    var isOscillatorPlaying = false

    init() {
        engine.output = oscillator
        do {
            try engine.start()
        } catch {
            Log("AudioKit did not start!")
        }
    }

    func playOscillator(frequency: AUValue) {
        oscillator.frequency = frequency
        if !isOscillatorPlaying {
            oscillator.start()
            isOscillatorPlaying = true
        }
    }

    func stopOscillator() {
        if isOscillatorPlaying {
            oscillator.stop()
            isOscillatorPlaying = false
        }
    }

    func loadSample(_ url: URL) {
        do {
            let file = try AVAudioFile(forReading: url)
            try sampler.loadAudioFile(file)
            Log("Sample loaded successfully")
        } catch {
            Log("Could not load sample: \(error.localizedDescription)")
        }
    }

    func playSample() {
        do {
            try sampler.play()
            Log("Playing sample")
        } catch {
            Log("Could not play sample: \(error.localizedDescription)")
        }
    }
}


