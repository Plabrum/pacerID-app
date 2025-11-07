import SwiftUI

@main
struct PacemakerIDApp: App {
    // MARK: - Dependencies

    // Use mock classifier for demo; replace with actual classifier in production
    private let classifier: PacemakerClassifier = MockPacemakerClassifier()

    var body: some Scene {
        WindowGroup {
            CameraView(viewModel: CameraViewModel(classifier: classifier))
        }
    }
}
