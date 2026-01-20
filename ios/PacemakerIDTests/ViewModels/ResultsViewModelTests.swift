@testable import PacerID
import XCTest

@MainActor
final class ResultsViewModelTests: XCTestCase {
    var viewModel: ResultsViewModel!
    var testClassifications: [Classification]!

    override func setUp() {
        super.setUp()
        testClassifications = TestHelpers.createClassifications(count: 4, topConfidence: 0.87)
        viewModel = ResultsViewModel(classifications: testClassifications)
    }

    override func tearDown() {
        viewModel = nil
        testClassifications = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_setsClassifications() {
        // Given & When (in setUp)
        // Then
        XCTAssertEqual(viewModel.classifications.count, testClassifications.count)
        XCTAssertEqual(viewModel.classifications, testClassifications)
    }

    // MARK: - Top Result Tests

    func test_topResult_returnsFirstClassification() {
        // When
        let topResult = viewModel.topResult

        // Then
        XCTAssertEqual(topResult, testClassifications.first)
    }

    func test_topResult_whenEmpty_returnsNil() {
        // Given
        viewModel = ResultsViewModel(classifications: [])

        // When
        let topResult = viewModel.topResult

        // Then
        XCTAssertNil(topResult)
    }

    // MARK: - High Confidence Tests

    func test_hasHighConfidenceResult_whenAbove70Percent_returnsTrue() {
        // Given
        let classifications = [TestHelpers.createClassification(confidence: 0.85)]
        viewModel = ResultsViewModel(classifications: classifications)

        // When
        let hasHighConfidence = viewModel.hasHighConfidenceResult

        // Then
        XCTAssertTrue(hasHighConfidence)
    }

    func test_hasHighConfidenceResult_whenExactly70Percent_returnsFalse() {
        // Given
        let classifications = [TestHelpers.createClassification(confidence: 0.70)]
        viewModel = ResultsViewModel(classifications: classifications)

        // When
        let hasHighConfidence = viewModel.hasHighConfidenceResult

        // Then
        XCTAssertFalse(hasHighConfidence)
    }

    func test_hasHighConfidenceResult_whenBelow70Percent_returnsFalse() {
        // Given
        let classifications = [TestHelpers.createClassification(confidence: 0.65)]
        viewModel = ResultsViewModel(classifications: classifications)

        // When
        let hasHighConfidence = viewModel.hasHighConfidenceResult

        // Then
        XCTAssertFalse(hasHighConfidence)
    }

    func test_hasHighConfidenceResult_whenEmpty_returnsFalse() {
        // Given
        viewModel = ResultsViewModel(classifications: [])

        // When
        let hasHighConfidence = viewModel.hasHighConfidenceResult

        // Then
        XCTAssertFalse(hasHighConfidence)
    }

    // MARK: - Confidence Level Tests

    func test_confidenceLevel_whenVeryHigh_returnsVeryHigh() {
        // Given
        let classifications = [TestHelpers.createClassification(confidence: 0.95)]
        viewModel = ResultsViewModel(classifications: classifications)

        // When
        let level = viewModel.confidenceLevel

        // Then
        XCTAssertEqual(level, "Very High")
    }

    func test_confidenceLevel_when90Percent_returnsVeryHigh() {
        // Given
        let classifications = [TestHelpers.createClassification(confidence: 0.90)]
        viewModel = ResultsViewModel(classifications: classifications)

        // When
        let level = viewModel.confidenceLevel

        // Then
        XCTAssertEqual(level, "Very High")
    }

    func test_confidenceLevel_whenHigh_returnsHigh() {
        // Given
        let classifications = [TestHelpers.createClassification(confidence: 0.80)]
        viewModel = ResultsViewModel(classifications: classifications)

        // When
        let level = viewModel.confidenceLevel

        // Then
        XCTAssertEqual(level, "High")
    }

    func test_confidenceLevel_when70Percent_returnsHigh() {
        // Given
        let classifications = [TestHelpers.createClassification(confidence: 0.70)]
        viewModel = ResultsViewModel(classifications: classifications)

        // When
        let level = viewModel.confidenceLevel

        // Then
        XCTAssertEqual(level, "High")
    }

    func test_confidenceLevel_whenModerate_returnsModerate() {
        // Given
        let classifications = [TestHelpers.createClassification(confidence: 0.60)]
        viewModel = ResultsViewModel(classifications: classifications)

        // When
        let level = viewModel.confidenceLevel

        // Then
        XCTAssertEqual(level, "Moderate")
    }

    func test_confidenceLevel_when50Percent_returnsModerate() {
        // Given
        let classifications = [TestHelpers.createClassification(confidence: 0.50)]
        viewModel = ResultsViewModel(classifications: classifications)

        // When
        let level = viewModel.confidenceLevel

        // Then
        XCTAssertEqual(level, "Moderate")
    }

    func test_confidenceLevel_whenLow_returnsLow() {
        // Given
        let classifications = [TestHelpers.createClassification(confidence: 0.40)]
        viewModel = ResultsViewModel(classifications: classifications)

        // When
        let level = viewModel.confidenceLevel

        // Then
        XCTAssertEqual(level, "Low")
    }

    func test_confidenceLevel_whenEmpty_returnsUnknown() {
        // Given
        viewModel = ResultsViewModel(classifications: [])

        // When
        let level = viewModel.confidenceLevel

        // Then
        XCTAssertEqual(level, "Unknown")
    }

    // MARK: - Formatted Confidence Tests

    func test_formattedConfidence_formatsCorrectly() {
        // Given
        let classification = Classification(label: "Test", confidence: 0.8745)

        // When
        let formatted = viewModel.formattedConfidence(for: classification)

        // Then
        XCTAssertEqual(formatted, "87.5%")
    }

    func test_formattedConfidence_handlesZero() {
        // Given
        let classification = Classification(label: "Test", confidence: 0.0)

        // When
        let formatted = viewModel.formattedConfidence(for: classification)

        // Then
        XCTAssertEqual(formatted, "0.0%")
    }

    func test_formattedConfidence_handlesOne() {
        // Given
        let classification = Classification(label: "Test", confidence: 1.0)

        // When
        let formatted = viewModel.formattedConfidence(for: classification)

        // Then
        XCTAssertEqual(formatted, "100.0%")
    }

    // MARK: - Top Results Tests

    func test_topResults_returnsCorrectCount() {
        // Given (viewModel has 4 classifications)

        // When
        let top2 = viewModel.topResults(2)

        // Then
        XCTAssertEqual(top2.count, 2)
        XCTAssertEqual(top2[0], testClassifications[0])
        XCTAssertEqual(top2[1], testClassifications[1])
    }

    func test_topResults_whenRequestMoreThanAvailable_returnsAll() {
        // Given (viewModel has 4 classifications)

        // When
        let top10 = viewModel.topResults(10)

        // Then
        XCTAssertEqual(top10.count, testClassifications.count)
    }

    func test_topResults_whenRequestZero_returnsEmpty() {
        // When
        let top0 = viewModel.topResults(0)

        // Then
        XCTAssertEqual(top0.count, 0)
    }

    func test_topResults_preservesOrder() {
        // When
        let top3 = viewModel.topResults(3)

        // Then
        for i in 0 ..< 3 {
            XCTAssertEqual(top3[i], testClassifications[i])
        }
    }
}
