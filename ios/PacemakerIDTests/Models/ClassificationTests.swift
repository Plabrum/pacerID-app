@testable import PacerID
import XCTest

@MainActor
final class ClassificationTests: XCTestCase {
    // MARK: - Initialization Tests

    func test_init_setsProperties() {
        // Given
        let label = "Medtronic Azure XT DR"
        let confidence = 0.87

        // When
        let classification = Classification(label: label, confidence: confidence)

        // Then
        XCTAssertEqual(classification.label, label)
        XCTAssertEqual(classification.confidence, confidence, accuracy: 0.001)
    }

    func test_init_generatesUniqueIDs() {
        // Given & When
        let classification1 = Classification(label: "Model A", confidence: 0.8)
        let classification2 = Classification(label: "Model B", confidence: 0.7)

        // Then
        XCTAssertNotEqual(classification1.id, classification2.id)
    }

    // MARK: - Confidence Percentage Tests

    func test_confidencePercentage_formatsCorrectly() {
        // Given
        let classification = Classification(label: "Test", confidence: 0.8745)

        // When
        let formatted = classification.confidencePercentage

        // Then
        XCTAssertEqual(formatted, "87.5%")
    }

    func test_confidencePercentage_handlesZero() {
        // Given
        let classification = Classification(label: "Test", confidence: 0.0)

        // When
        let formatted = classification.confidencePercentage

        // Then
        XCTAssertEqual(formatted, "0.0%")
    }

    func test_confidencePercentage_handlesOne() {
        // Given
        let classification = Classification(label: "Test", confidence: 1.0)

        // When
        let formatted = classification.confidencePercentage

        // Then
        XCTAssertEqual(formatted, "100.0%")
    }

    func test_confidencePercentage_handlesVerySmallValues() {
        // Given
        let classification = Classification(label: "Test", confidence: 0.001)

        // When
        let formatted = classification.confidencePercentage

        // Then
        XCTAssertEqual(formatted, "0.1%")
    }

    // MARK: - Threshold Tests

    func test_isAboveThreshold_whenAbove_returnsTrue() {
        // Given
        let classification = Classification(label: "Test", confidence: 0.85)

        // When
        let result = classification.isAboveThreshold(0.7)

        // Then
        XCTAssertTrue(result)
    }

    func test_isAboveThreshold_whenEqual_returnsTrue() {
        // Given
        let classification = Classification(label: "Test", confidence: 0.7)

        // When
        let result = classification.isAboveThreshold(0.7)

        // Then
        XCTAssertTrue(result)
    }

    func test_isAboveThreshold_whenBelow_returnsFalse() {
        // Given
        let classification = Classification(label: "Test", confidence: 0.65)

        // When
        let result = classification.isAboveThreshold(0.7)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Equatable Tests

    func test_equatable_sameValues_areEqual() {
        // Given
        let classification1 = Classification(label: "Model A", confidence: 0.8)
        let classification2 = Classification(label: "Model A", confidence: 0.8)

        // When & Then
        XCTAssertEqual(classification1, classification2)
    }

    func test_equatable_differentLabels_areNotEqual() {
        // Given
        let classification1 = Classification(label: "Model A", confidence: 0.8)
        let classification2 = Classification(label: "Model B", confidence: 0.8)

        // When & Then
        XCTAssertNotEqual(classification1, classification2)
    }

    func test_equatable_differentConfidence_areNotEqual() {
        // Given
        let classification1 = Classification(label: "Model A", confidence: 0.8)
        let classification2 = Classification(label: "Model A", confidence: 0.7)

        // When & Then
        XCTAssertNotEqual(classification1, classification2)
    }

    // MARK: - Example Data Tests

    func test_example_hasValidData() {
        // When
        let example = Classification.example

        // Then
        XCTAssertFalse(example.label.isEmpty)
        XCTAssertGreaterThan(example.confidence, 0)
        XCTAssertLessThanOrEqual(example.confidence, 1.0)
    }

    func test_exampleResults_hasMultipleResults() {
        // When
        let examples = Classification.exampleResults

        // Then
        XCTAssertEqual(examples.count, 4)
        XCTAssertTrue(examples.allSatisfy { !$0.label.isEmpty })
    }

    func test_exampleResults_sortedByConfidence() {
        // When
        let examples = Classification.exampleResults

        // Then
        for i in 0 ..< examples.count - 1 {
            XCTAssertGreaterThanOrEqual(
                examples[i].confidence,
                examples[i + 1].confidence,
                "Results should be sorted by confidence descending"
            )
        }
    }
}
