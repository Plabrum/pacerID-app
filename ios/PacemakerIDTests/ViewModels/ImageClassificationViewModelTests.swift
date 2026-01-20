import CoreGraphics
@testable import PacerID
import XCTest

@MainActor
final class ImageClassificationViewModelTests: XCTestCase {
    var viewModel: ImageClassificationViewModel!
    var mockClassifier: ConfigurableMockPacemakerClassifier!
    var testImage: CGImage!

    override func setUp() {
        super.setUp()
        testImage = TestHelpers.createTestImage()
        mockClassifier = ConfigurableMockPacemakerClassifier(delayNanoseconds: 10_000_000)
        viewModel = ImageClassificationViewModel(
            classifier: mockClassifier,
            image: testImage!
        )
    }

    override func tearDown() {
        viewModel = nil
        mockClassifier = nil
        testImage = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_setsImageAndClassifier() {
        // Given & When (in setUp)
        // Then
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNil(viewModel.classifications)
        XCTAssertFalse(viewModel.showResults)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Classify Success Tests

    func test_classify_whenSuccessful_setsClassifications() async {
        // Given
        let expectedResults = TestHelpers.createClassifications()
        mockClassifier.resultsToReturn = expectedResults

        // When
        await viewModel.classify()

        // Then
        XCTAssertEqual(viewModel.classifications, expectedResults)
        XCTAssertTrue(viewModel.showResults)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isProcessing)
    }

    func test_classify_callsClassifierWithImage() async {
        // Given
        mockClassifier.resultsToReturn = TestHelpers.createClassifications()

        // When
        await viewModel.classify()

        // Then
        XCTAssertEqual(mockClassifier.classifyCallCount, 1)
    }

    // MARK: - Classify Failure Tests

    func test_classify_whenFails_setsErrorMessage() async {
        // Given
        mockClassifier.shouldThrowError = true

        // When
        await viewModel.classify()

        // Then
        XCTAssertNil(viewModel.classifications)
        XCTAssertFalse(viewModel.showResults)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isProcessing)
    }

    func test_classify_whenCustomError_setsErrorMessage() async {
        // Given
        let customError = NSError(domain: "test", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Custom error message",
        ])
        mockClassifier.errorToThrow = customError

        // When
        await viewModel.classify()

        // Then
        XCTAssertNil(viewModel.classifications)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Custom error message")
    }

    // MARK: - Processing State Tests

    func test_classify_setsProcessingState() async {
        // Given
        mockClassifier.delayNanoseconds = 100_000_000 // 100ms
        mockClassifier.resultsToReturn = TestHelpers.createClassifications()

        // When - Start classify task
        let task = Task {
            await viewModel.classify()
        }

        // Check processing state during execution
        try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
        XCTAssertTrue(viewModel.isProcessing, "Should be processing")

        // Wait for completion
        await task.value

        // Then - Processing should be complete
        XCTAssertFalse(viewModel.isProcessing, "Should not be processing after completion")
    }

    func test_classify_clearsPreviousError() async {
        // Given - Set an error first
        mockClassifier.shouldThrowError = true
        await viewModel.classify()
        XCTAssertNotNil(viewModel.errorMessage)

        // When - Classify successfully
        mockClassifier.shouldThrowError = false
        mockClassifier.resultsToReturn = TestHelpers.createClassifications()
        await viewModel.classify()

        // Then
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Concurrent Calls Tests

    func test_classify_whenAlreadyProcessing_doesNothing() async {
        // Given
        mockClassifier.delayNanoseconds = 200_000_000 // 200ms to ensure overlap
        mockClassifier.resultsToReturn = TestHelpers.createClassifications()

        // When - Start two classify calls
        let task1 = Task {
            await viewModel.classify()
        }

        // Give first call time to start
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

        let callCountBefore = mockClassifier.classifyCallCount

        // Try to start second call while first is processing
        await viewModel.classify()

        // Then - Second call should be ignored
        XCTAssertEqual(mockClassifier.classifyCallCount, callCountBefore, "Should not make second call")

        // Wait for first task to complete
        await task1.value
    }

    // MARK: - Dismiss Results Tests

    func test_dismissResults_clearsClassificationsAndHidesResults() async {
        // Given
        mockClassifier.resultsToReturn = TestHelpers.createClassifications()
        await viewModel.classify()
        XCTAssertNotNil(viewModel.classifications)
        XCTAssertTrue(viewModel.showResults)

        // When
        viewModel.dismissResults()

        // Then
        XCTAssertNil(viewModel.classifications)
        XCTAssertFalse(viewModel.showResults)
    }

    func test_dismissResults_whenNoResults_doesNotCrash() {
        // Given - No classifications set

        // When & Then - Should not crash
        viewModel.dismissResults()

        XCTAssertNil(viewModel.classifications)
        XCTAssertFalse(viewModel.showResults)
    }

    // MARK: - Integration Tests

    func test_fullClassificationFlow() async {
        // Given
        let expectedResults = TestHelpers.createClassifications(count: 3)
        mockClassifier.resultsToReturn = expectedResults

        // When - Classify
        await viewModel.classify()

        // Then - Results shown
        XCTAssertEqual(viewModel.classifications, expectedResults)
        XCTAssertTrue(viewModel.showResults)
        XCTAssertNil(viewModel.errorMessage)

        // When - Dismiss
        viewModel.dismissResults()

        // Then - Results cleared
        XCTAssertNil(viewModel.classifications)
        XCTAssertFalse(viewModel.showResults)
    }
}
