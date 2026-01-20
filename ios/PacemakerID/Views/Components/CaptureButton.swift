import SwiftUI

/// Camera shutter button with standard iOS camera app appearance
struct CaptureButton: View {
    let action: () -> Void
    let isProcessing: Bool

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 70, height: 70)

                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                } else {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 58, height: 58)
                }
            }
        }
        .disabled(isProcessing)
        .accessibilityLabel("Capture photo")
        .accessibilityHint("Takes a photo of the X-ray for pacemaker identification")
    }
}

#Preview {
    VStack(spacing: 40) {
        CaptureButton(action: {}, isProcessing: false)
        CaptureButton(action: {}, isProcessing: true)
    }
    .padding()
    .background(Color.black)
}
