# PacerID

Pacemaker identification app with on-device ML classification.

## Structure

```
pacerID-app/
├── ios/           # iOS app (SwiftUI + MVVM)
├── ml/            # ML training (PyTorch → CoreML)
│   ├── datasets/  # Training data (gitignored, add when available)
│   ├── models/    # CoreML models (versioned)
│   ├── scripts/   # Training scripts
│   └── configs/   # Training configs
└── Makefile       # Build commands
```

## Quick Start

### iOS Development
```bash
make install    # Install XcodeGen, SwiftLint, SwiftFormat
make open       # Open in Xcode
```

### ML Training
```bash
make install-ml      # Create conda environment
conda activate pacerid-ml
make train          # Train model
make export         # Export to CoreML
make sync-model VERSION=v1.0.0  # Sync to iOS
make build          # Build iOS app with new model
```

## Commands

Run `make help` to see all available commands.

## Documentation

- iOS setup: See [QUICKSTART.md](QUICKSTART.md) and [SETUP_GUIDE.md](SETUP_GUIDE.md)
- iOS-specific docs: See [ios/](ios/) directory
- Claude-specific info: See [claude.md](claude.md)

## Requirements

- **iOS**: Xcode 15+, Swift 5.9+, iOS 16.0+
- **ML**: Python 3.10+, PyTorch 2.0+, conda
