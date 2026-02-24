import SwiftUI

@main
struct PacerIDApp: App {
    // MARK: - Dependencies

    @StateObject private var dependencies = AppDependencies.shared

    var body: some Scene {
        WindowGroup {
            LandingView(classifier: dependencies.classifier)
                .environment(\.appDependencies, dependencies)
        }
    }
}
