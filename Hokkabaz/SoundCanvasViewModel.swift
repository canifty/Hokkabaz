//
//  SoundCanvasViewModel.swift
//  Hokkabaz
//
//  Created by Can Dindar on 11/03/25.
//

import SwiftUI
import Combine
import PencilKit

class SoundCanvasViewModel: ObservableObject {
    // Audio engine
    @Published var conductor = Conductor()

    // Drawing data
    @Published var pkDrawing: PKDrawing = PKDrawing()
    @Published var activeReplayStroke: PKStroke? = nil
    weak var canvasView: PKCanvasView?

    // UI State
    @Published var currentColorIndex = 2
    @Published var currentInstrument = "Piano"
    @Published var showTutorial = false
    @Published var showSettings = false
    @Published var showExportMenu = false
    @Published var exportImage: UIImage? = nil
    @Published var showClearConfirmation = false
    @Published var isControlPanelHidden = false
    @Published var showNoteLetters = false

    // Canvas view state
    @Published var canvasScale: CGFloat = 1.0
    @Published var canvasOffset = CGSize.zero

    // Theme
    @Published var appTheme: AppTheme = .canvas

    @Published var currentBrushType: BrushType = .pencil
    @Published var currentBrushWidth: CGFloat = 25.0
    @Published var currentBrushOpacity: Double = 1.0
    @Published var showBrushSettings = false

    var currentBrushProperties: BrushProperties {
        BrushProperties(
            type: currentBrushType,
            width: currentBrushWidth,
            opacity: currentBrushOpacity,
            pressure: 1.0,
            tilt: 0.0,
            spacing: 1.0
        )
    }

    var currentPKTool: PKInkingTool {
        let uiColor = UIColor(colors[currentColorIndex]).withAlphaComponent(currentBrushOpacity)
        return PKInkingTool(currentBrushType.pkInkType, color: uiColor, width: currentBrushWidth)
    }

    // Colors and notes
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, Color(red: 255/255, green: 105/255, blue: 180/255)]
    let colorNames: [LocalizedStringKey] = ["C", "D", "E", "F", "G", "A", "B"]
    let instrumentNames: [String] = ["Piano", "Guitar", "Flute", "Violin", "Trumpet", "Harp", "Cello"]

    // Track instrument changes
    var instrumentCancellable: AnyCancellable?

    // Replay
    private var replayTimer: Timer?
    @Published var isReplaying: Bool = false
    @Published var isPaused: Bool = false
    @Published var showPlaybackControls: Bool = false

    init() {
        conductor.loadPianoPreset()

        instrumentCancellable = $currentInstrument
            .dropFirst()
            .sink { [weak self] instrumentName in
                self?.conductor.loadInstrumentByName(instrumentName)
            }
    }

    // MARK: - Computed Properties

    var currentColor: Color {
        colors[currentColorIndex]
    }

    var backgroundColors: [Color] {
        switch appTheme {
        case .canvas:
            return [Color(white: 0.9), Color(white: 0.95)]
        case .night:
            return [Color.black.opacity(0.8), Color(red: 0.1, green: 0.1, blue: 0.3)]
        case .colorful:
            return [Color.purple.opacity(0.7), Color.blue.opacity(0.5)]
        case .system:
            return [Color(UIColor.systemBackground), Color(UIColor.secondarySystemBackground)]
        }
    }

    var colorNotes: [ColorNote] {
        zip(zip(zip(zip(colors, colorNames), instrumentNames), conductor.midiNotes), conductor.noteFrequencies).map {
            ColorNote(
                color: $0.0.0.0.0,
                noteName: $0.0.0.0.1,
                instrument: $0.0.0.1,
                midiNote: Int($0.0.1),
                frequency: Double($0.1)
            )
        }
    }

    // MARK: - Audio

    func startSoundForColor() {
        conductor.playInstrument(colorIndex: currentColorIndex)
    }

    // MARK: - Brush

    func setBrushType(_ type: BrushType) {
        currentBrushType = type

        switch type {
        case .pencil:
            currentBrushWidth = 25.0
            currentBrushOpacity = 1.0
        case .marker:
            currentBrushWidth = 25.0
            currentBrushOpacity = 1.0
        case .brush:
            currentBrushWidth = 25.0
            currentBrushOpacity = 1.0
        case .charcoal:
            currentBrushWidth = 10.0
            currentBrushOpacity = 1.0
        case .watercolor:
            currentBrushWidth = 25.0
            currentBrushOpacity = 1.0
        }
    }

    // MARK: - Canvas Operations

    func clearCanvas() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        canvasView?.drawing = PKDrawing()
    }

    func undoLastStroke() {
        var strokes = pkDrawing.strokes
        guard !strokes.isEmpty else { return }
        strokes.removeLast()
        canvasView?.drawing = PKDrawing(strokes: strokes)
    }

    func resetCanvasView() {
        canvasScale = 1.0
        canvasOffset = .zero
    }

    // MARK: - Replay

    func replayStrokes() {
        let allStrokes = pkDrawing.strokes
        guard !allStrokes.isEmpty else { return }

        stopReplay()

        showPlaybackControls = true
        isPaused = false
        isReplaying = true

        var currentIndex = 0

        replayTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }

            if currentIndex < allStrokes.count {
                let stroke = allStrokes[currentIndex]
                self.activeReplayStroke = stroke

                let colorIndex = self.colorIndexForUIColor(stroke.ink.color)
                self.conductor.playInstrument(colorIndex: colorIndex)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.conductor.stopSound()
                    self.activeReplayStroke = nil
                }

                currentIndex += 1
            } else {
                self.activeReplayStroke = nil
                self.isReplaying = false
                self.isPaused = false
                self.showPlaybackControls = false
                timer.invalidate()
                self.replayTimer = nil
            }
        }
    }

    func stopReplay() {
        replayTimer?.invalidate()
        replayTimer = nil
        conductor.stopSound()
        activeReplayStroke = nil
        isReplaying = false
        isPaused = false
        showPlaybackControls = false
    }

    // MARK: - Export

    func renderCanvasToImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            if appTheme == .canvas {
                if let paperImage = UIImage(named: "canvas") {
                    paperImage.draw(in: CGRect(origin: .zero, size: size))
                } else {
                    UIColor(backgroundColors[0]).setFill()
                    UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
                }
            } else {
                UIColor(backgroundColors[0]).setFill()
                UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
            }

            let drawingImage = pkDrawing.image(from: CGRect(origin: .zero, size: size), scale: UIScreen.main.scale)
            drawingImage.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Helpers

    private func colorIndexForUIColor(_ uiColor: UIColor) -> Int {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        uiColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)

        var bestIndex = 0
        var bestDistance = CGFloat.infinity

        for (i, color) in colors.enumerated() {
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            UIColor(color).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            let distance = abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = i
            }
        }

        return bestIndex
    }
}
