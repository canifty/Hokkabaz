import SwiftUI
import AudioKit
import AVFoundation
import SoundpipeAudioKit

class Conductor: ObservableObject {
    let engine = AudioEngine()
    let oscillator = Oscillator()
    let sampler = AppleSampler()
    var isOscillatorPlaying = false
    var isPlayingDrawing = false  // Prevent multiple playbacks at the same time

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

struct ContentView: View {
    @StateObject private var conductor = Conductor()
    @State private var strokes: [[CGPoint]] = []
    @State private var currentStroke: [CGPoint] = []

    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    let frequencies: [AUValue] = [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88]

    @State private var currentColor: Color = .red
    @State private var currentFrequency: AUValue = 261.63
    @State private var isPlaying = false
    @State private var playTask: Task<Void, Never>?  // Store playback task to cancel it
    @State private var playbackStrokeIndex: Int = 0
    @State private var playbackPointIndex: Int = 0
    
    var body: some View {
        VStack {
            Canvas { context, size in
                for stroke in strokes {
                    drawStroke(stroke, in: &context)
                }
                drawStroke(currentStroke, in: &context)
            }
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let newPoint = value.location
                    currentStroke.append(newPoint)
                    updateSound(with: newPoint)
                }
                .onEnded { _ in
                    if !currentStroke.isEmpty {
                        strokes.append(currentStroke)
                        currentStroke.removeAll()
                        conductor.stopOscillator()
                    }
                })

            HStack {
                ForEach(0..<colors.count, id: \.self) { index in
                    Button(action: {
                        currentColor = colors[index]
                        currentFrequency = frequencies[index]
                        if currentColor == .red {
                            if let url = Bundle.main.url(forResource: "Sad-Violin-Fast-E", withExtension: "wav") {
                                conductor.loadSample(url)
                            }
                        }
                    }) {
                        Circle()
                            .fill(colors[index])
                            .frame(width: 40, height: 40)
                    }
                }
            }

            HStack {
                Button("Play Drawing") {
                    if !isPlaying {
                        startPlayingDrawing()
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button(isPlaying ? "Pause" : "Resume") {
                    if isPlaying {
                        stopPlayingDrawing()
                    } else {
                        startPlayingDrawing()
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Undo") {
                    if !strokes.isEmpty {
                        strokes.removeLast()
                        stopPlayingDrawing() // Stop if needed
                    }
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Delete All") {
                    strokes.removeAll()
                    stopPlayingDrawing() // Ensure everything is stopped
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .onAppear {
            if let url = Bundle.main.url(forResource: "Sad-Violin-Fast-E", withExtension: "wav") {
                conductor.loadSample(url)
            }
        }
        .onDisappear {
            stopPlayingDrawing()
            conductor.stopOscillator()
            do {
                try conductor.engine.stop()
            } catch {
                Log("AudioKit did not stop!")
            }
        }
    }

    func drawStroke(_ stroke: [CGPoint], in context: inout GraphicsContext) {
        guard !stroke.isEmpty else { return }

        var path = Path()
        for (index, point) in stroke.enumerated() {
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        context.stroke(path, with: .color(currentColor), lineWidth: 5)
    }

    func updateSound(with point: CGPoint) {
        let frequency = map(point.y, from: 0, to: UIScreen.main.bounds.height, toLow: 200, toHigh: 800)

        // Play the assigned frequency for the selected color
        conductor.playOscillator(frequency: currentColor == .red ? 523.25 : AUValue(frequency)) // Red plays C5 (523.25 Hz)
        
        isPlaying = true
    }

    func startPlayingDrawing() {
        stopPlayingDrawing() // Cancel any previous playback first

        isPlaying = true
        playTask = Task {
            for i in playbackStrokeIndex..<strokes.count {
                for j in playbackPointIndex..<strokes[i].count {
                    try? await Task.sleep(nanoseconds: UInt64(0.05 * 1_000_000_000))
                    if Task.isCancelled {
                        playbackStrokeIndex = i
                        playbackPointIndex = j
                        return  // Stop and save progress
                    }
                    updateSound(with: strokes[i][j])
                }
                playbackPointIndex = 0 // Reset point index after finishing a stroke
            }
            isPlaying = false // Reset after playing
            playbackStrokeIndex = 0
            playbackPointIndex = 0
        }
    }

    func stopPlayingDrawing() {
        playTask?.cancel() // Cancel ongoing playback
        isPlaying = false
        conductor.stopOscillator()
    }

    func map(_ value: CGFloat, from: CGFloat, to: CGFloat, toLow: CGFloat, toHigh: CGFloat) -> CGFloat {
        return (value - from) / (to - from) * (toHigh - toLow) + toLow
    }
}

#Preview {
    ContentView()
}
