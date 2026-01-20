import CoreGraphics
import SwiftUI

@MainActor
final class ImageClassificationViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isProcessing = false
    @Published var classifications: [Classification]?
    @Published var showResults = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private nonisolated(unsafe) let classifier: PacemakerClassifier
    private let image: CGImage

    // MARK: - Initialization

    init(classifier: PacemakerClassifier, image: CGImage) {
        self.classifier = classifier
        self.image = image
    }

    // MARK: - Classification

    func classify() async {
        guard !isProcessing else { return }

        isProcessing = true
        errorMessage = nil

        do {
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
}
