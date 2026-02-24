import CoreGraphics
import SwiftUI

@MainActor
final class CameraViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var cameraService: any CameraServiceProtocol
    @Published var isProcessing = false
    @Published var classifications: [Classification]?
    @Published var showResults = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private nonisolated(unsafe) let classifier: PacemakerClassifier

    // MARK: - Initialization

    init(
        classifier: PacemakerClassifier,
        cameraServiceFactory: (() -> any CameraServiceProtocol)? = nil
    ) {
        self.cameraService = cameraServiceFactory?() ?? CameraService()
        self.classifier = classifier
    }

    // MARK: - Camera Setup

    func setupCamera() async {
        await cameraService.checkAuthorization()

        guard cameraService.isAuthorized else {
            errorMessage = "Camera access is required to use this app. Please enable it in Settings."
            return
        }

        do {
            try await cameraService.setupSession()
            await cameraService.startSession()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Photo Capture & Classification

    func captureAndClassify() async {
        guard !isProcessing else { return }

        isProcessing = true
        errorMessage = nil

        do {
            let image = try await cameraService.capturePhoto()
            let results = try await classifier.classify(image: image)

            classifications = results
            showResults = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    // MARK: - Navigation

    func dismissResults() {
        showResults = false
        classifications = nil
    }

    // MARK: - Cleanup

    func cleanup() {
        Task {
            await cameraService.stopSession()
        }
    }
}
