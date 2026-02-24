# Claude Code Context

## Project Structure

This is a monorepo with iOS app and ML training:

```
pacerID-app/
├── ios/              # iOS application
│   ├── PacerID/  # Source code (SwiftUI + MVVM)
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
   - Downloaded automatically from Kaggle via `make download-data`
   - Stored in `ml/datasets/` (not in git)
   - Structure: raw/ (from Kaggle), processed/ (symlinks to raw/)
   - Dataset source configured in `ml/configs/base.yaml`

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
# First time setup
make install-ml                 # Create conda environment
conda activate pacerid-ml       # Activate environment
make download-data              # Download training data from Kaggle

# Training workflow
make train                      # Train model
make export                     # Export to CoreML
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
- `ios/PacerID/Protocols/PacemakerClassifier.swift` - ML classifier interface
- `ml/configs/base.yaml` - **Single source of truth** for all paths and training settings
- `ml/scripts/download_data.py` - Downloads dataset from Kaggle
- `ml/scripts/train.py` - Main training script
- `ml/scripts/export.py` - Exports PyTorch model to CoreML
- `ml/scripts/sync_model.sh` - Publishes model to versioned storage

## When Making Changes

- **iOS code changes**: Just edit and build
- **New files**: May need `make clean && make generate` to update project
- **Model path changes**: Update `ios/project.yml` sources
- **Training config or dataset paths**: Edit `ml/configs/base.yaml` (single source of truth)
- **All ML scripts read from config**: No hardcoded paths in Python code
