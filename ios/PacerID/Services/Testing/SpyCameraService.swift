import AVFoundation
import CoreGraphics
import SwiftUI

/// Spy implementation of CameraServiceProtocol for verifying method calls and call order
/// Useful for testing that ViewModels call camera methods in the correct sequence
@MainActor
final class SpyCameraService: ObservableObject, CameraServiceProtocol {
    // MARK: - Published Properties

    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var error: CameraError?

    // MARK: - Call Tracking

    /// Records all method calls in order
    private(set) var methodCalls: [String] = []

    /// Stores arguments passed to methods
    private(set) var callArguments: [String: Any] = [:]

    // MARK: - Configuration

    /// Controls behavior of each method
    var authorizationResult = true
    var setupShouldThrow = false
    var setupError: CameraError = .cannotAddInput
    var captureShouldThrow = false
    var captureError: CameraError = .invalidImageData

    /// Test image to return from capturePhoto
    var testImage: CGImage?

    // MARK: - Protocol Properties

    var session: AVCaptureSession? { nil }

    // MARK: - Initialization

    init(
        authorizationResult: Bool = true,
        testImage: CGImage? = nil
    ) {
        self.authorizationResult = authorizationResult
        self.testImage = testImage ?? MockCameraService.createDefaultTestImage()
    }

    // MARK: - CameraServiceProtocol

    func checkAuthorization() async {
        methodCalls.append("checkAuthorization")
        isAuthorized = authorizationResult

        if !authorizationResult {
            error = .notAuthorized
        }
    }

    func setupSession() async throws {
        methodCalls.append("setupSession")

        guard isAuthorized else {
            throw CameraError.notAuthorized
        }

        if setupShouldThrow {
            throw setupError
        }
    }

    func startSession() async {
        methodCalls.append("startSession")
        isSessionRunning = true
    }

    func stopSession() async {
        methodCalls.append("stopSession")
        isSessionRunning = false
    }

    func capturePhoto() async throws -> CGImage {
        methodCalls.append("capturePhoto")

        guard isSessionRunning else {
            throw CameraError.sessionNotRunning
        }

        if captureShouldThrow {
            throw captureError
        }

        guard let image = testImage else {
            throw CameraError.invalidImageData
        }

        return image
    }

    // MARK: - Verification Methods

    /// Checks if a method was called a specific number of times
    func verifyMethodCalled(_ method: String, times: Int) -> Bool {
        methodCalls.filter { $0 == method }.count == times
    }

    /// Checks if a method was called at least once
    func verifyMethodCalled(_ method: String) -> Bool {
        methodCalls.contains(method)
    }

    /// Verifies methods were called in the expected order
    func verifyCallOrder(_ expectedOrder: [String]) -> Bool {
        guard methodCalls.count >= expectedOrder.count else {
            return false
        }

        for (index, expectedMethod) in expectedOrder.enumerated() where methodCalls[index] != expectedMethod {
            return false
        }

        return true
    }

    /// Returns the number of times a method was called
    func callCount(for method: String) -> Int {
        methodCalls.filter { $0 == method }.count
    }

    /// Clears all recorded calls
    func reset() {
        methodCalls.removeAll()
        callArguments.removeAll()
        isAuthorized = false
        isSessionRunning = false
        error = nil
    }
}
