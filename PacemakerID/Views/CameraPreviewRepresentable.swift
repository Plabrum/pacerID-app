import AVFoundation
import SwiftUI

/// SwiftUI wrapper for AVCaptureVideoPreviewLayer
struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context _: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context _: Context) {
        uiView.session = session
    }
}

/// UIView that hosts the AVCaptureVideoPreviewLayer
final class CameraPreviewView: UIView {
    var session: AVCaptureSession? {
        didSet {
            updateSession()
        }
    }

    private var previewLayer: AVCaptureVideoPreviewLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPreviewLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPreviewLayer()
    }

    private func setupPreviewLayer() {
        let layer = AVCaptureVideoPreviewLayer()
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)
        previewLayer = layer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    private func updateSession() {
        previewLayer?.session = session
    }
}
