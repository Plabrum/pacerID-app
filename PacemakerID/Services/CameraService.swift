import AVFoundation
import UIKit

/// Service for managing camera capture session
@MainActor
final class CameraService: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var error: CameraError?

    // MARK: - Private Properties

    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var photoContinuation: CheckedContinuation<CGImage, Error>?

    // MARK: - Public Properties

    var session: AVCaptureSession { captureSession }

    // MARK: - Initialization

    override init() {
        super.init()
    }

    // MARK: - Authorization

    func checkAuthorization() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            isAuthorized = false
            error = .notAuthorized
        @unknown default:
            isAuthorized = false
            error = .unknown
        }
    }

    // MARK: - Session Setup

    func setupSession() async throws {
        guard isAuthorized else {
            throw CameraError.notAuthorized
        }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        // Add video input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            captureSession.commitConfiguration()
            throw CameraError.noCameraAvailable
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: camera)
            guard captureSession.canAddInput(videoInput) else {
                captureSession.commitConfiguration()
                throw CameraError.cannotAddInput
            }
            captureSession.addInput(videoInput)
        } catch {
            captureSession.commitConfiguration()
            throw CameraError.cannotAddInput
        }

        // Add photo output
        guard captureSession.canAddOutput(photoOutput) else {
            captureSession.commitConfiguration()
            throw CameraError.cannotAddOutput
        }
        captureSession.addOutput(photoOutput)

        captureSession.commitConfiguration()
    }

    // MARK: - Session Control

    func startSession() {
        guard !isSessionRunning else { return }
        Task {
            captureSession.startRunning()
            await MainActor.run {
                isSessionRunning = captureSession.isRunning
            }
        }
    }

    func stopSession() {
        guard isSessionRunning else { return }
        Task {
            captureSession.stopRunning()
            await MainActor.run {
                isSessionRunning = false
            }
        }
    }

    // MARK: - Photo Capture

    func capturePhoto() async throws -> CGImage {
        guard isSessionRunning else {
            throw CameraError.sessionNotRunning
        }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off

        return try await withCheckedThrowingContinuation { continuation in
            self.photoContinuation = continuation
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                photoContinuation?.resume(throwing: CameraError.captureFailed(error))
                return
            }

            guard let imageData = photo.fileDataRepresentation(),
                  let uiImage = UIImage(data: imageData),
                  let cgImage = uiImage.cgImage
            else {
                photoContinuation?.resume(throwing: CameraError.invalidImageData)
                return
            }

            photoContinuation?.resume(returning: cgImage)
        }
    }
}

// MARK: - Camera Errors

enum CameraError: LocalizedError {
    case notAuthorized
    case noCameraAvailable
    case cannotAddInput
    case cannotAddOutput
    case sessionNotRunning
    case captureFailed(Error)
    case invalidImageData
    case unknown

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            "Camera access is not authorized. Please enable camera access in Settings."
        case .noCameraAvailable:
            "No camera is available on this device."
        case .cannotAddInput:
            "Cannot configure camera input."
        case .cannotAddOutput:
            "Cannot configure camera output."
        case .sessionNotRunning:
            "Camera session is not running."
        case let .captureFailed(error):
            "Failed to capture photo: \(error.localizedDescription)"
        case .invalidImageData:
            "Captured image data is invalid."
        case .unknown:
            "An unknown camera error occurred."
        }
    }
}
