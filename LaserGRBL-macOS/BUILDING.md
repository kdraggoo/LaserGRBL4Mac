# Quick Build Guide

## For Developers Familiar with Xcode

### Fast Track

```bash
# 1. Open Xcode
open -a Xcode

# 2. Create new macOS App project:
#    - Save location: this directory (LaserGRBL-macOS/)
#    - Name: LaserGRBL
#    - Interface: SwiftUI
#    - Language: Swift

# 3. Replace default files with the provided Swift files

# 4. Build and run (⌘R)
```

### File Checklist

Ensure these files are in your Xcode project:

- [x] `LaserGRBLApp.swift` - App entry point
- [x] `Models/GCodeCommand.swift` - Command model
- [x] `Models/GCodeFile.swift` - File model
- [x] `Managers/GCodeFileManager.swift` - File operations
- [x] `Views/ContentView.swift` - Main view
- [x] `Views/GCodeEditorView.swift` - Editor
- [x] `Views/GCodePreviewView.swift` - Preview canvas
- [x] `Views/FileInfoView.swift` - Info sheet
- [x] `Info.plist` - App metadata
- [x] `LaserGRBL.entitlements` - Permissions

### Build Settings Summary

| Setting | Value |
|---------|-------|
| **Minimum Deployment** | macOS 13.0 |
| **Bundle ID** | com.yourname.LaserGRBL |
| **Interface** | SwiftUI |
| **Language** | Swift |
| **App Sandbox** | Enabled |
| **File Access** | User Selected (Read/Write) |
| **Serial Port** | Enabled (for Phase 2) |

### Common Commands

```bash
# Clean build folder
⇧⌘K

# Build
⌘B

# Run
⌘R

# Run with debugger
⌥⌘R

# Profile with Instruments
⌘I
```

### Architecture Support

This app is designed for:
- ✅ Apple Silicon (arm64) - Primary target
- ✅ Intel (x86_64) - Should work but not optimized
- ⚠️ Universal Binary - Not tested

Build for your architecture or create a Universal Binary for distribution.

### Distribution

For distribution outside the Mac App Store:

1. **Archive** the app (Product → Archive)
2. **Export** with Developer ID certificate
3. **Notarize** with Apple (required for Catalina+)
4. **Distribute** as DMG or PKG

```bash
# Notarization command (after export)
xcrun notarytool submit LaserGRBL.app.zip \
  --apple-id "your@email.com" \
  --password "app-specific-password" \
  --team-id "TEAM_ID" \
  --wait
```

## Automated Build Script (Future)

A `build.sh` script will be provided for CI/CD:

```bash
#!/bin/bash
# Future automated build script
xcodebuild -project LaserGRBL.xcodeproj \
           -scheme LaserGRBL \
           -configuration Release \
           -destination 'platform=macOS,arch=arm64' \
           clean build
```

## Testing

### Unit Tests (Future)

```bash
# Run tests
⌘U

# Test specific file
⌘⌥U (select test)
```

### Manual Testing Checklist

- [ ] App launches without errors
- [ ] Can open `.gcode` files
- [ ] Commands parse correctly
- [ ] Preview renders toolpath
- [ ] Can edit G-code text
- [ ] Can save files
- [ ] File info displays correctly
- [ ] Zoom/pan works
- [ ] Grid toggle works

### Performance Testing

Use Instruments to profile:
- Time Profiler - Check parsing performance
- Allocations - Monitor memory usage
- Leaks - Verify no memory leaks

## Debug vs Release

### Debug Build
- Includes debug symbols
- No optimizations
- Larger binary size
- Useful for development

### Release Build
- Optimized code
- Smaller binary
- Faster execution
- Use for distribution

Toggle in Xcode: **Product → Scheme → Edit Scheme → Run → Build Configuration**

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Swift compiler errors | Check Swift version (5.9+) |
| Entitlements not applied | Re-link entitlements file |
| App crashes on launch | Check sandbox permissions |
| Preview not rendering | Verify Canvas implementation |
| Can't access files | Enable file access entitlements |

## Development Tips

1. **Use SwiftUI Previews** - Fast iteration without full builds
2. **Enable Swift Concurrency Warnings** - Catch async issues early
3. **Use Xcode Breakpoints** - Debug complex parsing logic
4. **Profile Early** - Don't wait for performance issues

## Version Control

Remember to add `.gitignore`:

```gitignore
# Xcode
*.xcodeproj/xcuserdata/
*.xcodeproj/project.xcworkspace/xcuserdata/
*.xcworkspace/xcuserdata/
DerivedData/
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3

# macOS
.DS_Store
```

## Ready to Build?

See `SETUP.md` for detailed step-by-step instructions if this is your first time.

Otherwise, you're ready to go! Build and test the app now.

