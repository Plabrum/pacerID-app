import CoreGraphics
import Foundation

/// Mock implementation of PacemakerClassifier for testing and demonstration
final class MockPacemakerClassifier: PacemakerClassifier {
    // Common pacemaker brands and models for realistic mock data
    private let pacemakerModels = [
        "Medtronic Azure XT DR",
        "Medtronic Astra DR",
        "Boston Scientific Accolade MRI",
        "Boston Scientific Ingenio MRI",
        "Abbott Ellipse VR",
        "Abbott Assurity MRI",
        "Biotronik Eluna 8 DR-T",
        "Biotronik Etrinsa 8 VR-T",
        "Medtronic Percepta CRT-D",
        "Boston Scientific Resonate X4 CRT-D",
    ]

    /// Simulates classification with random but realistic confidence distribution
    func classify(image _: CGImage) async throws -> [Classification] {
        // Simulate processing delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Generate realistic confidence scores
        // Top result has high confidence, others decay exponentially
        let shuffledModels = pacemakerModels.shuffled()
        var results: [Classification] = []

        // Generate a random top confidence between 0.7 and 0.95
        var remainingProbability = 1.0
        let topConfidence = Double.random(in: 0.70 ... 0.95)

        results.append(Classification(
            label: shuffledModels[0],
            confidence: topConfidence
        ))
        remainingProbability -= topConfidence

        // Distribute remaining probability across other models
        let numberOfResults = min(5, shuffledModels.count)
        for i in 1 ..< numberOfResults {
            let confidence = remainingProbability * Double.random(in: 0.15 ... 0.40)
            results.append(Classification(
                label: shuffledModels[i],
                confidence: confidence
            ))
            remainingProbability -= confidence
        }

        // Sort by confidence descending
        return results.sorted { $0.confidence > $1.confidence }
    }
}
