# PacemakerID - XcodeGen Setup Guide

This guide will help you set up the project using XcodeGen, a tool that generates Xcode projects from a YAML specification file.

## Why XcodeGen?

- **Version Control Friendly**: No more merge conflicts in `.pbxproj` files
- **Declarative**: Project structure defined in readable YAML
- **Reproducible**: Everyone on the team generates the same project
- **Simple**: Easy to add/remove files and configure settings

## Prerequisites

1. **macOS** with Xcode 15.0 or later installed
2. **Homebrew** (for installing XcodeGen)
3. **iOS device** with camera (Simulator won't work for camera features)

## Quick Start

### 1. Install XcodeGen

```bash
# Using Homebrew (recommended)
brew install xcodegen

# Verify installation
xcodegen --version
```

### 2. Generate the Xcode Project

```bash
cd /Users/phil/repos/pacerID-app

# Generate PacemakerID.xcodeproj from project.yml
xcodegen generate

# You should see output like:
# ⚙️  Generating project...
# ⚙️  Writing project...
# Created project at /Users/phil/repos/pacerID-app/PacemakerID.xcodeproj
```

### 3. Open the Project

```bash
# Open in Xcode
open PacemakerID.xcodeproj

# Or just double-click PacemakerID.xcodeproj in Finder
```

### 4. Configure Code Signing

1. In Xcode, select the **PacemakerID** project in the Navigator
2. Select the **PacemakerID** target
3. Go to **Signing & Capabilities** tab
4. Select your **Team** from the dropdown

**Optional**: Set your team ID in `project.yml` to automate this:

```yaml
settings:
  base:
    DEVELOPMENT_TEAM: "YOUR_TEAM_ID_HERE"
```

Then regenerate: `xcodegen generate`

### 5. Build and Run

1. Connect your iOS device via USB
2. Select your device in the scheme selector (top toolbar)
3. Press **⌘R** or click the Run button
4. Allow camera access when prompted

## Project Structure

```
pacerID-app/
├── project.yml                    # XcodeGen configuration (SOURCE OF TRUTH)
├── PacemakerID.xcodeproj/         # Generated (DO NOT EDIT, ignored by git)
├── PacemakerID/                   # Source code
│   ├── PacemakerIDApp.swift
│   ├── Info.plist
│   ├── Assets.xcassets/
│   ├── Models/
│   ├── Protocols/
│   ├── Services/
│   ├── ViewModels/
│   └── Views/
└── README.md
```

## Working with XcodeGen

### Making Project Changes

**IMPORTANT**: Never edit the `.xcodeproj` file directly in Xcode project settings. Instead:

1. Edit `project.yml`
2. Run `xcodegen generate`
3. Xcode will reload automatically

### Common Tasks

#### Adding a New Swift File

Just create the file in the appropriate directory:

```bash
# XcodeGen automatically includes all files in PacemakerID/
touch PacemakerID/Services/RealPacemakerClassifier.swift
xcodegen generate
```

#### Changing Bundle Identifier

Edit `project.yml`:

```yaml
options:
  bundleIdPrefix: com.yourcompany  # Change this

targets:
  PacemakerID:
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.yourcompany.PacemakerID  # And this
```

Then regenerate:

```bash
xcodegen generate
```

#### Adding Dependencies (Swift Package Manager)

Edit `project.yml` and add packages:

```yaml
targets:
  PacemakerID:
    dependencies:
      - package: Alamofire
        product: Alamofire

packages:
  Alamofire:
    url: https://github.com/Alamofire/Alamofire
    from: 5.8.0
```

#### Changing Deployment Target

Edit `project.yml`:

```yaml
options:
  deploymentTarget:
    iOS: "17.0"  # Change this
```

#### Adding Build Settings

Edit `project.yml`:

```yaml
targets:
  PacemakerID:
    settings:
      base:
        ENABLE_BITCODE: NO
        SWIFT_STRICT_CONCURRENCY: complete
        # Add more settings here
```

### Team Workflow

#### Initial Setup (First Time)

```bash
git clone <repository>
cd pacerID-app
xcodegen generate
open PacemakerID.xcodeproj
```

#### Daily Workflow

```bash
# Pull latest changes
git pull

# If project.yml changed, regenerate
xcodegen generate

# Open and work
open PacemakerID.xcodeproj
```

#### Before Committing

```bash
# Only commit source files and project.yml
# The .xcodeproj is automatically ignored by .gitignore

git add PacemakerID/
git add project.yml
git commit -m "Add new feature"
git push
```

## XcodeGen Configuration Reference

### Current Configuration (`project.yml`)

```yaml
name: PacemakerID

options:
  bundleIdPrefix: com.yourcompany      # Base bundle identifier
  deploymentTarget:
    iOS: "16.0"                        # Minimum iOS version
  developmentLanguage: en              # Development language
  xcodeVersion: "15.0"                 # Xcode version

targets:
  PacemakerID:
    type: application                  # App target
    platform: iOS                      # iOS platform

    sources:
      - path: PacemakerID              # Auto-include all files
        excludes:
          - "*.md"                     # Exclude markdown files

    info:
      path: PacemakerID/Info.plist     # Info.plist location
      properties:
        NSCameraUsageDescription: "..." # Camera permission

    settings:
      base:
        PRODUCT_NAME: PacemakerID
        TARGETED_DEVICE_FAMILY: "1,2"  # iPhone and iPad
        ENABLE_PREVIEWS: YES            # SwiftUI previews

      debug:
        SWIFT_OPTIMIZATION_LEVEL: "-Onone"

      release:
        SWIFT_OPTIMIZATION_LEVEL: "-O"
```

### Key Settings Explained

| Setting | Description |
|---------|-------------|
| `bundleIdPrefix` | Base for all bundle identifiers |
| `deploymentTarget` | Minimum iOS version required |
| `TARGETED_DEVICE_FAMILY` | "1" = iPhone, "2" = iPad, "1,2" = Universal |
| `ENABLE_PREVIEWS` | Enable SwiftUI canvas previews |
| `SWIFT_VERSION` | Swift language version |

## Advanced Usage

### Multiple Targets

Add a test target:

```yaml
targets:
  PacemakerID:
    type: application
    # ... existing config

  PacemakerIDTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - PacemakerIDTests
    dependencies:
      - target: PacemakerID
```

### Custom Schemes

```yaml
schemes:
  PacemakerID:
    build:
      targets:
        PacemakerID: all
    run:
      config: Debug
      commandLineArguments:
        "-com.apple.CoreData.SQLDebug": "1"
    test:
      config: Debug
      gatherCoverageData: true
```

### Conditional Compilation

```yaml
targets:
  PacemakerID:
    settings:
      debug:
        SWIFT_ACTIVE_COMPILATION_CONDITIONS: DEBUG MOCK_CLASSIFIER

      release:
        SWIFT_ACTIVE_COMPILATION_CONDITIONS: PRODUCTION
```

Then in code:

```swift
#if MOCK_CLASSIFIER
let classifier = MockPacemakerClassifier()
#else
let classifier = ProductionPacemakerClassifier()
#endif
```

## Troubleshooting

### XcodeGen Not Found

```bash
# Install via Homebrew
brew install xcodegen

# Or install via Mint
mint install yonaskolb/XcodeGen
```

### Project Won't Generate

```bash
# Validate project.yml syntax
xcodegen generate --spec project.yml

# Check for YAML syntax errors
yamllint project.yml  # if you have yamllint installed
```

### Xcode Doesn't See New Files

```bash
# Regenerate the project
xcodegen generate

# Clean build folder in Xcode
# Product > Clean Build Folder (⌘⇧K)
```

### Build Settings Not Applying

1. Make sure you edited `project.yml`, not the Xcode project settings
2. Regenerate: `xcodegen generate`
3. Close and reopen Xcode
4. Clean build: ⌘⇧K

### Merge Conflicts in project.yml

Since `project.yml` is YAML (plain text), merge conflicts are much easier to resolve than `.pbxproj` conflicts:

```bash
# View the conflict
git diff project.yml

# Edit to resolve
vim project.yml  # or your preferred editor

# Regenerate
xcodegen generate

# Commit
git add project.yml
git commit
```

## Advantages Over Manual Xcode Projects

| Feature | Manual Xcode | XcodeGen |
|---------|--------------|----------|
| Merge conflicts | Common, difficult | Rare, easy to resolve |
| Code review | Hard to review .pbxproj | Easy to review YAML changes |
| CI/CD | Need to commit .xcodeproj | Generate on CI server |
| Consistency | Varies by developer | Same for everyone |
| File management | Manual add in Xcode | Automatic detection |

## Best Practices

### ✅ Do

- Commit `project.yml` to version control
- Run `xcodegen generate` after pulling changes
- Edit `project.yml` for project configuration
- Use consistent indentation in `project.yml`
- Document custom settings in `project.yml` comments

### ❌ Don't

- Don't commit `.xcodeproj` (it's in `.gitignore`)
- Don't edit Xcode project settings directly
- Don't manually add files in Xcode (they're auto-detected)
- Don't forget to regenerate after changing `project.yml`

## Quick Reference Commands

```bash
# Generate project
xcodegen generate

# Generate with custom spec file
xcodegen generate --spec custom.yml

# Generate and use cache (faster)
xcodegen generate --use-cache

# Dump spec to JSON (for debugging)
xcodegen dump --spec project.yml

# Show version
xcodegen --version

# Get help
xcodegen --help
```

## Migration from Manual Xcode Project

If you started with a manual Xcode project:

1. Install XcodeGen: `brew install xcodegen`
2. The `project.yml` is already created
3. Delete the old `.xcodeproj` if it exists
4. Generate new project: `xcodegen generate`
5. Open and configure signing: `open PacemakerID.xcodeproj`

## Resources

- **XcodeGen Documentation**: https://github.com/yonaskolb/XcodeGen
- **Project Spec Reference**: https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md
- **Examples**: https://github.com/yonaskolb/XcodeGen/tree/master/Examples

## Support

If you encounter issues:

1. Check the [XcodeGen Issues](https://github.com/yonaskolb/XcodeGen/issues)
2. Validate your `project.yml` syntax
3. Try cleaning and regenerating
4. Check Xcode console for error messages

---

**Ready to build!** Run `xcodegen generate` and start developing with a version-control-friendly project setup.
