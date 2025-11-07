import CoreGraphics
import Foundation

/// Protocol for pacemaker classification services
protocol PacemakerClassifier {
    /// Classifies an image and returns a list of possible pacemaker brands/models
    /// with their confidence scores, sorted by confidence (highest first)
    ///
    /// - Parameter image: The CGImage to classify
    /// - Returns: An array of Classification results
    func classify(image: CGImage) async throws -> [Classification]
}

/// Errors that can occur during classification
enum ClassificationError: LocalizedError {
    case invalidImage
    case classificationFailed
    case modelNotAvailable

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            "The provided image is invalid or corrupted."
        case .classificationFailed:
            "Failed to classify the image. Please try again."
        case .modelNotAvailable:
            "The classification model is not available."
        }
    }
}
