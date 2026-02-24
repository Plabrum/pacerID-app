import PhotosUI
import SwiftUI

struct LandingView: View {
    // MARK: - Dependencies

    let classifier: PacemakerClassifier
    @Environment(\.appDependencies) private var dependencies

    // MARK: - State

    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showImageClassification = false
    @State private var photoSelection: PhotosPickerItem?
    @State private var selectedImage: CGImage?
    @State private var isLoadingImage = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                // App Title
                VStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Pacer-ID")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Pacemaker Identification")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)

                Spacer()

                // Action Buttons
                VStack(spacing: 20) {
                    // Capture Image Button
                    Button(action: {
                        showCamera = true
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "camera.fill")
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Capture Image")
                                    .font(.headline)
                                Text("Take a photo with camera")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Capture Image")

                    // Upload Image Button
                    Button(action: {
                        showPhotoPicker = true
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Upload Image")
                                    .font(.headline)
                                Text("Choose from photo library")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Upload Image")
                }
                .padding(.horizontal, 24)

                // Error Message
                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showCamera) {
                CameraView(viewModel: dependencies.makeCameraViewModel())
            }
            .navigationDestination(isPresented: $showImageClassification) {
                if let image = selectedImage {
                    ImageClassificationView(
                        viewModel: dependencies.makeImageClassificationViewModel(image: image)
                    )
                }
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $photoSelection,
                matching: .images
            )
            .onChange(of: photoSelection) { newValue in
                Task {
                    await loadSelectedImage(from: newValue)
                }
            }
        }
    }

    // MARK: - Image Loading

    private func loadSelectedImage(from item: PhotosPickerItem?) async {
        guard let item else { return }

        isLoadingImage = true
        errorMessage = nil

        do {
            // Load image data
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw ImageLoadingError.unableToLoadData
            }

            // Convert to UIImage
            guard let uiImage = UIImage(data: data) else {
                throw ImageLoadingError.invalidImageFormat
            }

            // Convert to CGImage
            guard let cgImage = uiImage.cgImage else {
                throw ImageLoadingError.unableToConvertToCGImage
            }

            // Store and navigate
            selectedImage = cgImage
            showImageClassification = true

        } catch {
            errorMessage = "Failed to load image: \(error.localizedDescription)"
        }

        isLoadingImage = false
        photoSelection = nil
    }
}

// MARK: - Error Types

enum ImageLoadingError: LocalizedError {
    case unableToLoadData
    case invalidImageFormat
    case unableToConvertToCGImage

    var errorDescription: String? {
        switch self {
        case .unableToLoadData:
            "Unable to load image data"
        case .invalidImageFormat:
            "Invalid image format"
        case .unableToConvertToCGImage:
            "Unable to process image"
        }
    }
}

// MARK: - Preview

#Preview {
    LandingView(classifier: MockPacemakerClassifier())
}
