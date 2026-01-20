import CoreGraphics
import Foundation

/// Configurable mock implementation of PacemakerClassifier for testing
/// Allows tests to control classification behavior, timing, and errors
final class ConfigurableMockPacemakerClassifier: PacemakerClassifier {
    // MARK: - Configuration

    /// Delay in nanoseconds before returning results (default: 100ms)
    var delayNanoseconds: UInt64 = 100_000_000

    /// If true, throws ClassificationError.classificationFailed
    var shouldThrowError = false

    /// Specific error to throw (overrides shouldThrowError)
    var errorToThrow: Error?

    /// Predetermined results to return (if nil, generates random results)
    var resultsToReturn: [Classification]?

    /// Number of times classify has been called
    private(set) var classifyCallCount = 0

    // MARK: - Test Data

    private let pacemakerModels = [
        "Medtronic Azure XT DR",
        "Medtronic Astra DR",
        "Boston Scientific Accolade MRI",
        "Boston Scientific Ingenio MRI",
        "Abbott Ellipse VR",
        "Abbott Assurity MRI",
        "Biotronik Eluna 8 DR-T",
        "Biotronik Etrinsa 8 VR-T",
    ]

    // MARK: - Initialization

    init(
        delayNanoseconds: UInt64 = 100_000_000,
        shouldThrowError: Bool = false,
        resultsToReturn: [Classification]? = nil
    ) {
        self.delayNanoseconds = delayNanoseconds
        self.shouldThrowError = shouldThrowError
        self.resultsToReturn = resultsToReturn
    }

    // MARK: - PacemakerClassifier

    func classify(image _: CGImage) async throws -> [Classification] {
        classifyCallCount += 1

        // Simulate processing delay
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }

        // Throw configured error if requested
        if let error = errorToThrow {
            throw error
        }

        if shouldThrowError {
            throw ClassificationError.classificationFailed
        }

        // Return predetermined results if configured
        if let results = resultsToReturn {
            return results
        }

        // Generate random results as fallback
        return generateRandomResults()
    }

    // MARK: - Helper Methods

    /// Generates random but realistic classification results
    private func generateRandomResults() -> [Classification] {
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
        let numberOfResults = min(4, shuffledModels.count)
        for i in 1 ..< numberOfResults {
            let confidence = remainingProbability * Double.random(in: 0.15 ... 0.40)
            results.append(Classification(
                label: shuffledModels[i],
                confidence: confidence
            ))
            remainingProbability -= confidence
        }

        return results.sorted { $0.confidence > $1.confidence }
    }

    /// Resets the mock state
    func reset() {
        classifyCallCount = 0
        delayNanoseconds = 100_000_000
        shouldThrowError = false
        errorToThrow = nil
        resultsToReturn = nil
    }
}
