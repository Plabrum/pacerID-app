import AVFoundation
import UIKit

/// Service for managing camera capture session
@MainActor
final class CameraService: NSObject, ObservableObject, CameraServiceProtocol {
    // MARK: - Published Properties

    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var error: CameraError?

    // MARK: - Private Properties

    private nonisolated(unsafe) let captureSession = AVCaptureSession()
    private nonisolated(unsafe) let photoOutput = AVCapturePhotoOutput()
    private var photoContinuation: CheckedContinuation<CGImage, Error>?
    private let sessionQueue = DispatchQueue(label: "com.pacerid.camera.session")

    // MARK: - Public Properties

    var session: AVCaptureSession? { captureSession }

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

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraError.unknown)
                    return
                }

                captureSession.beginConfiguration()
                captureSession.sessionPreset = .photo

                // Add video input
                guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                    captureSession.commitConfiguration()
                    continuation.resume(throwing: CameraError.noCameraAvailable)
                    return
                }

                do {
                    let videoInput = try AVCaptureDeviceInput(device: camera)
                    guard captureSession.canAddInput(videoInput) else {
                        captureSession.commitConfiguration()
                        continuation.resume(throwing: CameraError.cannotAddInput)
                        return
                    }
                    captureSession.addInput(videoInput)
                } catch {
                    captureSession.commitConfiguration()
                    continuation.resume(throwing: CameraError.cannotAddInput)
                    return
                }

                // Add photo output
                guard captureSession.canAddOutput(photoOutput) else {
                    captureSession.commitConfiguration()
                    continuation.resume(throwing: CameraError.cannotAddOutput)
                    return
                }
                captureSession.addOutput(photoOutput)

                captureSession.commitConfiguration()
                continuation.resume()
            }
        }
    }

    // MARK: - Session Control

    func startSession() async {
        guard !isSessionRunning else { return }

        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                self?.captureSession.startRunning()
                continuation.resume()
            }
        }

        isSessionRunning = captureSession.isRunning
    }

    func stopSession() async {
        guard isSessionRunning else { return }

        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                self?.captureSession.stopRunning()
                continuation.resume()
            }
        }

        isSessionRunning = false
    }

    // MARK: - Photo Capture

    func capturePhoto() async throws -> CGImage {
        guard isSessionRunning else {
            throw CameraError.sessionNotRunning
        }

        guard photoContinuation == nil else {
            throw CameraError.captureInProgress
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
        // Extract data on nonisolated context to avoid data race
        let result: Result<CGImage, Error> = if let error {
            .failure(CameraError.captureFailed(error))
        } else if let imageData = photo.fileDataRepresentation(),
                  let uiImage = UIImage(data: imageData),
                  let cgImage = uiImage.cgImage
        {
            .success(cgImage)
        } else {
            .failure(CameraError.invalidImageData)
        }

        Task { @MainActor in
            defer { photoContinuation = nil }

            switch result {
            case let .success(cgImage):
                photoContinuation?.resume(returning: cgImage)
            case let .failure(error):
                photoContinuation?.resume(throwing: error)
            }
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
    case captureInProgress
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
        case .captureInProgress:
            "A photo capture is already in progress."
        case let .captureFailed(error):
            "Failed to capture photo: \(error.localizedDescription)"
        case .invalidImageData:
            "Captured image data is invalid."
        case .unknown:
            "An unknown camera error occurred."
        }
    }
}
