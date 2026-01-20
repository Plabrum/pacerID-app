import AVFoundation
import CoreGraphics
import SwiftUI
import UIKit

/// Mock implementation of CameraServiceProtocol for testing
/// Simulates camera behavior without requiring actual hardware
@MainActor
final class MockCameraService: ObservableObject, CameraServiceProtocol {
    // MARK: - Published Properties

    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var error: CameraError?

    // MARK: - Configuration

    /// Controls authorization check result
    var authorizationResult = true

    /// If true, setupSession() will throw an error
    var setupShouldThrow = false

    /// Error to throw during setup
    var setupError: CameraError = .cannotAddInput

    /// If true, startSession() will set isSessionRunning to false
    var startShouldFail = false

    /// If true, capturePhoto() will throw an error
    var captureShouldThrow = false

    /// Error to throw during capture
    var captureError: CameraError = .captureFailed(NSError(domain: "test", code: -1))

    /// Delay in nanoseconds for async operations (default: 10ms for fast tests)
    var operationDelayNanoseconds: UInt64 = 10_000_000

    /// Test image to return from capturePhoto()
    var testImage: CGImage?

    // MARK: - Call Tracking

    private(set) var checkAuthorizationCallCount = 0
    private(set) var setupSessionCallCount = 0
    private(set) var startSessionCallCount = 0
    private(set) var stopSessionCallCount = 0
    private(set) var capturePhotoCallCount = 0

    // MARK: - Protocol Properties

    /// Mock doesn't provide a real AVCaptureSession
    var session: AVCaptureSession? { nil }

    // MARK: - Initialization

    init(
        authorizationResult: Bool = true,
        setupShouldThrow: Bool = false,
        captureShouldThrow: Bool = false
    ) {
        self.authorizationResult = authorizationResult
        self.setupShouldThrow = setupShouldThrow
        self.captureShouldThrow = captureShouldThrow
        self.testImage = Self.createDefaultTestImage()
    }

    // MARK: - CameraServiceProtocol

    func checkAuthorization() async {
        checkAuthorizationCallCount += 1

        if operationDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: operationDelayNanoseconds)
        }

        isAuthorized = authorizationResult

        if !authorizationResult {
            error = .notAuthorized
        }
    }

    func setupSession() async throws {
        setupSessionCallCount += 1

        if operationDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: operationDelayNanoseconds)
        }

        guard isAuthorized else {
            throw CameraError.notAuthorized
        }

        if setupShouldThrow {
            throw setupError
        }
    }

    func startSession() async {
        startSessionCallCount += 1

        if operationDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: operationDelayNanoseconds)
        }

        if !startShouldFail {
            isSessionRunning = true
        }
    }

    func stopSession() async {
        stopSessionCallCount += 1

        if operationDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: operationDelayNanoseconds)
        }

        isSessionRunning = false
    }

    func capturePhoto() async throws -> CGImage {
        capturePhotoCallCount += 1

        if operationDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: operationDelayNanoseconds)
        }

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

    // MARK: - Test Helpers

    /// Resets all call counters and state
    func reset() {
        checkAuthorizationCallCount = 0
        setupSessionCallCount = 0
        startSessionCallCount = 0
        stopSessionCallCount = 0
        capturePhotoCallCount = 0

        isAuthorized = false
        isSessionRunning = false
        error = nil

        authorizationResult = true
        setupShouldThrow = false
        startShouldFail = false
        captureShouldThrow = false
    }

    /// Creates a simple test image
    static func createDefaultTestImage() -> CGImage? {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.cgImage
    }

    /// Creates a colored test image for testing
    static func createTestImage(color: UIColor, size: CGSize = CGSize(width: 100, height: 100)) -> CGImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.cgImage
    }
}
