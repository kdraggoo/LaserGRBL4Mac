# Phase 4: SVG Vector Import - Setup Guide

**LaserGRBL for macOS**

This guide will walk you through adding the Phase 4 foundation files to your Xcode project and integrating the required Swift Package Manager dependencies.

---

## What's Been Created

### ✅ Core Models (4 files)
- `Models/SVGPath.swift` - Path data structure with Bézier curve support
- `Models/SVGDocument.swift` - Complete SVG document representation
- `Models/SVGLayer.swift` - Layer management system
- `Models/VectorSettings.swift` - Conversion parameters and presets

### ✅ Managers (1 file)
- `Managers/SVGImporter.swift` - File import and parsing (placeholder for SwiftDraw)

### ✅ Test Files (5 SVG files)
- `Tests/SampleFiles/square.svg` - Basic rectangle
- `Tests/SampleFiles/circle.svg` - Circle (curve testing)
- `Tests/SampleFiles/star.svg` - Star shape (complex path)
- `Tests/SampleFiles/curves.svg` - Various Bézier curves
- `Tests/SampleFiles/logo.svg` - Multi-element design

---

## Step 1: Add Files to Xcode Project

### Open Xcode Project

```bash
cd "/Volumes/Development (Case Sense)/Projects/LaserGRBL4Mac/LaserGRBL4Mac/LaserGRBL-macOS/LaserGRBL"
open LaserGRBL.xcodeproj
```

### Add Model Files

1. In Xcode Project Navigator, right-click on `Models` folder
2. Choose **"Add Files to 'LaserGRBL'"**
3. Navigate to and select these files:
   - `SVGPath.swift`
   - `SVGDocument.swift`
   - `SVGLayer.swift`
   - `VectorSettings.swift`
4. ✅ Check "Copy items if needed"
5. ✅ Ensure "LaserGRBL" target is selected
6. Click "Add"

### Add Manager Files

1. Right-click on `Managers` folder
2. Choose **"Add Files to 'LaserGRBL'"**
3. Select `SVGImporter.swift`
4. ✅ Check "Copy items if needed"
5. ✅ Ensure "LaserGRBL" target is selected
6. Click "Add"

---

## Step 2: Add Swift Package Dependencies

We need to add **SwiftDraw** for SVG parsing. (SVGPath will be added later if needed)

### Add SwiftDraw Package

1. In Xcode, select your project file in the Navigator
2. Select the **"LaserGRBL"** project (not target)
3. Go to the **"Package Dependencies"** tab
4. Click the **"+"** button
5. In the search field, enter:
   ```
   https://github.com/swhitty/SwiftDraw
   ```
6. Click **"Add Package"**
7. Select version: **"Up to Next Major Version"** with **"0.16.0"**
8. Click **"Add Package"** again
9. Ensure **"SwiftDraw"** is checked for the **LaserGRBL** target
10. Click **"Add Package"**

### Verify Package Added

After adding, you should see in the Package Dependencies section:
- ORSSerialPort (2.1.0) ✅
- SwiftDraw (0.16.0) ✅

---

## Step 3: Update SVGImporter to Use SwiftDraw

Once the package is added, we'll update `SVGImporter.swift` to use SwiftDraw's actual parsing capabilities instead of the placeholder.

### Current Status
The `SVGImporter.swift` file currently contains a placeholder implementation that creates a simple test square. This is intentional - we need to add SwiftDraw first, then implement the actual parsing logic.

### Next Steps (After Package Added)
1. Import SwiftDraw in SVGImporter.swift
2. Replace placeholder `SVGXMLParser` with SwiftDraw parsing
3. Extract paths from SwiftDraw's DOM
4. Convert to our `SVGPath` structures

---

## Step 4: Build and Test

### Clean Build

```
⌘ + Shift + K (Clean Build Folder)
```

### Build Project

```
⌘ + B (Build)
```

### Expected Results

✅ Project compiles successfully
✅ No errors in new files
✅ SwiftDraw package integrated
✅ All 5 new Swift files in target

### If You Get Errors

**"Cannot find type 'SVGPath' in scope"**
- Solution: Ensure all model files are added to the LaserGRBL target
- Check Target Membership in File Inspector (⌘ + Option + 1)

**"No such module 'SwiftDraw'"**
- Solution: Re-add the package or try cleaning derived data
- Product → Clean Build Folder (⌘ + Shift + K)
- Close and reopen Xcode

**Build takes very long**
- Solution: Clean derived data
- Go to ~/Library/Developer/Xcode/DerivedData
- Delete the LaserGRBL folder
- Rebuild

---

## Step 5: Verify File Structure

Your project should now have:

```
LaserGRBL.xcodeproj
├── Package Dependencies
│   ├── ORSSerialPort (2.1.0)
│   └── SwiftDraw (0.16.0)
└── LaserGRBL/
    ├── Models/
    │   ├── GCodeCommand.swift
    │   ├── GCodeFile.swift
    │   ├── GrblCommand.swift
    │   ├── GrblResponse.swift
    │   ├── RasterImage.swift
    │   ├── RasterSettings.swift
    │   ├── SVGPath.swift          ✨ NEW
    │   ├── SVGDocument.swift      ✨ NEW
    │   ├── SVGLayer.swift         ✨ NEW
    │   └── VectorSettings.swift   ✨ NEW
    ├── Managers/
    │   ├── GCodeFileManager.swift
    │   ├── SerialPortManager.swift
    │   ├── GrblController.swift
    │   ├── ImageImporter.swift
    │   ├── RasterConverter.swift
    │   └── SVGImporter.swift      ✨ NEW
    └── Views/
        ├── ContentView.swift
        ├── GCodeEditorView.swift
        ├── GCodePreviewView.swift
        ├── FileInfoView.swift
        ├── ConnectionView.swift
        ├── ControlPanelView.swift
        ├── ConsoleView.swift
        ├── ImageImportView.swift
        └── RasterSettingsView.swift
```

---

## What's Next

### Immediate Next Steps

1. ✅ Files created and added to project
2. ✅ SwiftDraw package integrated
3. ⏳ Update SVGImporter to use SwiftDraw
4. ⏳ Create BezierTools.swift for curve conversion
5. ⏳ Create PathToGCodeConverter.swift
6. ⏳ Build UI views for SVG import

### Week 1 Remaining Tasks

- Implement actual SVG parsing with SwiftDraw
- Extract transforms and styles
- Test with sample SVG files
- Verify path extraction works

---

## Testing Checklist

Once SwiftDraw is integrated and parsing is implemented:

- [ ] Can import square.svg
- [ ] Can import circle.svg (curve conversion)
- [ ] Can import star.svg (complex path)
- [ ] Can import curves.svg (Bézier curves)
- [ ] Can import logo.svg (multi-element)
- [ ] Paths are extracted correctly
- [ ] Bounding boxes calculated
- [ ] Layers detected (if present)
- [ ] No crashes on import

---

## File Summaries

### SVGPath.swift (280 lines)
- Path data structure with CGPath
- Start/end point calculation
- Path element extraction
- Length approximation
- Bézier curve helpers

### SVGDocument.swift (180 lines)
- Document-level representation
- Layer management
- Path collection
- Bounding box calculation
- Time estimation

### SVGLayer.swift (130 lines)
- Layer structure
- Visibility/lock state
- Path grouping
- Layer operations

### VectorSettings.swift (300 lines)
- Conversion parameters
- 5 built-in presets
- Validation logic
- Render modes
- Fill patterns

### SVGImporter.swift (160 lines)
- File picker integration
- SVG loading
- Placeholder parser (to be replaced)
- Error handling

---

## Known Limitations (Current)

1. **SVGImporter is placeholder-only**
   - Currently creates test square
   - Needs SwiftDraw integration for actual parsing

2. **No UI yet**
   - Views will be created in Week 3
   - Manual testing only for now

3. **No G-code conversion yet**
   - PathToGCodeConverter in Week 2
   - BezierTools in Week 2

---

## Support

If you encounter issues:

1. Check Package Dependencies tab shows both packages
2. Clean build folder and derived data
3. Verify all files have LaserGRBL target membership
4. Check console for specific error messages

---

**Phase 4 Foundation Complete!** 🎉

You now have the core data structures and foundation for SVG import. Next step is implementing the actual parsing with SwiftDraw.

---

*Phase 4 Setup Guide*  
*LaserGRBL for macOS*  
*Created: October 19, 2025*

