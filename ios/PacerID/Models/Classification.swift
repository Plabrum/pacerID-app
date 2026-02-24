import Foundation

/// Represents a classification result with a label and confidence score
struct Classification: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let confidence: Double

    /// Formatted confidence as a percentage string
    var confidencePercentage: String {
        String(format: "%.1f%%", confidence * 100)
    }

    /// Returns true if confidence is above a given threshold
    func isAboveThreshold(_ threshold: Double) -> Bool {
        confidence >= threshold
    }
}

extension Classification {
    /// For preview and testing purposes
    static let example = Classification(label: "Medtronic Azure XT DR", confidence: 0.87)

    static let exampleResults: [Classification] = [
        Classification(label: "Medtronic Azure XT DR", confidence: 0.87),
        Classification(label: "Boston Scientific Accolade MRI", confidence: 0.08),
        Classification(label: "Abbott Ellipse VR", confidence: 0.03),
        Classification(label: "Biotronik Eluna 8 DR-T", confidence: 0.02),
    ]
}
