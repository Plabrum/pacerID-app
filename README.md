# PacemakerID

An iOS app that uses the device camera to photograph X-rays and identify pacemaker brands and models using machine learning.

## Overview

PacemakerID is designed for healthcare professionals to quickly identify pacemaker devices from X-ray images. The app provides:
- Live camera preview for capturing X-ray images
- On-device machine learning classification
- Confidence-ranked results display
- Privacy-first design (no network calls or data storage)

**🚀 New here?** Start with [QUICKSTART.md](QUICKSTART.md) to get running in 60 seconds!

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- Physical iOS device with camera (camera preview won't work in Simulator)

## Project Setup

### Recommended: XcodeGen (Simple & Version Control Friendly)

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from `project.yml`:

```bash
# Quick Start (using Makefile)
make open           # Installs xcodegen if needed, generates project, and opens Xcode

# OR Manual Commands
brew install xcodegen
xcodegen generate
open PacemakerID.xcodeproj
```

**Benefits:**
- No merge conflicts in project files
- Project structure defined in readable YAML
- Automatic file detection
- Everyone generates the same project

📖 **See [XCODEGEN_SETUP.md](XCODEGEN_SETUP.md) for detailed XcodeGen guide**

### Alternative: Manual Xcode Project

If you prefer not to use XcodeGen, see [SETUP_GUIDE.md](SETUP_GUIDE.md) for manual setup instructions

## Code Quality & Formatting

The project includes automated linting and formatting:

```bash
# Install tools
make install-tools

# Install pre-commit hooks
make install-hooks

# Format code
make format

# Lint code
make lint
```

**Tools:**
- **SwiftLint**: Enforces Swift style and conventions (mostly defaults)
- **SwiftFormat**: Automatically formats code (mostly defaults)
- **Pre-commit Hook**: Runs checks before each commit

**Philosophy**: Minimal configuration, trust the defaults! See [LINTING_AND_FORMATTING.md](LINTING_AND_FORMATTING.md)

## Project Structure

```
PacemakerID/
├── PacemakerIDApp.swift          # App entry point
├── Info.plist                    # Camera permissions & config
├── Models/
│   └── Classification.swift      # Classification result model
├── Protocols/
│   └── PacemakerClassifier.swift # Classifier protocol
├── Services/
│   ├── CameraService.swift       # AVFoundation camera management
│   └── MockPacemakerClassifier.swift # Demo classifier
├── ViewModels/
│   ├── CameraViewModel.swift     # Camera screen logic
│   └── ResultsViewModel.swift    # Results screen logic
└── Views/
    ├── CameraView.swift          # Main camera screen
    ├── CameraPreviewRepresentable.swift # AVFoundation wrapper
    ├── ResultsView.swift         # Results display screen
    └── Components/
        ├── CaptureButton.swift   # Camera shutter button
        └── ProbabilityBar.swift  # Result confidence bars
```

## Architecture

### MVVM-Light Pattern

- **Models**: Simple data structures (`Classification`)
- **Protocols**: Define interfaces (`PacemakerClassifier`)
- **Services**: Business logic and system integration
  - `CameraService`: Manages AVFoundation capture session
  - `MockPacemakerClassifier`: Provides demo classification results
- **ViewModels**: UI state and coordination
  - `CameraViewModel`: Handles camera setup, capture, and classification
  - `ResultsViewModel`: Formats and presents results
- **Views**: SwiftUI UI components

### Key Features

1. **Protocol-Based Classifier**
   - `PacemakerClassifier` protocol allows pluggable ML models
   - Mock classifier provided for testing without real model
   - Easy to swap in production model implementation

2. **AVFoundation Integration**
   - `CameraService` manages capture session
   - `CameraPreviewRepresentable` wraps `AVCaptureVideoPreviewLayer` in SwiftUI
   - Async/await for photo capture

3. **Modern SwiftUI**
   - `@MainActor` for UI-bound view models
   - `task` modifier for lifecycle management
   - `NavigationStack` for camera → results flow
   - Full dark mode support

4. **Accessibility**
   - VoiceOver labels on all interactive elements
   - Semantic color usage
   - Dynamic type support

## Usage

### Running the App

1. Connect a physical iOS device (camera doesn't work in Simulator)
2. Select your device in Xcode
3. Build and run (⌘R)
4. Allow camera access when prompted
5. Point camera at an X-ray image
6. Tap the capture button
7. View classification results

### Integrating a Real ML Model

Replace `MockPacemakerClassifier` with your production classifier:

```swift
// In PacemakerIDApp.swift
struct PacemakerIDApp: App {
    private let classifier: PacemakerClassifier = YourProductionClassifier()

    var body: some Scene {
        WindowGroup {
            CameraView(viewModel: CameraViewModel(classifier: classifier))
        }
    }
}
```

Your classifier must conform to `PacemakerClassifier`:

```swift
final class YourProductionClassifier: PacemakerClassifier {
    func classify(image: CGImage) async throws -> [Classification] {
        // Your CoreML or other ML framework integration
        // Return results sorted by confidence (highest first)
    }
}
```

## Privacy & Security

- **On-device only**: No network calls or cloud processing
- **No storage**: Images are not saved to disk
- **Permissions**: Camera access requested with clear usage description
- **Memory**: Images released after classification

## Testing

The app includes a `MockPacemakerClassifier` that generates realistic test data:
- Random confidence scores (70-95% for top result)
- Realistic pacemaker model names from major manufacturers
- 0.5 second delay to simulate processing

## Customization

### Adding New Pacemaker Models

Edit the model list in `MockPacemakerClassifier.swift`:

```swift
private let pacemakerModels = [
    "Your New Model",
    // ... existing models
]
```

### Adjusting Confidence Thresholds

Modify the confidence color coding in `ResultsViewModel.swift` and `ProbabilityBar.swift`.

### Styling

All UI components support iOS light/dark mode automatically. Colors use semantic system colors that adapt to appearance.

## Known Limitations

- Requires physical device with camera (no Simulator support for camera capture)
- Mock classifier provides random results (replace with production model)
- Portrait orientation optimized (landscape supported but UI not optimized)

## License

Copyright 2025. All rights reserved.
