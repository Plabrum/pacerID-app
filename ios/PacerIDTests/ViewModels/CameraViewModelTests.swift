import CoreGraphics
@testable import PacerID
import XCTest

@MainActor
final class CameraViewModelTests: XCTestCase {
    var viewModel: CameraViewModel!
    var mockCameraService: MockCameraService!
    var mockClassifier: ConfigurableMockPacemakerClassifier!

    override func setUp() {
        super.setUp()
        mockCameraService = MockCameraService(authorizationResult: true)
        mockClassifier = ConfigurableMockPacemakerClassifier(delayNanoseconds: 10_000_000)
        viewModel = CameraViewModel(
            classifier: mockClassifier,
            cameraServiceFactory: { self.mockCameraService }
        )
    }

    override func tearDown() {
        viewModel = nil
        mockCameraService = nil
        mockClassifier = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_createsServiceThroughFactory() {
        // Then
        XCTAssertNotNil(viewModel.cameraService)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNil(viewModel.classifications)
        XCTAssertFalse(viewModel.showResults)
    }

    // MARK: - Setup Camera Tests

    func test_setupCamera_whenAuthorized_startsSession() async {
        // Given
        mockCameraService.authorizationResult = true

        // When
        await viewModel.setupCamera()

        // Then
        XCTAssertEqual(mockCameraService.checkAuthorizationCallCount, 1)
        XCTAssertEqual(mockCameraService.setupSessionCallCount, 1)
        XCTAssertEqual(mockCameraService.startSessionCallCount, 1)
        XCTAssertTrue(mockCameraService.isAuthorized)
        XCTAssertTrue(mockCameraService.isSessionRunning)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_setupCamera_whenNotAuthorized_setsErrorMessage() async {
        // Given
        mockCameraService.authorizationResult = false

        // When
        await viewModel.setupCamera()

        // Then
        XCTAssertEqual(mockCameraService.checkAuthorizationCallCount, 1)
        XCTAssertEqual(mockCameraService.setupSessionCallCount, 0)
        XCTAssertEqual(mockCameraService.startSessionCallCount, 0)
        XCTAssertFalse(mockCameraService.isAuthorized)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Camera access is required") ?? false)
    }

    func test_setupCamera_whenSetupFails_setsErrorMessage() async {
        // Given
        mockCameraService.authorizationResult = true
        mockCameraService.setupShouldThrow = true
        mockCameraService.setupError = .cannotAddInput

        // When
        await viewModel.setupCamera()

        // Then
        XCTAssertEqual(mockCameraService.checkAuthorizationCallCount, 1)
        XCTAssertEqual(mockCameraService.setupSessionCallCount, 1)
        XCTAssertEqual(mockCameraService.startSessionCallCount, 0)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Capture and Classify Tests

    func test_captureAndClassify_whenSuccessful_setsClassifications() async {
        // Given
        mockCameraService.isSessionRunning = true
        let expectedClassifications = TestHelpers.createClassifications()
        mockClassifier.resultsToReturn = expectedClassifications

        // When
        await viewModel.captureAndClassify()

        // Then
        XCTAssertEqual(mockCameraService.capturePhotoCallCount, 1)
        XCTAssertEqual(mockClassifier.classifyCallCount, 1)
        XCTAssertEqual(viewModel.classifications, expectedClassifications)
        XCTAssertTrue(viewModel.showResults)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isProcessing)
    }

    func test_captureAndClassify_whenCaptureFails_setsErrorMessage() async {
        // Given
        mockCameraService.isSessionRunning = true
        mockCameraService.captureShouldThrow = true

        // When
        await viewModel.captureAndClassify()

        // Then
        XCTAssertEqual(mockCameraService.capturePhotoCallCount, 1)
        XCTAssertEqual(mockClassifier.classifyCallCount, 0)
        XCTAssertNil(viewModel.classifications)
        XCTAssertFalse(viewModel.showResults)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isProcessing)
    }

    func test_captureAndClassify_whenClassificationFails_setsErrorMessage() async {
        // Given
        mockCameraService.isSessionRunning = true
        mockClassifier.shouldThrowError = true

        // When
        await viewModel.captureAndClassify()

        // Then
        XCTAssertEqual(mockCameraService.capturePhotoCallCount, 1)
        XCTAssertEqual(mockClassifier.classifyCallCount, 1)
        XCTAssertNil(viewModel.classifications)
        XCTAssertFalse(viewModel.showResults)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isProcessing)
    }

    func test_captureAndClassify_whenAlreadyProcessing_doesNothing() async {
        // Given
        mockCameraService.isSessionRunning = true
        mockClassifier.delayNanoseconds = 200_000_000 // 200ms
        mockClassifier.resultsToReturn = TestHelpers.createClassifications()

        // When - Start first capture
        let task = Task {
            await viewModel.captureAndClassify()
        }

        // Wait for processing to start
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

        let captureCountBefore = mockCameraService.capturePhotoCallCount

        // Try to start second capture
        await viewModel.captureAndClassify()

        // Then - Second call should be ignored
        XCTAssertEqual(mockCameraService.capturePhotoCallCount, captureCountBefore)

        // Wait for first task to complete
        await task.value
    }

    func test_captureAndClassify_clearsPreviousError() async {
        // Given - Set an error first
        mockCameraService.isSessionRunning = true
        mockCameraService.captureShouldThrow = true
        await viewModel.captureAndClassify()
        XCTAssertNotNil(viewModel.errorMessage)

        // When - Successful capture
        mockCameraService.captureShouldThrow = false
        mockClassifier.resultsToReturn = TestHelpers.createClassifications()
        await viewModel.captureAndClassify()

        // Then
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNotNil(viewModel.classifications)
    }

    // MARK: - Processing State Tests

    func test_captureAndClassify_setsProcessingState() async {
        // Given
        mockCameraService.isSessionRunning = true
        mockClassifier.delayNanoseconds = 100_000_000 // 100ms
        mockClassifier.resultsToReturn = TestHelpers.createClassifications()

        // When - Start capture task
        let task = Task {
            await viewModel.captureAndClassify()
        }

        // Check processing state during execution
        try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
        XCTAssertTrue(viewModel.isProcessing, "Should be processing")

        // Wait for completion
        await task.value

        // Then - Processing should be complete
        XCTAssertFalse(viewModel.isProcessing, "Should not be processing after completion")
    }

    // MARK: - Dismiss Results Tests

    func test_dismissResults_clearsClassificationsAndHidesResults() async {
        // Given
        mockCameraService.isSessionRunning = true
        mockClassifier.resultsToReturn = TestHelpers.createClassifications()
        await viewModel.captureAndClassify()
        XCTAssertNotNil(viewModel.classifications)
        XCTAssertTrue(viewModel.showResults)

        // When
        viewModel.dismissResults()

        // Then
        XCTAssertNil(viewModel.classifications)
        XCTAssertFalse(viewModel.showResults)
    }

    // MARK: - Cleanup Tests

    func test_cleanup_stopsSession() async {
        // Given
        mockCameraService.isSessionRunning = true

        // When
        viewModel.cleanup()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then
        XCTAssertEqual(mockCameraService.stopSessionCallCount, 1)
    }

    // MARK: - Integration Tests

    func test_fullCameraFlow() async {
        // Given
        mockCameraService.authorizationResult = true
        let expectedClassifications = TestHelpers.createClassifications()
        mockClassifier.resultsToReturn = expectedClassifications

        // When - Setup camera
        await viewModel.setupCamera()

        // Then - Camera setup successful
        XCTAssertTrue(mockCameraService.isAuthorized)
        XCTAssertTrue(mockCameraService.isSessionRunning)
        XCTAssertNil(viewModel.errorMessage)

        // When - Capture and classify
        await viewModel.captureAndClassify()

        // Then - Results shown
        XCTAssertEqual(viewModel.classifications, expectedClassifications)
        XCTAssertTrue(viewModel.showResults)

        // When - Dismiss results
        viewModel.dismissResults()

        // Then - Results cleared
        XCTAssertNil(viewModel.classifications)
        XCTAssertFalse(viewModel.showResults)

        // When - Cleanup
        viewModel.cleanup()

        // Wait for cleanup
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then - Session stopped
        XCTAssertEqual(mockCameraService.stopSessionCallCount, 1)
    }

    func test_errorRecoveryFlow() async {
        // Given
        mockCameraService.isSessionRunning = true
        mockCameraService.captureShouldThrow = true

        // When - First capture fails
        await viewModel.captureAndClassify()

        // Then - Error set
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.classifications)

        // When - Fix error and retry
        mockCameraService.captureShouldThrow = false
        mockClassifier.resultsToReturn = TestHelpers.createClassifications()
        await viewModel.captureAndClassify()

        // Then - Success
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNotNil(viewModel.classifications)
        XCTAssertTrue(viewModel.showResults)
    }
}
