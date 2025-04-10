import SwiftUI

struct ExportView: View {
    let image: UIImage
    let closeAction: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            HStack {
                Text("Export Drawing")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    closeAction()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.primary.opacity(0.6))
                }
                .accessibilityLabel("Close export panel")
            }
            
            // Image preview
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .cornerRadius(12)
                .padding(.vertical, 10)
            
            // Export options
            HStack(spacing: 15) {
                ShareLink(item: Image(uiImage: image), preview: SharePreview("My Drawing", image: Image(uiImage: image))) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    // Close menu after a short delay
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        closeAction()
//                    }
                })
                
                Button {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

                    // Close menu after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        closeAction()
                    }
                } label: {
                    Label("Save to Photos", systemImage: "photo")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 0)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}
