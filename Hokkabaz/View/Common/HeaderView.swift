//
//  HeaderView.swift
//  Hokkabaz
//
//  Created by Can Dindar on 31/07/25.
//

import SwiftUI

struct HeaderView: View {
    
    @ObservedObject var viewModel: SoundCanvasViewModel
    var foregroundStyle: Color
    
    var body: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.4)) {
                    viewModel.showClearConfirmation = true
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(foregroundStyle)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.1))
                    )
            }
            .accessibilityLabel("Clear the Canvas")
            .alert(isPresented: $viewModel.showClearConfirmation) {
                Alert(
                    title: Text("Clear Canvas?"),
                    message: Text("This will permanently delete your drawing and musical creation. This action cannot be undone."),
                    primaryButton: .destructive(Text("Clear All")) {
                        viewModel.clearCanvas()
                    },
                    secondaryButton: .cancel()
                )
            }
            
            Button {
                withAnimation(.spring(response: 0.4)) {
                    viewModel.undoLastStroke()
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(foregroundStyle)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.1))
                    )
            }
            .accessibilityLabel("Undo the stroke")
            
//            Button {
//                withAnimation(.spring(response: 0.4)) {
//                    viewModel.showExportMenu = true
//                }
//            } label: {
//                Image(systemName: "square.and.arrow.up")
//                    .font(.system(size: 18, weight: .semibold))
//                    .foregroundColor(foregroundStyle)
//                    .padding(8)
//                    .background(
//                        Circle()
//                            .fill(Color.black.opacity(0.1))
//                    )
//            }
//            .accessibilityLabel("Export Drawing")
            
            Button {
                withAnimation {
                    viewModel.showSettings.toggle()
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(foregroundStyle)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.1))
                    )
            }
            .accessibilityLabel("Open settings")
        }
                .padding()
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                        .padding(8)
                )

    }
}

// ex ipad header
//    .padding()
//    .background(
//        RoundedRectangle(cornerRadius: 20)
//            .fill(Color.primary.opacity(0.05))
//            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
//    )
//    
//    .frame(maxWidth: .infinity, alignment: .trailing)
