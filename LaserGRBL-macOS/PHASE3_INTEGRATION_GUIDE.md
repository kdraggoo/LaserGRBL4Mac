# Phase 3 Integration Guide

**LaserGRBL for macOS - Image Import & Raster Conversion**

This guide will help you integrate Phase 3 features into your Xcode project.

---

## Prerequisites

- ✅ Phase 1 complete (G-Code Loading & Export)
- ✅ Phase 2 complete (USB Serial & GRBL Control)
- macOS 13.0+ deployment target
- Xcode 15.0+
- Swift 5.9+

---

## Files to Add to Xcode Project

### Models (Add to LaserGRBL/Models/)

1. **RasterImage.swift** (320 lines)
   - Image processing and metadata
   - Grayscale conversion
   - Image adjustments

2. **RasterSettings.swift** (280 lines)
   - Conversion parameters
   - Dithering algorithms
   - Preset system

### Managers (Add to LaserGRBL/Managers/)

3. **ImageImporter.swift** (160 lines)
   - Image file import
   - Multi-format support
   - DPI metadata reading

4. **RasterConverter.swift** (650 lines)
   - G-code generation
   - 9 dithering algorithms
   - Raster optimization

### Views (Add to LaserGRBL/Views/)

5. **ImageImportView.swift** (400 lines)
   - Main image import UI
   - Preview modes
   - Zoom/pan controls

6. **RasterSettingsView.swift** (350 lines)
   - Settings panel
   - Preset selector
   - Real-time adjustments

### Modified Files

7. **ContentView.swift** (updated)
   - Added Image tab
   - Environment object wiring

8. **LaserGRBLApp.swift** (updated)
   - ImageImporter environment object
   - RasterConverter environment object
   - Keyboard shortcuts

9. **GCodeFile.swift** (updated)
   - Added `loadFromText()` method

---

## Step-by-Step Integration

### 1. Open Your Xcode Project

```bash
cd "/Volumes/Development (Case Sense)/Projects/LaserGRBL4Mac/LaserGRBL4Mac/LaserGRBL-macOS/LaserGRBL"
open LaserGRBL.xcodeproj
```

### 2. Add New Files

**In Xcode:**

1. Right-click on `Models` folder → Add Files to "LaserGRBL"
   - Add `RasterImage.swift`
   - Add `RasterSettings.swift`
   - ✅ Ensure "Copy items if needed" is checked
   - ✅ Ensure "LaserGRBL" target is selected

2. Right-click on `Managers` folder → Add Files to "LaserGRBL"
   - Add `ImageImporter.swift`
   - Add `RasterConverter.swift`

3. Right-click on `Views` folder → Add Files to "LaserGRBL"
   - Add `ImageImportView.swift`
   - Add `RasterSettingsView.swift`

### 3. Update Existing Files

The following files have been updated. Replace them or merge changes:

- `LaserGRBL/LaserGRBLApp.swift`
- `LaserGRBL/Views/ContentView.swift`
- `LaserGRBL/Models/GCodeFile.swift`

### 4. Verify File Structure

Your project should now have:

```
LaserGRBL.xcodeproj
LaserGRBL/
├── LaserGRBLApp.swift (updated)
├── Models/
│   ├── GCodeCommand.swift
│   ├── GCodeFile.swift (updated)
│   ├── GrblCommand.swift
│   ├── GrblResponse.swift
│   ├── RasterImage.swift (NEW)
│   └── RasterSettings.swift (NEW)
├── Managers/
│   ├── GCodeFileManager.swift
│   ├── SerialPortManager.swift
│   ├── GrblController.swift
│   ├── ImageImporter.swift (NEW)
│   └── RasterConverter.swift (NEW)
└── Views/
    ├── ContentView.swift (updated)
    ├── GCodeEditorView.swift
    ├── GCodePreviewView.swift
    ├── FileInfoView.swift
    ├── ConnectionView.swift
    ├── ControlPanelView.swift
    ├── ConsoleView.swift
    ├── ImageImportView.swift (NEW)
    └── RasterSettingsView.swift (NEW)
```

### 5. Build the Project

```
⌘ + B (or Product → Build)
```

**If you get errors:**

1. **Missing imports:** Make sure all files are added to the target
2. **Module not found:** Clean build folder (⌘ + Shift + K, then ⌘ + B)
3. **SwiftUI errors:** Ensure deployment target is macOS 13.0+

### 6. Run and Test

```
⌘ + R (or Product → Run)
```

---

## Testing Checklist

### Basic Functionality

- [ ] App launches without crashes
- [ ] Four tabs visible: G-Code, Image, Control, Console
- [ ] Image tab is accessible
- [ ] Import Image button works (⌘I)
- [ ] Welcome screen shows Phase 3 progress

### Image Import

- [ ] Can import PNG files
- [ ] Can import JPEG files
- [ ] Can import other formats (BMP, TIFF, GIF)
- [ ] File picker opens and closes
- [ ] Image displays in preview
- [ ] Image metadata shows correctly

### Image Preview

- [ ] Original mode shows image
- [ ] Grayscale mode works
- [ ] Zoom controls work (pinch gesture)
- [ ] Pan scrolling works
- [ ] Grid overlay toggles
- [ ] Dimension overlay displays

### Settings Panel

- [ ] Settings sidebar toggles
- [ ] All sliders responsive
- [ ] Preset selector works
- [ ] Dimensions update correctly
- [ ] Aspect ratio lock works

### Dithering

- [ ] All 9 algorithms available
- [ ] Algorithm descriptions show
- [ ] Threshold slider works
- [ ] Strength slider works
- [ ] Algorithm switching is smooth

### Conversion

- [ ] Convert button activates
- [ ] Progress bar displays
- [ ] Conversion completes
- [ ] G-code is generated
- [ ] Statistics show in status bar

### Integration

- [ ] No crashes when switching tabs
- [ ] Memory usage is reasonable
- [ ] UI remains responsive
- [ ] Error handling works

---

## Common Issues & Solutions

### Issue: "Cannot find type 'RasterImage' in scope"

**Solution:** Make sure `RasterImage.swift` is added to the LaserGRBL target.
- Select the file in Project Navigator
- Check "Target Membership" in File Inspector
- ✅ LaserGRBL should be checked

### Issue: "Missing environment object of type ImageImporter"

**Solution:** Ensure `LaserGRBLApp.swift` has been updated with the new environment objects.

### Issue: Build takes very long or hangs

**Solution:** Clean build folder and derived data:
```
⌘ + Shift + K (Clean Build Folder)
⌘ + Option + Shift + K (Clean Derived Data)
```

### Issue: Preview canvas shows checkerboard but no image

**Solution:** Check that:
1. Image file was loaded successfully
2. No errors in console
3. Try a different image format

### Issue: Conversion is very slow

**Solution:** 
- Large images take time (progress bar shows status)
- Try reducing DPI or resolution
- High-quality dithering is slower (use Floyd-Steinberg for speed)

---

## Performance Optimization

### For Large Images (>5 MP)

1. Reduce DPI to 127-254
2. Use faster dithering (Floyd-Steinberg, Burkes)
3. Increase line interval to 0.15-0.2mm
4. Enable "Skip White Pixels"

### For High Quality

1. Increase DPI to 318-508
2. Use high-quality dithering (Jarvis-Judice-Ninke, Sierra)
3. Decrease line interval to 0.05-0.08mm
4. Adjust brightness/contrast for optimal detail

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘ + I | Import Image |
| ⌘ + O | Open G-Code |
| ⌘ + S | Save |
| ⌘ + Shift + S | Save As |

---

## Next Steps

### Phase 4 Preview

Once Phase 3 is working, you can prepare for Phase 4 (SVG Vector Import):
- SVG file parsing
- Bézier curve conversion
- Path optimization
- Vector preview

---

## Support

### If You Encounter Issues

1. **Check Console Output** (⌘ + Shift + Y)
   - Look for error messages
   - Check for missing files

2. **Verify File Targets**
   - All new files should be in LaserGRBL target
   - Check Target Membership in File Inspector

3. **Clean and Rebuild**
   - Clean Build Folder (⌘ + Shift + K)
   - Build (⌘ + B)

4. **Check Deployment Target**
   - Project Settings → General → Minimum Deployments
   - Should be macOS 13.0 or later

### Documentation

- **PHASE3_COMPLETE.md** - Feature details
- **IMPLEMENTATION_STATUS.md** - Overall progress
- **QUICKSTART.md** - Quick setup guide
- **KNOWN_ISSUES.md** - Known bugs

---

## Testing Images

For testing, use:
- **Small images** (512×512) - Fast conversion, good for testing
- **Photos** (1024×1024) - Test photo quality
- **Large images** (2048×2048) - Test performance
- **High contrast** - Test dithering algorithms
- **Grayscale** - Test with pre-converted images

Recommended test images:
- Simple logo (black & white)
- Photograph (color)
- Line art (high contrast)
- Text document
- Complex illustration

---

## Verification

After integration, verify:

✅ All 21 Swift files compile  
✅ No compiler warnings  
✅ App launches successfully  
✅ All 4 tabs functional  
✅ Image import works  
✅ Conversion generates G-code  
✅ No memory leaks or crashes  

---

**Integration Complete!** 🎉

You now have full Phase 3 functionality:
- Image import (6 formats)
- 9 dithering algorithms
- G-code raster generation
- Advanced settings panel
- Real-time preview

Enjoy creating raster engravings!

---

*Phase 3 Integration Guide*  
*LaserGRBL for macOS*  
*Last Updated: October 11, 2025*

