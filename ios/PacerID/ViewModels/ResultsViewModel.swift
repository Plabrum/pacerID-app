import Foundation

@MainActor
final class ResultsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var classifications: [Classification]

    // MARK: - Computed Properties

    var topResult: Classification? {
        classifications.first
    }

    var hasHighConfidenceResult: Bool {
        topResult?.confidence ?? 0 > 0.7
    }

    var confidenceLevel: String {
        guard let confidence = topResult?.confidence else { return "Unknown" }

        switch confidence {
        case 0.9...:
            return "Very High"
        case 0.7 ..< 0.9:
            return "High"
        case 0.5 ..< 0.7:
            return "Moderate"
        default:
            return "Low"
        }
    }

    // MARK: - Initialization

    init(classifications: [Classification]) {
        self.classifications = classifications
    }

    // MARK: - Helper Methods

    func formattedConfidence(for classification: Classification) -> String {
        String(format: "%.1f%%", classification.confidence * 100)
    }

    /// Returns the top N results, useful for displaying a subset
    func topResults(_ count: Int) -> [Classification] {
        Array(classifications.prefix(count))
    }
}
