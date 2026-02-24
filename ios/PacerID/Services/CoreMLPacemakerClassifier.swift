import CoreML
import Foundation
import Vision

/// Real implementation of PacemakerClassifier using the CoreML model.
///
/// The model is exported with ImageNet normalization baked in and class labels
/// embedded via CoreML ClassifierConfig, so Vision returns VNClassificationObservation
/// results directly.
final class CoreMLPacemakerClassifier: PacemakerClassifier {
    private nonisolated(unsafe) let vnModel: VNCoreMLModel

    init() throws {
        guard let modelURL = Bundle.main.url(
            forResource: "PacerIDClassifier",
            withExtension: "mlmodelc"
        ) else {
            throw ClassificationError.modelNotAvailable
        }

        let mlModel = try MLModel(contentsOf: modelURL)
        self.vnModel = try VNCoreMLModel(for: mlModel)
    }

    func classify(image: CGImage) async throws -> [Classification] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: vnModel) { request, _ in
                guard let observations = request.results as? [VNClassificationObservation],
                      !observations.isEmpty
                else {
                    continuation.resume(throwing: ClassificationError.classificationFailed)
                    return
                }

                let results = observations.map {
                    Classification(label: $0.identifier, confidence: Double($0.confidence))
                }
                continuation.resume(returning: results)
            }

            // Center-crop to match training preprocessing
            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ClassificationError.classificationFailed)
            }
        }
    }
}
