//
//  PhoneView.swift
//  Hokkabaz
//
//  Created by Can Dindar on 28/02/25.
//

import SwiftUI
import StoreKit

struct PhoneView: View {
    // MARK: Properties
    @Environment(\.requestReview) var requestReview
    @AppStorage("playButtonTapCount") private var playButtonTapCount = 0
    
    @StateObject private var viewModel = SoundCanvasViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showInstruments = false // New state for showing/hiding instruments
    @State private var scalePercentage: String = ""
    
    var foregroundStyle: Color {
        switch viewModel.appTheme {
        case .canvas: return .black
        case .night: return .white
        case .colorful: return .white
        case .system: return colorScheme == .dark ? .white : .black
        }
    }
    
    // MARK: Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                if viewModel.appTheme == .canvas {
                    Image("canvas")
                        .resizable()
                        .ignoresSafeArea()
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: viewModel.backgroundColors),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
                
                // Canvas
                CanvasView(viewModel: viewModel)

                // Glow overlay for replay highlight
                Canvas { context, _ in
                    guard let stroke = viewModel.activeReplayStroke else { return }
                    let count = stroke.path.count
                    guard count > 1 else { return }

                    let color = Color(stroke.ink.color)
                    let avgWidth = (0..<count).reduce(0.0) { $0 + stroke.path[$1].size.width } / CGFloat(count)

                    var path = Path()
                    path.move(to: stroke.path[0].location)
                    for i in 1..<count {
                        let mid = CGPoint(
                            x: (stroke.path[i-1].location.x + stroke.path[i].location.x) / 2,
                            y: (stroke.path[i-1].location.y + stroke.path[i].location.y) / 2
                        )
                        path.addQuadCurve(to: mid, control: stroke.path[i-1].location)
                        if i == count - 1 { path.addLine(to: stroke.path[i].location) }
                    }

                    context.stroke(path, with: .color(color.opacity(0.25)),
                        style: StrokeStyle(lineWidth: avgWidth * 2.5, lineCap: .round, lineJoin: .round))
                    context.stroke(path, with: .color(color.opacity(0.6)),
                        style: StrokeStyle(lineWidth: avgWidth * 1.3, lineCap: .round, lineJoin: .round))
                }
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.15), value: viewModel.activeReplayStroke != nil)
 
                // 1. Top right: headerView
                VStack {
                    HStack {
                        Spacer()
                        Spacer()
                        Spacer()

                        if !scalePercentage.isEmpty {
                            Text("Zoom: \(scalePercentage)%")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.1))
                                .cornerRadius(20)
                                .transition(.opacity)
                        }
                        Spacer()
                        HeaderView(viewModel: viewModel, foregroundStyle: foregroundStyle)
                    }
                    Spacer()
                }
                .padding()

                // 2. Bottom left: instrument button panel
                VStack {
                    Spacer()
                    HStack {
                        InstrumentPanelView(showInstruments: $showInstruments, viewModel: viewModel)
                        Spacer()
                    }
                }
                .padding()
                .padding(.horizontal, 30)


                // 3. Bottom center: colorPanel
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ColorPanel(viewModel: viewModel)
                        Spacer()
                    }
                }
                .padding(.bottom)

                // 4. Bottom right: Play button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            viewModel.showPlaybackControls ? viewModel.stopReplay() : viewModel.replayStrokes()
                             
                            playButtonTapCount += 1
                            
                            // Request review after 3 taps
                            if playButtonTapCount == 3 {
                                requestReview()
                            }
                            
                        } label: {
                            Image(systemName: viewModel.showPlaybackControls ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 18)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .accessibilityLabel(viewModel.showPlaybackControls ? "Stop playback" : "Replay Drawing")
                        .buttonStyle(PressableButtonStyle())
                        .frame(width: 75, height: 75, alignment: .bottomTrailing)
//                        .padding(5)
                        .padding(.horizontal, 30)
                    }
                }
                .padding()
                if viewModel.showSettings {
                    SettingsView(viewModel: viewModel) {
                        withAnimation {
                            viewModel.showSettings = false
                        }
                    }
                    .transition(.move(edge: .trailing))
                    .zIndex(2)
                    .padding()
                    .padding(.horizontal, 18)
                    
                }
                
                if viewModel.showExportMenu, let image = viewModel.exportImage {
                    ExportView(image: image) {
                        withAnimation {
                            viewModel.showExportMenu = false
                        }
                    }
                    .transition(.move(edge: .bottom))
                    .zIndex(3)
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onChange(of: viewModel.showExportMenu) { _, newValue in
                if newValue {
                    viewModel.exportImage = viewModel.renderCanvasToImage(size: geometry.size)
                }
            }
        }
      
        .preferredColorScheme(preferredColorScheme)
        .animation(.interactiveSpring(duration: 0.5), value: viewModel.showSettings)
        .animation(.interactiveSpring(duration: 0.5), value: viewModel.showExportMenu)
        .animation(.easeInOut(duration: 0.3), value: viewModel.appTheme)

        .animation(.spring(response: 0.35), value: viewModel.isControlPanelHidden)
        .animation(.spring(response: 0.1), value: viewModel.showNoteLetters)
        .animation(.spring(), value: showInstruments)
    }
    
    var preferredColorScheme: ColorScheme? {
        switch viewModel.appTheme {
        case .system: return nil
        case .canvas: return .light
        case .night: return .dark
        case .colorful: return .dark
        }
    }
}

#Preview {
    PhoneView()
}
