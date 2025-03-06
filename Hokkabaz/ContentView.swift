import SwiftUI
import AudioKit
struct ContentView: View {
    @StateObject private var conductor = Conductor()
    @StateObject private var strokeManager = StrokeManager()

    var body: some View {
        ZStack {
            Image("roughTexture")
                .resizable(capInsets: EdgeInsets(), resizingMode: .tile)
                .ignoresSafeArea()
            
        VStack {
            DrawingCanvas(strokeManager: strokeManager, conductor: conductor)
            ControlsView(strokeManager: strokeManager, conductor: conductor)
        }
        .padding()
        .onDisappear {
            strokeManager.stopPlayingDrawing()
            conductor.stopOscillator()
            do {
                try conductor.engine.stop()
            } catch {
                Log("AudioKit did not stop!")
            }
        }
    }
    }
}

#Preview {
    ContentView()
}
