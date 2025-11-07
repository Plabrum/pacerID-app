# PacemakerID - Quick Start

Get up and running in 60 seconds.

## Prerequisites

- macOS with Xcode 15.0+
- Homebrew installed
- iOS device with camera (for full testing)

## Steps

### 1. Clone or Navigate to Project

```bash
cd /Users/phil/repos/pacerID-app
```

### 2. Generate & Open

```bash
# One command does it all
make open
```

This will:
- Install XcodeGen if needed
- Generate `PacemakerID.xcodeproj`
- Open the project in Xcode

### 3. Configure Signing

In Xcode:
1. Select **PacemakerID** project in Navigator
2. Select **PacemakerID** target
3. Go to **Signing & Capabilities**
4. Select your **Team**

### 4. Build & Run

1. Connect your iOS device (or select a Simulator)
2. Press **⌘R** to build and run
3. Allow camera access when prompted
4. Point camera at any image
5. Tap capture button
6. View mock classification results

## Alternative: Command Line Build

```bash
# Build for Simulator
make build

# Just generate project (without opening)
make generate

# Clean build artifacts
make clean
```

## Project Management

### Adding New Files

Just create the file in the appropriate folder:

```bash
touch PacemakerID/Services/RealClassifier.swift
make generate
```

XcodeGen automatically detects and includes it!

### Changing Settings

Edit `project.yml` then regenerate:

```bash
vim project.yml
make generate
```

### Daily Workflow

```bash
git pull              # Get latest changes
make generate         # Regenerate if project.yml changed
make open             # Open in Xcode
# ... code, test, commit ...
```

## Key Commands

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make open` | Generate & open in Xcode |
| `make build` | Build for Simulator |
| `make clean` | Clean build artifacts |
| `xcodegen generate` | Generate project manually |

## What's Created

```
PacemakerID.xcodeproj/    ← Generated (ignored by git)
project.yml               ← Source of truth
PacemakerID/             ← Your source code
  ├── Models/
  ├── Protocols/
  ├── Services/
  ├── ViewModels/
  └── Views/
```

## Need Help?

- **XcodeGen Details**: See [XCODEGEN_SETUP.md](XCODEGEN_SETUP.md)
- **Manual Setup**: See [SETUP_GUIDE.md](SETUP_GUIDE.md)
- **Architecture**: See [README.md](README.md)
- **Implementation**: See [IMPLEMENTATION_NOTES.md](IMPLEMENTATION_NOTES.md)

## Integrating Your ML Model

Replace mock classifier in `PacemakerIDApp.swift`:

```swift
// Change this:
private let classifier: PacemakerClassifier = MockPacemakerClassifier()

// To this:
private let classifier: PacemakerClassifier = YourProductionClassifier()
```

Your classifier must implement the `PacemakerClassifier` protocol.

## Testing Without Device

The mock classifier works in Simulator, but:
- Camera preview won't show (AVFoundation limitation)
- Photo capture will fail
- You can test UI components in SwiftUI Previews

## Common Issues

### "xcodegen: command not found"

```bash
brew install xcodegen
```

### "No such file or directory"

Make sure you're in the project directory:

```bash
cd /Users/phil/repos/pacerID-app
```

### Camera doesn't work

- Must use physical device (Simulator doesn't support camera capture)
- Check Settings > Privacy > Camera permissions

### Build fails

```bash
make clean
make generate
# Try building again in Xcode
```

---

**That's it!** You're ready to develop. Happy coding! 🚀
