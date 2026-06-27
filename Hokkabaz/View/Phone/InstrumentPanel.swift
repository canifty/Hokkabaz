//
//  InstrumentPanelView.swift
//  Hokkabaz
//  iOS
//  Created by Can Dindar on 31/07/25.
//
import SwiftUI

struct InstrumentPanelView: View {
    
    @Binding var showInstruments: Bool
    @ObservedObject var viewModel: SoundCanvasViewModel
    
    var body: some View {
        VStack {
            if showInstruments {
                VStack {
                    InstrumentButtonWithoutName(iconName: "piano.png", isSelected: viewModel.currentInstrument == "Piano") {
                        viewModel.currentInstrument = "Piano"
                        viewModel.conductor.loadPianoPreset()
                    }
                    InstrumentButtonWithoutName(iconName: "guitar.png", isSelected: viewModel.currentInstrument == "Guitar") {
                        viewModel.currentInstrument = "Guitar"
                        viewModel.conductor.loadGuitarPreset()
                    }
                    InstrumentButtonWithoutName(iconName: "saks", isSelected: viewModel.currentInstrument == "Saxophone") {
                        viewModel.currentInstrument = "Saxophone"
                        viewModel.conductor.loadSaxophonePreset()
                    }
                    InstrumentButtonWithoutName(iconName: "violin.png", isSelected: viewModel.currentInstrument == "Violin") {
                        viewModel.currentInstrument = "Violin"
                        viewModel.conductor.loadViolinPreset()
                    }
                    InstrumentButtonWithoutName(iconName: "flute.png", isSelected: viewModel.currentInstrument == "Flute") {
                        viewModel.currentInstrument = "Flute"
                        viewModel.conductor.loadFlutePreset()
                    }
                    InstrumentButtonWithoutName(iconName: "trumpet.png", isSelected: viewModel.currentInstrument == "Trumpet") {
                        viewModel.currentInstrument = "Trumpet"
                        viewModel.conductor.loadTrumpetPreset()
                    }
                }
                .padding(.vertical, 12)
            }
            
            Button {
                withAnimation(.spring()) {
                    showInstruments.toggle()
                }
            } label: {
                Image(systemName: showInstruments ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
            }
        }
        .buttonStyle(ScalingButtonStyle())
        .padding(.horizontal, 10)
        .background(Capsule().fill(.ultraThinMaterial).shadow(radius: 5))
        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
        .frame(width: 70, height: 350, alignment: .bottomLeading)
    }
}
