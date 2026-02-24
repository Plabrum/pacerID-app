# PacerID - Implementation Notes

Technical details and code reference for developers.

## Core Architecture

### Protocol-Based Design

The app uses protocol-based dependency injection for testability and flexibility:

```swift
protocol PacemakerClassifier {
    func classify(image: CGImage) async throws -> [Classification]
}
```

This allows swapping between:
- `MockPacemakerClassifier` (for testing/demo)
- Production ML classifier (CoreML, TensorFlow Lite, etc.)

### Async/Await Throughout

Modern Swift concurrency is used consistently:

```swift
// Camera capture
let image = try await cameraService.capturePhoto()

// Classification
let results = try await classifier.classify(image: image)
```

### @MainActor for UI

All view models and camera service are `@MainActor` to ensure UI updates on main thread:

```swift
@MainActor
final class CameraViewModel: ObservableObject {
    // All published properties automatically on main thread
}
```

## Key Components

### 1. CameraService

**Responsibilities:**
- Manages `AVCaptureSession` lifecycle
- Handles camera permissions
- Captures photos as `CGImage`

**Key Methods:**
```swift
func checkAuthorization() async
func setupSession() async throws
func startSession()
func stopSession()
func capturePhoto() async throws -> CGImage
```

**Error Handling:**
```swift
enum CameraError: LocalizedError {
    case notAuthorized
    case noCameraAvailable
    case cannotAddInput
    case cannotAddOutput
    case sessionNotRunning
    case captureFailed(Error)
    case invalidImageData
    case unknown
}
```

### 2. CameraPreviewRepresentable

**Purpose:** Bridges UIKit's `AVCaptureVideoPreviewLayer` to SwiftUI

**Implementation Pattern:**
```swift
struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewView
    func updateUIView(_ uiView: CameraPreviewView, context: Context)
}
```

**Why UIViewRepresentable:**
- AVFoundation preview requires UIKit
- SwiftUI has no native camera preview
- This pattern is Apple's recommended approach

### 3. CameraViewModel

**Responsibilities:**
- Coordinates camera, classification, and navigation
- Manages app state and errors
- Provides data binding for UI

**State Properties:**
```swift
@Published var cameraService: CameraService
@Published var isProcessing: Bool
@Published var classifications: [Classification]?
@Published var showResults: Bool
@Published var errorMessage: String?
```

**Flow:**
```
1. setupCamera() → check permissions → start session
2. captureAndClassify() → capture → classify → navigate to results
3. dismissResults() → reset state → return to camera
```

### 4. Classification Model

Simple, immutable data structure:

```swift
struct Classification: Identifiable, Equatable {
    let id: UUID
    let label: String        // "Medtronic Azure XT DR"
    let confidence: Double   // 0.0 to 1.0

    var confidencePercentage: String // "87.3%"
}
```

**Design Choices:**
- `Identifiable` for SwiftUI `ForEach`
- `Equatable` for state comparison
- Computed properties for formatting
- Immutable for thread safety

## UI Components

### CaptureButton

Mimics iOS Camera app design:

```swift
struct CaptureButton: View {
    let action: () -> Void
    let isProcessing: Bool

    // Shows white circle or progress indicator
}
```

**Visual States:**
- Normal: White circle with stroke
- Processing: Loading spinner

### ProbabilityBar

Horizontal bar chart with label and percentage:

```swift
struct ProbabilityBar: View {
    let classification: Classification
    let isTopResult: Bool

    // Dynamic width based on confidence
    // Color based on confidence level
}
```

**Color Coding:**
- Green: High confidence (≥70%)
- Orange: Moderate (50-70%)
- Gray: Low (<50%)

## Navigation Flow

```
CameraView (NavigationStack root)
    ↓ (capture button tapped)
    ↓ (captureAndClassify())
    ↓ (showResults = true)
ResultsView (navigationDestination)
    ↓ (Done button)
    ↓ (onDismiss())
CameraView (return)
```

**Implementation:**
```swift
.navigationDestination(isPresented: $viewModel.showResults) {
    if let classifications = viewModel.classifications {
        ResultsView(...)
    }
}
```

## Lifecycle Management

### Camera Session

```swift
CameraView
    .task {
        await viewModel.setupCamera()  // on appear
    }
    .onDisappear {
        viewModel.cleanup()            // stop session
    }
```

**Why This Matters:**
- Saves battery
- Releases camera hardware
- Proper resource management

### View Model Initialization

```swift
@StateObject var viewModel: CameraViewModel

// In parent:
CameraView(viewModel: CameraViewModel(classifier: classifier))
```

**@StateObject ensures:**
- View model survives view updates
- Single source of truth
- Proper memory management

## Accessibility

### VoiceOver Support

Every interactive element has accessibility labels:

```swift
.accessibilityLabel("Capture photo")
.accessibilityHint("Takes a photo of the X-ray for pacemaker identification")
```

### Semantic Colors

All colors use system semantic colors:
- `.primary`, `.secondary` (adapt to dark mode)
- `.white`, `.black` (when specifically needed)
- Color coding has non-color alternatives (icons, text)

### Dynamic Type

Text automatically scales with user's preferred size:
```swift
.font(.headline)  // System font, scales automatically
```

## Error Handling Strategy

### Graceful Degradation

```swift
do {
    let image = try await cameraService.capturePhoto()
    let results = try await classifier.classify(image: image)
    // Success path
} catch {
    // Show error, but don't crash
    errorMessage = error.localizedDescription
}
```

### User-Facing Errors

All errors implement `LocalizedError`:
```swift
var errorDescription: String? {
    "Camera access is not authorized. Please enable in Settings."
}
```

### Error Display

```swift
if let errorMessage = viewModel.errorMessage {
    Text(errorMessage)
        .foregroundColor(.white)
        .background(Color.red.opacity(0.8))
}
```

## Testing Strategy

### Mock Classifier

`MockPacemakerClassifier` provides realistic test data:

```swift
func classify(image: CGImage) async throws -> [Classification] {
    try await Task.sleep(nanoseconds: 500_000_000)  // Simulate delay
    return generateRealisticResults()
}
```

**Benefits:**
- Test without ML model
- Predictable results
- Adjustable for edge cases

### Preview Providers

All views have SwiftUI previews:

```swift
#Preview {
    CameraView(viewModel: CameraViewModel(classifier: MockPacemakerClassifier()))
}
```

**Fast Iteration:**
- See changes instantly
- No device deployment
- Multiple states in one preview

## Integration Points

### Adding Production Classifier

Replace mock in `PacerIDApp.swift`:

```swift
// Replace this:
private let classifier: PacemakerClassifier = MockPacemakerClassifier()

// With your implementation:
private let classifier: PacemakerClassifier = ProductionClassifier()
```

### Production Classifier Template

```swift
import CoreML
import Vision

final class ProductionClassifier: PacemakerClassifier {
    private let model: VNCoreMLModel

    init() throws {
        let config = MLModelConfiguration()
        let mlModel = try YourMLModel(configuration: config).model
        model = try VNCoreMLModel(for: mlModel)
    }

    func classify(image: CGImage) async throws -> [Classification] {
        let request = VNCoreMLRequest(model: model)
        let handler = VNImageRequestHandler(cgImage: image)

        try handler.perform([request])

        guard let results = request.results as? [VNClassificationObservation] else {
            throw ClassificationError.classificationFailed
        }

        return results.map { observation in
            Classification(
                label: observation.identifier,
                confidence: Double(observation.confidence)
            )
        }
        .sorted { $0.confidence > $1.confidence }
    }
}
```

## Performance Considerations

### Camera Preview

- Preview layer runs on separate queue
- No impact on main thread
- Hardware-accelerated

### Image Processing

```swift
// CGImage is efficient
let image = try await cameraService.capturePhoto()

// No unnecessary conversions
// Pass directly to classifier
```

### Memory Management

- Images not retained after classification
- Camera session stopped when not visible
- No caching or storage

## Privacy & Security

### No Network

- All processing on-device
- No API calls
- No analytics

### No Storage

- Images not saved to Photos
- No temporary files
- No caching

### Permissions

- Camera only when needed
- Clear usage description
- Graceful handling of denial

## Common Customizations

### Change Confidence Threshold

In `ResultsViewModel.swift`:

```swift
var confidenceLevel: String {
    guard let confidence = topResult?.confidence else { return "Unknown" }

    switch confidence {
    case 0.9...:        // Adjust these thresholds
        return "Very High"
    case 0.7..<0.9:     // Adjust these thresholds
        return "High"
    // ...
    }
}
```

### Add Pacemaker Models

In `MockPacemakerClassifier.swift`:

```swift
private let pacemakerModels = [
    "Your New Model",
    "Another Model",
    // ... existing models
]
```

### Customize UI Colors

In `ProbabilityBar.swift`:

```swift
private var barColor: Color {
    switch classification.confidence {
    case 0.7...:
        return .green  // Change to .blue, etc.
    // ...
    }
}
```

## Code Quality Standards

### SwiftLint Friendly

Code follows standard Swift style:
- 4 spaces indentation
- `self` only when required
- Clear naming conventions
- Short, focused functions

### No Warnings

- All force-unwraps avoided
- Optional handling explicit
- Deprecated APIs avoided
- All cases handled in switches

### Documentation

All public APIs documented:
```swift
/// Classifies an image and returns pacemaker brands/models
/// - Parameter image: The CGImage to classify
/// - Returns: Array of Classifications sorted by confidence
func classify(image: CGImage) async throws -> [Classification]
```

## File Organization

```
Models/         → Data structures
Protocols/      → Interfaces
Services/       → Business logic, system integration
ViewModels/     → UI state & coordination
Views/          → SwiftUI components
  Components/   → Reusable UI elements
```

**Benefits:**
- Clear separation of concerns
- Easy to navigate
- Scalable structure
- Testable components

---

## Quick Reference

### Starting Development

1. Open project in Xcode
2. Build (⌘B)
3. Run on device (⌘R)
4. Edit files
5. See changes immediately

### Adding Features

1. Determine layer (Model/Service/ViewModel/View)
2. Create new file in appropriate folder
3. Add to project target
4. Import in consuming files
5. Update relevant view models

### Debugging Camera Issues

```swift
// Add breakpoint in CameraService:
func capturePhoto() async throws -> CGImage {
    // Check if session is running
    print("Session running: \(isSessionRunning)")
    // ...
}
```

### Testing Without Device

Use previews for UI:
```swift
#Preview {
    CameraView(viewModel: CameraViewModel(
        classifier: MockPacemakerClassifier()
    ))
}
```

---

**Ready to extend!** The architecture supports adding features like:
- Image history
- Export results
- Multiple camera modes
- Batch processing
- Custom ML models
