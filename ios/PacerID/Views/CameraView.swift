import SwiftUI

struct CameraView: View {
    @StateObject var viewModel: CameraViewModel

    var body: some View {
        ZStack {
            // Camera preview
            if viewModel.cameraService.isAuthorized,
               viewModel.cameraService.isSessionRunning,
               let session = viewModel.cameraService.session
            {
                CameraPreviewRepresentable(session: session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // Overlay UI
            VStack {
                Spacer()

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

                // Capture button
                CaptureButton(
                    action: {
                        Task {
                            await viewModel.captureAndClassify()
                        }
                    },
                    isProcessing: viewModel.isProcessing
                )
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Pacer-ID")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.setupCamera()
        }
        .onDisappear {
            viewModel.cleanup()
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
    CameraView(viewModel: CameraViewModel(classifier: MockPacemakerClassifier()))
}
