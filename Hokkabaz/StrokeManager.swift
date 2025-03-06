//
//  StrokeManager.swift
//  Hokkabaz
//
//  Created by Can Dindar on 05/03/25.
//

import SwiftUI
import AudioKit

class StrokeManager: ObservableObject {
    @Published var strokes: [[CGPoint]] = []
    @Published var currentStroke: [CGPoint] = []
    @Published var isPlaying = false

    var playTask: Task<Void, Never>?  // Store playback task to cancel it
    var playbackStrokeIndex: Int = 0
    var playbackPointIndex: Int = 0

    func addPoint(_ point: CGPoint) {
        currentStroke.append(point)
    }

    func finalizeStroke() {
        if !currentStroke.isEmpty {
            strokes.append(currentStroke)
            currentStroke.removeAll()
        }
    }

    func undoLastStroke() {
        if !strokes.isEmpty {
            strokes.removeLast()
        }
    }

    func clearStrokes() {
        strokes.removeAll()
    }

    func startPlayingDrawing(conductor: Conductor) {
        stopPlayingDrawing()
        isPlaying = true

        playTask = Task {
            for i in playbackStrokeIndex..<strokes.count {
                for j in playbackPointIndex..<strokes[i].count {
                    try? await Task.sleep(nanoseconds: UInt64(0.05 * 1_000_000_000))
                    if Task.isCancelled {
                        playbackStrokeIndex = i
                        playbackPointIndex = j
                        return
                    }
                    conductor.playOscillator(frequency: AUValue(map(strokes[i][j].y, from: 0, to: UIScreen.main.bounds.height, toLow: 200, toHigh: 800)))
                }
                playbackPointIndex = 0
            }
            isPlaying = false
            playbackStrokeIndex = 0
            playbackPointIndex = 0
        }
    }

    func stopPlayingDrawing() {
        playTask?.cancel()
        isPlaying = false
    }

    func map(_ value: CGFloat, from: CGFloat, to: CGFloat, toLow: CGFloat, toHigh: CGFloat) -> CGFloat {
        return (value - from) / (to - from) * (toHigh - toLow) + toLow
    }
}

