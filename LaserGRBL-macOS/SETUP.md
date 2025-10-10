# Setting Up LaserGRBL for macOS in Xcode

This guide walks you through creating an Xcode project for LaserGRBL macOS.

## Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Apple Silicon Mac (M1/M2/M3) recommended

## Step-by-Step Setup

### 1. Create New Xcode Project

1. Open Xcode
2. Select **File → New → Project**
3. Choose **macOS** tab
4. Select **App** template
5. Click **Next**

### 2. Configure Project Settings

Fill in the following:
- **Product Name**: `LaserGRBL`
- **Team**: Select your development team
- **Organization Identifier**: `com.yourname` (or your identifier)
- **Bundle Identifier**: Will auto-fill as `com.yourname.LaserGRBL`
- **Interface**: **SwiftUI**
- **Language**: **Swift**
- **Storage**: None (uncheck Core Data and CloudKit)
- **Include Tests**: Optional

Click **Next** and save in: `/Volumes/Development (Case Sense)/Projects/LaserGRBL4Mac/LaserGRBL4Mac/LaserGRBL-macOS/`

### 3. Add Source Files to Project

1. In Xcode Project Navigator, **delete** the default files:
   - `LaserGRBLApp.swift` (we'll replace it)
   - `ContentView.swift`

2. **Drag and drop** these folders from Finder into your Xcode project:
   - `Models/`
   - `Managers/`
   - `Views/`

3. When prompted, select:
   - ✅ **Copy items if needed**
   - ✅ **Create groups**
   - ✅ **Add to target: LaserGRBL**

4. Add the standalone files:
   - `LaserGRBLApp.swift`
   - `Info.plist`
   - `LaserGRBL.entitlements`

### 4. Configure Build Settings

#### General Tab

1. Select your project in the Project Navigator
2. Select the **LaserGRBL** target
3. Under **General** tab:
   - **Minimum Deployments**: macOS 13.0
   - **Category**: Developer Tools

#### Signing & Capabilities Tab

1. Select **Signing & Capabilities** tab
2. Enable **Automatically manage signing**
3. Select your **Team**
4. Click **+ Capability** and add:
   - **App Sandbox**
     - ✅ User Selected Files (Read/Write)
   - **Hardened Runtime**
     - ✅ Allow Unsigned Executable Memory (OFF)

#### Info Tab

1. Select **Info** tab
2. Click **+** to add custom properties:
   - **Document Types**: Already configured in Info.plist
   - Right-click on `Info.plist` in project → **Open As → Source Code**
   - Verify the document types are present

### 5. Link the Entitlements File

1. In **Signing & Capabilities** tab
2. Look for **App Sandbox** section
3. Under **Code Signing Entitlements**, select: `LaserGRBL.entitlements`
4. Verify these entitlements are enabled:
   - User Selected File (Read/Write)
   - USB/Serial (for Phase 2)
   - Network Client (for future features)

### 6. Build and Run

1. Select **Product → Clean Build Folder** (⇧⌘K)
2. Select **Product → Build** (⌘B)
3. Fix any build errors if they appear
4. Select **Product → Run** (⌘R)

The app should launch with the welcome screen!

## Testing the App

### Quick Test

1. Click **"Open G-Code File"**
2. Navigate to `Tests/SampleFiles/`
3. Open `square.gcode`
4. Verify:
   - ✅ Commands appear in the left pane
   - ✅ Preview shows a square in the right pane
   - ✅ File info shows correct dimensions
   - ✅ Can switch to text editor mode
   - ✅ Can save file

### Creating Test Files

Use the sample files in `Tests/SampleFiles/`:
- `square.gcode` - Basic 50mm square
- `circle.gcode` - Arc commands test
- `engraving.gcode` - Complex pattern with power variation

## Troubleshooting

### Build Errors

**Error: Cannot find 'NSOpenPanel' in scope**
- Solution: Ensure you're building for macOS, not iOS
- Check target deployment settings

**Error: Missing entitlements**
- Solution: Make sure `LaserGRBL.entitlements` is added to the project
- Check that it's selected in Build Settings → Code Signing Entitlements

**Error: App crashes on file open**
- Solution: Verify App Sandbox entitlements include file access
- Check that "User Selected Files (Read/Write)" is enabled

### Runtime Issues

**Can't open files**
- Check App Sandbox permissions
- Verify entitlements file is properly linked
- Ensure "User Selected Files" is enabled

**Preview not displaying**
- Check that commands have valid X/Y coordinates
- Try the sample files first
- Verify analyze() is being called after loading

**Zoom/Pan not working**
- This is a known limitation - gestures may need tuning
- Use the toolbar buttons to reset view

## Project Structure Verification

Your project should look like this:

```
LaserGRBL/
├── LaserGRBLApp.swift
├── Models/
│   ├── GCodeCommand.swift
│   └── GCodeFile.swift
├── Managers/
│   └── GCodeFileManager.swift
├── Views/
│   ├── ContentView.swift
│   ├── GCodeEditorView.swift
│   ├── GCodePreviewView.swift
│   └── FileInfoView.swift
├── Tests/
│   └── SampleFiles/
│       ├── square.gcode
│       ├── circle.gcode
│       └── engraving.gcode
├── Info.plist
├── LaserGRBL.entitlements
└── Assets.xcassets/
```

## Next Steps

Once Phase 1 is working:
1. Test with your own G-code files
2. Report any parsing issues
3. Prepare for Phase 2: USB Serial Connectivity
4. Review the plan in `convert-to-native-mac.plan.md`

## Support

For issues specific to this macOS port:
- Check the main README.md for status updates
- Review `LaserGRBL-macOS/README.md` for technical details

For G-code format questions:
- Reference the original LaserGRBL documentation
- Visit: http://lasergrbl.com

