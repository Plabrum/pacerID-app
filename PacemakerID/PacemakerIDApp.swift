import SwiftUI

@main
struct PacemakerIDApp: App {
    // MARK: - Dependencies

    @StateObject private var dependencies = AppDependencies.shared

    var body: some Scene {
        WindowGroup {
            LandingView(classifier: dependencies.classifier)
                .environment(\.appDependencies, dependencies)
        }
    }
}
