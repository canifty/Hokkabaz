//
//  File.swift
//  Hokkabaz
//
//  Created by Can Dindar on 31/07/25.
//

import SwiftUI

struct ColorPanel: View {
    @ObservedObject var viewModel: SoundCanvasViewModel

    var body: some View {
        VStack {
            VStack {
                HStack(spacing: 12) {
                    ForEach(0..<viewModel.colors.count, id: \.self) { index in
                        ColorButton(
                            color: viewModel.colors[index],
                            note: viewModel.colorNames[index],
                            instrument: viewModel.instrumentNames[index],
                            isSelected: viewModel.currentColorIndex == index,
                            showNote: viewModel.showNoteLetters,
                            action: {
                                viewModel.currentColorIndex = index
                                viewModel.conductor.playInstrument(colorIndex: index)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    viewModel.conductor.stopSound()
                                }
                            }
                        )
                        .accessibilityLabel(String(describing: viewModel.colorNames[index]) + " note")
                        .accessibilityValue("Color: \(viewModel.colors[index].description)")
                        .accessibilityHint("Tap to select this note and color")
                    }
                }
            }
        }
    }
}
