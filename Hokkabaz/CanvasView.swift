//
//  CanvasView.swift
//  Hokkabaz
//
//  Created by Can Dindar on 11/03/25.
//

import SwiftUI
import PencilKit

struct CanvasView: UIViewRepresentable {
    @ObservedObject var viewModel: SoundCanvasViewModel

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = viewModel.currentPKTool
        viewModel.canvasView = canvasView
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        canvasView.tool = viewModel.currentPKTool
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var viewModel: SoundCanvasViewModel

        init(viewModel: SoundCanvasViewModel) {
            self.viewModel = viewModel
        }

        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            viewModel.startSoundForColor()
        }

        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            viewModel.conductor.stopSound()
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !viewModel.isReplaying else { return }
            viewModel.pkDrawing = canvasView.drawing
        }
    }
}
