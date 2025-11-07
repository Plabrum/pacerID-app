# PacemakerID - Quick Setup Guide

This guide will help you create the Xcode project and run the app.

## Prerequisites

- macOS with Xcode 15.0 or later installed
- iOS device with camera (Simulator won't work for camera features)
- Apple Developer account (for device deployment)

## Step-by-Step Setup

### 1. Create New Xcode Project

1. Open **Xcode**
2. Select **File > New > Project** (or press ⌘⇧N)
3. In the template chooser:
   - Select **iOS** tab
   - Choose **App** template
   - Click **Next**

### 2. Configure Project Settings

Enter the following project details:

| Field | Value |
|-------|-------|
| Product Name | `PacemakerID` |
| Team | Select your development team |
| Organization Identifier | `com.yourcompany` (or your identifier) |
| Bundle Identifier | Will auto-generate (e.g., `com.yourcompany.PacemakerID`) |
| Interface | **SwiftUI** |
| Language | **Swift** |
| Storage | None (uncheck Core Data) |
| Include Tests | Optional (can leave checked) |

Click **Next**, then choose the `pacerID-app` directory as the save location.

⚠️ **Important**: When saving, **uncheck** "Create Git repository" if you already have one.

### 3. Remove Default Files

Xcode creates some default files we don't need:

1. In the Project Navigator (left sidebar), find these files in the `PacemakerID` folder:
   - `ContentView.swift` (delete it)
   - `Assets.xcassets` (keep this, but it will be empty)
2. Right-click each file and select **Delete**
3. Choose **Move to Trash**

### 4. Add Project Files

Now add all the source files:

1. In Project Navigator, right-click on the `PacemakerID` folder (the one with the blue icon)
2. Select **Add Files to "PacemakerID"...**
3. Navigate to the `PacemakerID` folder in Finder
4. Select **all folders and files** inside:
   - `Models` folder
   - `Protocols` folder
   - `Services` folder
   - `ViewModels` folder
   - `Views` folder
   - `PacemakerIDApp.swift`
5. In the dialog, ensure these options are selected:
   - ✅ **Copy items if needed**
   - ✅ **Create groups** (not folder references)
   - ✅ Your target (PacemakerID) is checked
6. Click **Add**

### 5. Configure Info.plist

1. In Project Navigator, select `Info.plist`
2. Delete it (Move to Trash)
3. Right-click the `PacemakerID` folder > **Add Files to "PacemakerID"...**
4. Select the `Info.plist` file from the `PacemakerID` folder
5. Ensure "Copy items if needed" is checked
6. Click **Add**

**Alternative method**:
1. Select the project in Project Navigator (top-level item)
2. Select the `PacemakerID` target
3. Go to the **Info** tab
4. Click the **Custom iOS Target Properties** section
5. Add this key if not present:
   - Key: `Privacy - Camera Usage Description`
   - Value: `PacemakerID needs camera access to photograph X-rays and identify pacemaker devices.`

### 6. Verify Project Structure

Your Project Navigator should look like this:

```
PacemakerID
├── PacemakerIDApp.swift
├── Models
│   └── Classification.swift
├── Protocols
│   └── PacemakerClassifier.swift
├── Services
│   ├── CameraService.swift
│   └── MockPacemakerClassifier.swift
├── ViewModels
│   ├── CameraViewModel.swift
│   └── ResultsViewModel.swift
├── Views
│   ├── CameraView.swift
│   ├── CameraPreviewRepresentable.swift
│   ├── ResultsView.swift
│   └── Components
│       ├── CaptureButton.swift
│       └── ProbabilityBar.swift
├── Assets.xcassets
└── Info.plist
```

### 7. Build the Project

1. Press **⌘B** or select **Product > Build**
2. Ensure there are no errors
   - If you see warnings about "no selected devices", that's okay
   - Any Swift errors should not occur if files are added correctly

### 8. Run on Device

1. Connect your iOS device via USB
2. Trust the computer on your device if prompted
3. In Xcode, select your device from the scheme selector (top toolbar)
4. Press **⌘R** or select **Product > Run**
5. If prompted about code signing:
   - Go to project settings > **Signing & Capabilities**
   - Select your **Team**
   - Xcode will automatically manage signing

6. On first run, you may need to trust the developer on your device:
   - Go to **Settings > General > VPN & Device Management**
   - Tap your developer profile
   - Tap **Trust**

### 9. Grant Camera Permissions

1. When the app launches, it will request camera access
2. Tap **Allow** when prompted
3. The camera preview should appear immediately

## Testing the App

1. Point your device camera at any image (doesn't have to be an X-ray for testing)
2. Tap the white circular capture button
3. Wait ~0.5 seconds for processing
4. View the mock classification results
5. Tap **Done** to return to camera

## Troubleshooting

### "No such module" errors
- Ensure all files were added to the target
- Check that the target membership is set for each file

### Camera preview is black
- Ensure you're running on a physical device (not Simulator)
- Check that camera permissions were granted
- Go to Settings > Privacy > Camera and enable PacemakerID

### Build errors about missing files
- Verify all Swift files are added to the project
- Check that files are in the correct groups/folders

### Code signing issues
- Select a valid Team in Signing & Capabilities
- Ensure your Apple ID is added in Xcode preferences

## Next Steps

- Read the [README.md](README.md) for architecture details
- Replace `MockPacemakerClassifier` with your production ML model
- Customize UI colors and styling
- Add additional features as needed

## Quick Commands

| Action | Shortcut |
|--------|----------|
| Build | ⌘B |
| Run | ⌘R |
| Stop | ⌘. |
| Clean Build | ⌘⇧K |
| Open Quickly | ⌘⇧O |

## Need Help?

If you encounter issues:
1. Clean build folder: **Product > Clean Build Folder** (⌘⇧K)
2. Restart Xcode
3. Check that all files are properly added to the target
4. Verify Info.plist contains camera usage description

---

**Ready to go!** Your PacemakerID app should now be running on your device.
