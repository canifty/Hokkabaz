import SwiftUI

struct ControlsView: View {
    @ObservedObject var strokeManager: StrokeManager
    @ObservedObject var conductor: Conductor

    var body: some View {
        VStack {
//
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    strokeManager.undoLastStroke()
                } label: {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .font(.title)
                }

                Spacer()

                Button {
                    if strokeManager.isPlaying {
                        strokeManager.stopPlayingDrawing()
                    } else {
                        strokeManager.startPlayingDrawing(conductor: conductor)
                    }
                } label: {
                    Image(systemName: strokeManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.largeTitle)
                }

                Spacer()

                Button {
                    strokeManager.clearStrokes()
                    strokeManager.stopPlayingDrawing()
                } label: {
                    Image(systemName: "trash.circle")
                        .font(.title)
                        .foregroundColor(.red)
                }
            }
        }
        .toolbarBackground(.hidden, for: .bottomBar) // Hides toolbar background
    }
}

#Preview {
    ControlsView(strokeManager: StrokeManager(), conductor: Conductor())
}
