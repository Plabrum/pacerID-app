import SwiftUI

struct ImageClassificationView: View {
    @StateObject var viewModel: ImageClassificationViewModel

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Processing State
                if viewModel.isProcessing {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text("Analyzing image...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }

                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()
            }
        }
        .navigationTitle("Analyzing")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.classify()
        }
        .navigationDestination(isPresented: $viewModel.showResults) {
            if let classifications = viewModel.classifications {
                ResultsView(
                    viewModel: ResultsViewModel(classifications: classifications),
                    onDismiss: {
                        viewModel.dismissResults()
                    }
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        ImageClassificationView(
            viewModel: ImageClassificationViewModel(
                classifier: MockPacemakerClassifier(),
                image: CGImage(
                    width: 100,
                    height: 100,
                    bitsPerComponent: 8,
                    bitsPerPixel: 32,
                    bytesPerRow: 400,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                    provider: CGDataProvider(data: Data(count: 40000) as CFData)!,
                    decode: nil,
                    shouldInterpolate: false,
                    intent: .defaultIntent
                )!
            )
        )
    }
}
