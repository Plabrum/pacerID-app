import CoreGraphics
@testable import PacerID
import XCTest

/// Integration tests for the gallery → image loading → classify → results flow
@MainActor
final class GalleryToClassificationFlowTests: XCTestCase {
    var mockClassifier: ConfigurableMockPacemakerClassifier!
    var imageClassificationViewModel: ImageClassificationViewModel!
    var resultsViewModel: ResultsViewModel!
    var testImage: CGImage!

    override func setUp() {
        super.setUp()
        testImage = TestHelpers.createTestImage(size: CGSize(width: 200, height: 200))
        mockClassifier = ConfigurableMockPacemakerClassifier(delayNanoseconds: 10_000_000)
        imageClassificationViewModel = ImageClassificationViewModel(
            classifier: mockClassifier,
            image: testImage!
        )
    }

    override func tearDown() {
        imageClassificationViewModel = nil
        mockClassifier = nil
        resultsViewModel = nil
        testImage = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func test_fullGalleryFlow_happyPath() async {
        // Given
        let expectedClassifications = [
            Classification(label: "Medtronic Azure XT DR", confidence: 0.91),
            Classification(label: "Boston Scientific Accolade MRI", confidence: 0.06),
            Classification(label: "Abbott Ellipse VR", confidence: 0.03),
        ]
        mockClassifier.resultsToReturn = expectedClassifications

        // When - Step 1: Classify the image
        await imageClassificationViewModel.classify()

        // Then - Classifications are set
        XCTAssertEqual(imageClassificationViewModel.classifications, expectedClassifications)
        XCTAssertTrue(imageClassificationViewModel.showResults)
        XCTAssertNil(imageClassificationViewModel.errorMessage)
        XCTAssertFalse(imageClassificationViewModel.isProcessing)

        // When - Step 2: Create results view model
        resultsViewModel = ResultsViewModel(classifications: imageClassificationViewModel.classifications!)

        // Then - Results view model has correct data
        XCTAssertEqual(resultsViewModel.topResult?.label, "Medtronic Azure XT DR")
        XCTAssertTrue(resultsViewModel.hasHighConfidenceResult)
        XCTAssertEqual(resultsViewModel.confidenceLevel, "Very High")

        // When - Step 3: Dismiss results
        imageClassificationViewModel.dismissResults()

        // Then - Results cleared
        XCTAssertNil(imageClassificationViewModel.classifications)
        XCTAssertFalse(imageClassificationViewModel.showResults)
    }

    func test_galleryFlow_withDifferentImageSizes() async {
        // Test with small image
        let smallImage = TestHelpers.createTestImage(size: CGSize(width: 50, height: 50))
        var viewModel = ImageClassificationViewModel(classifier: mockClassifier, image: smallImage!)
        mockClassifier.resultsToReturn = [Classification(label: "Model A", confidence: 0.85)]

        await viewModel.classify()
        XCTAssertNotNil(viewModel.classifications)

        // Test with large image
        let largeImage = TestHelpers.createTestImage(size: CGSize(width: 1000, height: 1000))
        viewModel = ImageClassificationViewModel(classifier: mockClassifier, image: largeImage!)
        mockClassifier.reset()
        mockClassifier.resultsToReturn = [Classification(label: "Model B", confidence: 0.82)]

        await viewModel.classify()
        XCTAssertNotNil(viewModel.classifications)
    }

    // MARK: - Error Path Tests

    func test_classificationFails_showsError() async {
        // Given
        mockClassifier.shouldThrowError = true

        // When
        await imageClassificationViewModel.classify()

        // Then
        XCTAssertNil(imageClassificationViewModel.classifications)
        XCTAssertFalse(imageClassificationViewModel.showResults)
        XCTAssertNotNil(imageClassificationViewModel.errorMessage)
    }

    func test_classificationFails_allowsRetry() async {
        // Given
        mockClassifier.shouldThrowError = true

        // When - First attempt fails
        await imageClassificationViewModel.classify()

        // Then
        XCTAssertNotNil(imageClassificationViewModel.errorMessage)
        XCTAssertNil(imageClassificationViewModel.classifications)

        // When - Fix and retry
        mockClassifier.shouldThrowError = false
        mockClassifier.resultsToReturn = [Classification(label: "Model A", confidence: 0.88)]
        await imageClassificationViewModel.classify()

        // Then - Success
        XCTAssertNil(imageClassificationViewModel.errorMessage)
        XCTAssertNotNil(imageClassificationViewModel.classifications)
        XCTAssertTrue(imageClassificationViewModel.showResults)
    }

    // MARK: - Results View Model Integration

    func test_resultsViewModel_integrationWithImageClassificationViewModel() async {
        // Given
        let classifications = [
            Classification(label: "Biotronik Eluna 8 DR-T", confidence: 0.94),
            Classification(label: "Medtronic Azure XT DR", confidence: 0.04),
            Classification(label: "Abbott Ellipse VR", confidence: 0.02),
        ]
        mockClassifier.resultsToReturn = classifications

        // When
        await imageClassificationViewModel.classify()
        resultsViewModel = ResultsViewModel(classifications: imageClassificationViewModel.classifications!)

        // Then - Results view model correctly processes classifications
        XCTAssertEqual(resultsViewModel.topResult?.label, "Biotronik Eluna 8 DR-T")
        XCTAssertNotNil(resultsViewModel.topResult)
        XCTAssertEqual(resultsViewModel.topResult!.confidence, 0.94, accuracy: 0.001)
        XCTAssertTrue(resultsViewModel.hasHighConfidenceResult)
        XCTAssertEqual(resultsViewModel.confidenceLevel, "Very High")
        XCTAssertEqual(resultsViewModel.topResults(3).count, 3)
    }

    // MARK: - Multiple Classifications

    func test_multipleClassifications_withSameImage() async {
        // Given
        let firstResults = [Classification(label: "Model A", confidence: 0.85)]
        let secondResults = [Classification(label: "Model B", confidence: 0.92)]

        // When - First classification
        mockClassifier.resultsToReturn = firstResults
        await imageClassificationViewModel.classify()

        // Then
        XCTAssertEqual(imageClassificationViewModel.classifications, firstResults)

        // When - Dismiss and classify again
        imageClassificationViewModel.dismissResults()
        mockClassifier.resultsToReturn = secondResults
        await imageClassificationViewModel.classify()

        // Then - New results
        XCTAssertEqual(imageClassificationViewModel.classifications, secondResults)
        XCTAssertEqual(mockClassifier.classifyCallCount, 2)
    }

    func test_multipleImages_sequential() async {
        // Given - First image
        mockClassifier.resultsToReturn = [Classification(label: "Model A", confidence: 0.85)]
        await imageClassificationViewModel.classify()
        XCTAssertEqual(imageClassificationViewModel.classifications?.first?.label, "Model A")

        // When - New image
        let newImage = TestHelpers.createTestImage(size: CGSize(width: 150, height: 150))
        imageClassificationViewModel = ImageClassificationViewModel(
            classifier: mockClassifier,
            image: newImage!
        )
        mockClassifier.reset()
        mockClassifier.resultsToReturn = [Classification(label: "Model B", confidence: 0.90)]

        // When
        await imageClassificationViewModel.classify()

        // Then
        XCTAssertEqual(imageClassificationViewModel.classifications?.first?.label, "Model B")
        XCTAssertEqual(mockClassifier.classifyCallCount, 1) // Reset was called
    }

    // MARK: - Timing and Performance

    func test_classify_completesInReasonableTime() async {
        // Given
        mockClassifier.delayNanoseconds = 100_000_000 // 100ms
        mockClassifier.resultsToReturn = [Classification(label: "Model A", confidence: 0.85)]

        let startTime = Date()

        // When
        await imageClassificationViewModel.classify()

        // Then - Should complete within reasonable time
        let duration = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 0.5, "Operation should complete within 500ms")
        XCTAssertNotNil(imageClassificationViewModel.classifications)
    }

    // MARK: - State Management

    func test_viewModel_maintainsCorrectState_throughFlow() async {
        // Given
        mockClassifier.resultsToReturn = [Classification(label: "Model A", confidence: 0.87)]

        // Initial state
        XCTAssertFalse(imageClassificationViewModel.isProcessing)
        XCTAssertNil(imageClassificationViewModel.classifications)
        XCTAssertFalse(imageClassificationViewModel.showResults)

        // When - Classify
        await imageClassificationViewModel.classify()

        // State after classification
        XCTAssertFalse(imageClassificationViewModel.isProcessing)
        XCTAssertNotNil(imageClassificationViewModel.classifications)
        XCTAssertTrue(imageClassificationViewModel.showResults)

        // When - Dismiss
        imageClassificationViewModel.dismissResults()

        // State after dismiss
        XCTAssertFalse(imageClassificationViewModel.isProcessing)
        XCTAssertNil(imageClassificationViewModel.classifications)
        XCTAssertFalse(imageClassificationViewModel.showResults)
    }

    // MARK: - Comparison with Camera Flow

    func test_galleryFlow_producesConsistentResults_withCameraFlow() async {
        // Given - Same test image and classifier config
        let sharedClassifications = [Classification(label: "Shared Model", confidence: 0.88)]
        mockClassifier.resultsToReturn = sharedClassifications

        // When - Gallery flow
        await imageClassificationViewModel.classify()
        let galleryResults = imageClassificationViewModel.classifications

        // When - Camera flow simulation
        let mockCameraService = MockCameraService()
        mockCameraService.testImage = testImage
        mockCameraService.isSessionRunning = true

        let cameraViewModel = CameraViewModel(
            classifier: mockClassifier,
            cameraServiceFactory: { mockCameraService }
        )

        mockClassifier.reset()
        mockClassifier.resultsToReturn = sharedClassifications
        await cameraViewModel.captureAndClassify()
        let cameraResults = cameraViewModel.classifications

        // Then - Both flows produce same results
        XCTAssertEqual(galleryResults, cameraResults)
    }
}
