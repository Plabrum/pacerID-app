# Claude Code Context

## Project Structure

This is a monorepo with iOS app and ML training:

```
pacerID-app/
├── ios/              # iOS application
│   ├── PacemakerID/  # Source code (SwiftUI + MVVM)
│   ├── project.yml   # XcodeGen config
│   └── *Tests/       # Test suites
├── ml/               # ML training pipeline
│   ├── datasets/     # Training data (not in git, add externally)
│   ├── models/       # CoreML models (versioned in git)
│   ├── scripts/      # Training scripts
│   ├── configs/      # Training configs
│   └── src/          # Python package
└── Makefile          # Single Makefile for all commands
```

## Key Points

1. **Single Makefile**: All commands (iOS and ML) are in the root Makefile
   - `make build` = build iOS app
   - `make train` = train ML model
   - No separate Makefiles in subdirectories

2. **XcodeGen**: Project file is generated from `ios/project.yml`
   - Run `make generate` to create/update Xcode project
   - Never edit `.xcodeproj` directly

3. **Model Integration**:
   - ML models live in `ml/models/versions/vX.Y.Z/`
   - `ml/models/current` symlinks to active version
   - iOS references `../ml/models/current` in project.yml
   - Use `make sync-model VERSION=vX.Y.Z` to publish new model

4. **Datasets**:
   - Stored in `ml/datasets/` (not in git, added externally)
   - Structure: raw/, processed/, metadata/
   - See `ml/datasets/README.md` for format

5. **iOS Architecture**:
   - MVVM-Light pattern
   - Protocol-based classifier (`PacemakerClassifier`)
   - Mock classifier for testing without real model
   - Camera service using AVFoundation

## Common Tasks

### Working on iOS
```bash
make open       # Generate and open Xcode
make build      # Build for simulator
make test       # Run tests
make lint       # SwiftLint
make format     # SwiftFormat
```

### Working on ML
```bash
make install-ml           # First time setup
conda activate pacerid-ml
make train                # Train model
make export               # Export to CoreML
make sync-model VERSION=v1.0.0  # Publish to iOS
```

### Integration
After training a new model:
1. `make export` → creates `ml/output/PacemakerClassifier.mlmodel`
2. `make sync-model VERSION=v1.1.0` → publishes to `ml/models/versions/v1.1.0/` and updates `current` symlink
3. `make build` → iOS picks up new model

## Important Files

- `Makefile` - All build commands
- `ios/project.yml` - Xcode project definition
- `ios/PacemakerID/Protocols/PacemakerClassifier.swift` - ML classifier interface
- `ml/configs/base.yaml` - Training configuration
- `ml/scripts/sync_model.sh` - Model publishing script

## When Making Changes

- **iOS code changes**: Just edit and build
- **New files**: May need `make clean && make generate` to update project
- **Model path changes**: Update `ios/project.yml` sources
- **Training config**: Edit `ml/configs/base.yaml`
