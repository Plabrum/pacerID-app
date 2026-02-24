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
}
