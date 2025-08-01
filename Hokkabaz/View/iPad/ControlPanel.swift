//
//  ControlPanel.swift
//  Hokkabaz
//  iPad
//  Created by Can Dindar on 31/07/25.
//

import SwiftUI

struct ControlPanel: View {
    @ObservedObject var viewModel: SoundCanvasViewModel
    
    @Environment(\.colorScheme) var colorScheme
    var foregroundStyle: Color {
        switch viewModel.appTheme {
        case .canvas: return .black
        case .night: return .white
        case .colorful: return .white
        case .system: return colorScheme == .dark ? .white : .black
        }
    }
    
var body: some View {
    
        VStack(spacing: 20) {
            // Color buttons - removed header and ScrollView
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
                                // Short preview of the sound
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
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
            
            
            // Instruments section - removed header, ScrollView, and picker
            VStack(alignment: .leading, spacing: 8) {
                // Main instrument buttons in a row - replaced picker with buttons
                HStack {
                    
                    InstrumentButton(
                        iconName: "piano.png",
                        instrumentName: "Piano",
                        isSelected: viewModel.currentInstrument == "Piano",
                        action: {
                            viewModel.currentInstrument = "Piano"
                            viewModel.conductor.loadPianoPreset()
                        }
                    )
                    .foregroundColor(foregroundStyle)
                    .accessibilityLabel("Switch to Piano")
                    
                    InstrumentButton(
                        iconName: "guitar.png",
                        instrumentName: "Guitar",
                        isSelected: viewModel.currentInstrument == "Guitar",
                        action: {
                            viewModel.currentInstrument = "Guitar"
                            viewModel.conductor.loadGuitarPreset()
                        }
                    )
                    .foregroundColor(foregroundStyle)
                    .accessibilityLabel("Switch to Guitar")
                
                    InstrumentButton(
                        iconName: "saks",
                        instrumentName: "Saxophone",
                        isSelected: viewModel.currentInstrument == "Saxophone",
                        action: {
                            viewModel.currentInstrument = "Saxophone"
                            viewModel.conductor.loadSaxophonePreset()
                        }
                    )
                    .foregroundColor(foregroundStyle)
                    .accessibilityLabel("Switch to Saxophone")
                    
                    InstrumentButton(
                        iconName: "violin.png",
                        instrumentName: "Violin",
                        isSelected: viewModel.currentInstrument == "Violin",
                        action: {
                            viewModel.currentInstrument = "Violin"
                            viewModel.conductor.loadViolinPreset()
                        }
                    )
                    .foregroundColor(foregroundStyle)
                    .accessibilityLabel("Switch to Violin")
                    
                    InstrumentButton(
                        iconName: "flute.png",
                        instrumentName: "Flute",
                        isSelected: viewModel.currentInstrument == "Flute",
                        action: {
                            viewModel.currentInstrument = "Flute"
                            viewModel.conductor.loadFlutePreset()
                        }
                    )
                    .foregroundColor(foregroundStyle)
                    .accessibilityLabel("Switch to Flute")
                    
                    InstrumentButton(
                        iconName: "trumpet.png",
                        instrumentName: "Trumpet",
                        isSelected: viewModel.currentInstrument == "Trumpet",
                        action: {
                            viewModel.currentInstrument = "Trumpet"
                            viewModel.conductor.loadTrumpetPreset()
                        }
                    )
                    .foregroundColor(foregroundStyle)
                    .accessibilityLabel("Switch to Trumpet")
                }
                .padding(.horizontal, 16)
                .padding(.vertical)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 15)
        .padding(.top)
        .frame(width: 680, height: 220, alignment: .bottom)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

struct controlPanelIndicator: View {
    @ObservedObject var viewModel: SoundCanvasViewModel
var safeAreaBottom: CGFloat
    var body: some View {
    Button {
        withAnimation(.spring(response: 0.35)) {
            viewModel.isControlPanelHidden.toggle()
        }
    } label: {
        Capsule()
            .fill(Color.white.opacity(0.4))
            .frame(width: 36, height: 5)
            .padding(10)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: viewModel.isControlPanelHidden ? 1 : 0)
            )
    }
    .accessibilityLabel(viewModel.isControlPanelHidden ? "Show controls" : "Hide controls")
    .contentShape(Rectangle())
    .padding(.bottom, viewModel.isControlPanelHidden ? (safeAreaBottom > 0 ? 10 : 25) : 0)
}
}

