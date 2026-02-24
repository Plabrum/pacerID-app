import AVFoundation
import SwiftUI

/// Protocol for camera capture services, enabling testability through dependency injection
@MainActor
protocol CameraServiceProtocol: ObservableObject {
    // MARK: - Published Properties

    /// Whether camera access has been authorized
    var isAuthorized: Bool { get }

    /// Whether the camera session is currently running
    var isSessionRunning: Bool { get }

    /// Current camera error, if any
    var error: CameraError? { get }

    /// The underlying AVCaptureSession (optional for mock implementations)
    var session: AVCaptureSession? { get }

    // MARK: - Methods

    /// Checks and requests camera authorization
    func checkAuthorization() async

    /// Configures the camera session with input and output
    /// - Throws: CameraError if session setup fails
    func setupSession() async throws

    /// Starts the camera session
    func startSession() async

    /// Stops the camera session
    func stopSession() async

    /// Captures a photo and returns it as a CGImage
    /// - Returns: The captured image as CGImage
    /// - Throws: CameraError if capture fails
    func capturePhoto() async throws -> CGImage
}
