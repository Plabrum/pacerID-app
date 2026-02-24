import Combine
import CoreGraphics

/// Central dependency container for the application
/// Enables dependency injection and testability
@MainActor
final class AppDependencies: ObservableObject {
    // MARK: - Shared Instance

    /// Shared production instance with default dependencies
    static let shared = AppDependencies()

    // MARK: - Dependencies

    let classifier: PacemakerClassifier
    let cameraServiceFactory: () -> any CameraServiceProtocol

    // MARK: - Initialization

    /// Initialize with custom dependencies (primarily for testing)
    /// - Parameters:
    ///   - classifier: The pacemaker classifier to use
    ///   - cameraServiceFactory: Factory for creating camera service instances
    init(
        classifier: PacemakerClassifier? = nil,
        cameraServiceFactory: (() -> any CameraServiceProtocol)? = nil
    ) {
        if let classifier {
            self.classifier = classifier
        } else if let coreML = try? CoreMLPacemakerClassifier() {
            self.classifier = coreML
        } else {
            self.classifier = MockPacemakerClassifier()
        }
        self.cameraServiceFactory = cameraServiceFactory ?? { CameraService() }
    }

    // MARK: - ViewModel Factories

    /// Creates a new CameraViewModel with injected dependencies
    func makeCameraViewModel() -> CameraViewModel {
        CameraViewModel(
            classifier: classifier,
            cameraServiceFactory: cameraServiceFactory
        )
    }

    /// Creates a new ImageClassificationViewModel with injected dependencies
    func makeImageClassificationViewModel(image: CGImage) -> ImageClassificationViewModel {
        ImageClassificationViewModel(
            classifier: classifier,
            image: image
        )
    }

    /// Creates a new ResultsViewModel
    func makeResultsViewModel(classifications: [Classification]) -> ResultsViewModel {
        ResultsViewModel(classifications: classifications)
    }
}
