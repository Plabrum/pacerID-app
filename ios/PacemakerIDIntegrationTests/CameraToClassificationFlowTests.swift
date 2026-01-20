import CoreGraphics
@testable import PacerID
import XCTest

/// Integration tests for the full camera → capture → classify → results flow
@MainActor
final class CameraToClassificationFlowTests: XCTestCase {
    var mockCameraService: MockCameraService!
    var mockClassifier: ConfigurableMockPacemakerClassifier!
    var cameraViewModel: CameraViewModel!
    var resultsViewModel: ResultsViewModel!

    override func setUp() {
        super.setUp()
        mockCameraService = MockCameraService(authorizationResult: true)
        mockClassifier = ConfigurableMockPacemakerClassifier(delayNanoseconds: 10_000_000)
        cameraViewModel = CameraViewModel(
            classifier: mockClassifier,
            cameraServiceFactory: { self.mockCameraService }
        )
    }

    override func tearDown() {
        cameraViewModel = nil
        mockCameraService = nil
        mockClassifier = nil
        resultsViewModel = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func test_fullCameraFlow_happyPath() async {
        // Given
        let expectedClassifications = [
            Classification(label: "Medtronic Azure XT DR", confidence: 0.89),
            Classification(label: "Boston Scientific Accolade MRI", confidence: 0.08),
            Classification(label: "Abbott Ellipse VR", confidence: 0.03),
        ]
        mockClassifier.resultsToReturn = expectedClassifications

        // When - Step 1: Setup camera
        await cameraViewModel.setupCamera()

        // Then - Camera is authorized and running
        XCTAssertTrue(mockCameraService.isAuthorized)
        XCTAssertTrue(mockCameraService.isSessionRunning)
        XCTAssertNil(cameraViewModel.errorMessage)

        // When - Step 2: Capture and classify
        await cameraViewModel.captureAndClassify()

        // Then - Classifications are set
        XCTAssertEqual(cameraViewModel.classifications, expectedClassifications)
        XCTAssertTrue(cameraViewModel.showResults)
        XCTAssertNil(cameraViewModel.errorMessage)

        // When - Step 3: Create results view model
        resultsViewModel = ResultsViewModel(classifications: cameraViewModel.classifications!)

        // Then - Results view model has correct data
        XCTAssertEqual(resultsViewModel.topResult?.label, "Medtronic Azure XT DR")
        XCTAssertTrue(resultsViewModel.hasHighConfidenceResult)
        XCTAssertEqual(resultsViewModel.confidenceLevel, "High")

        // When - Step 4: Dismiss results
        cameraViewModel.dismissResults()

        // Then - Ready for next capture
        XCTAssertNil(cameraViewModel.classifications)
        XCTAssertFalse(cameraViewModel.showResults)
        XCTAssertTrue(mockCameraService.isSessionRunning)

        // When - Step 5: Cleanup
        cameraViewModel.cleanup()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then - Session stopped
        XCTAssertFalse(mockCameraService.isSessionRunning)
    }

    func test_multipleCaptures_inSequence() async {
        // Given
        await cameraViewModel.setupCamera()
        let firstResults = [Classification(label: "Model A", confidence: 0.85)]
        let secondResults = [Classification(label: "Model B", confidence: 0.92)]

        // When - First capture
        mockClassifier.resultsToReturn = firstResults
        await cameraViewModel.captureAndClassify()

        // Then
        XCTAssertEqual(cameraViewModel.classifications, firstResults)

        // When - Dismiss and capture again
        cameraViewModel.dismissResults()
        mockClassifier.resultsToReturn = secondResults
        await cameraViewModel.captureAndClassify()

        // Then
        XCTAssertEqual(cameraViewModel.classifications, secondResults)
        XCTAssertEqual(mockCameraService.capturePhotoCallCount, 2)
        XCTAssertEqual(mockClassifier.classifyCallCount, 2)
    }

    // MARK: - Error Path Tests

    func test_authorizationDenied_showsError() async {
        // Given
        mockCameraService.authorizationResult = false

        // When
        await cameraViewModel.setupCamera()

        // Then
        XCTAssertFalse(mockCameraService.isAuthorized)
        XCTAssertFalse(mockCameraService.isSessionRunning)
        XCTAssertNotNil(cameraViewModel.errorMessage)
        XCTAssertTrue(cameraViewModel.errorMessage?.contains("Camera access is required") ?? false)

        // When - Try to capture (should fail)
        await cameraViewModel.captureAndClassify()

        // Then - Still no results
        XCTAssertNil(cameraViewModel.classifications)
        XCTAssertFalse(cameraViewModel.showResults)
    }

    func test_setupFails_showsError() async {
        // Given
        mockCameraService.setupShouldThrow = true
        mockCameraService.setupError = .cannotAddInput

        // When
        await cameraViewModel.setupCamera()

        // Then
        XCTAssertTrue(mockCameraService.isAuthorized)
        XCTAssertFalse(mockCameraService.isSessionRunning)
        XCTAssertNotNil(cameraViewModel.errorMessage)
    }

    func test_captureFails_showsError_allowsRetry() async {
        // Given
        await cameraViewModel.setupCamera()
        mockCameraService.captureShouldThrow = true

        // When - First attempt fails
        await cameraViewModel.captureAndClassify()

        // Then
        XCTAssertNotNil(cameraViewModel.errorMessage)
        XCTAssertNil(cameraViewModel.classifications)

        // When - Fix and retry
        mockCameraService.captureShouldThrow = false
        mockClassifier.resultsToReturn = [Classification(label: "Model A", confidence: 0.85)]
        await cameraViewModel.captureAndClassify()

        // Then - Success
        XCTAssertNil(cameraViewModel.errorMessage)
        XCTAssertNotNil(cameraViewModel.classifications)
    }

    func test_classificationFails_showsError() async {
        // Given
        await cameraViewModel.setupCamera()
        mockClassifier.shouldThrowError = true

        // When
        await cameraViewModel.captureAndClassify()

        // Then
        XCTAssertNotNil(cameraViewModel.errorMessage)
        XCTAssertNil(cameraViewModel.classifications)
        XCTAssertFalse(cameraViewModel.showResults)
    }

    // MARK: - Method Call Order Verification

    func test_verifyMethodCallOrder() async {
        // Given
        let spyService = SpyCameraService(authorizationResult: true)
        let viewModel = CameraViewModel(
            classifier: mockClassifier,
            cameraServiceFactory: { spyService }
        )
        mockClassifier.resultsToReturn = [Classification(label: "Model A", confidence: 0.85)]

        // When
        await viewModel.setupCamera()
        await viewModel.captureAndClassify()

        // Then - Verify correct call order
        XCTAssertTrue(spyService.verifyCallOrder([
            "checkAuthorization",
            "setupSession",
            "startSession",
            "capturePhoto",
        ]))
    }

    // MARK: - Results View Model Integration

    func test_resultsViewModel_integrationWithCameraViewModel() async {
        // Given
        let classifications = [
            Classification(label: "Medtronic Azure XT DR", confidence: 0.92),
            Classification(label: "Boston Scientific Accolade MRI", confidence: 0.05),
            Classification(label: "Abbott Ellipse VR", confidence: 0.03),
        ]
        mockClassifier.resultsToReturn = classifications
        await cameraViewModel.setupCamera()

        // When
        await cameraViewModel.captureAndClassify()
        resultsViewModel = ResultsViewModel(classifications: cameraViewModel.classifications!)

        // Then - Results view model correctly processes classifications
        XCTAssertEqual(resultsViewModel.topResult?.label, "Medtronic Azure XT DR")
        XCTAssertNotNil(resultsViewModel.topResult)
        XCTAssertEqual(resultsViewModel.topResult!.confidence, 0.92, accuracy: 0.001)
        XCTAssertTrue(resultsViewModel.hasHighConfidenceResult)
        XCTAssertEqual(resultsViewModel.confidenceLevel, "Very High")
        XCTAssertEqual(resultsViewModel.topResults(2).count, 2)
    }

    // MARK: - Timing and Performance

    func test_captureAndClassify_completesInReasonableTime() async {
        // Given
        await cameraViewModel.setupCamera()
        mockClassifier.delayNanoseconds = 100_000_000 // 100ms
        mockClassifier.resultsToReturn = [Classification(label: "Model A", confidence: 0.85)]

        let startTime = Date()

        // When
        await cameraViewModel.captureAndClassify()

        // Then - Should complete within reasonable time
        let duration = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 0.5, "Operation should complete within 500ms")
        XCTAssertNotNil(cameraViewModel.classifications)
    }
}
