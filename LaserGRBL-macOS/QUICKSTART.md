# LaserGRBL macOS - Quick Start Guide

**Time to first build: ~10 minutes**

## What You're Getting

A native macOS app that can:
- ✅ Open and display G-code files
- ✅ Edit G-code commands
- ✅ Visualize toolpaths in 2D
- ✅ Calculate dimensions and time
- ✅ Export with custom headers/footers

## 3-Step Setup

### Step 1: Open Xcode (2 minutes)

```bash
cd "/Volumes/Development (Case Sense)/Projects/LaserGRBL4Mac/LaserGRBL4Mac/LaserGRBL-macOS"
open -a Xcode
```

Create new project:
- **File → New → Project**
- Choose: **macOS → App**
- Name: **LaserGRBL**
- Interface: **SwiftUI**
- Language: **Swift**
- Save in this directory

### Step 2: Add Files (5 minutes)

1. Delete default `LaserGRBLApp.swift` and `ContentView.swift`
2. Drag these folders into Xcode:
   - `Models/`
   - `Managers/`
   - `Views/`
3. Add these files:
   - `LaserGRBLApp.swift`
   - `Info.plist`
   - `LaserGRBL.entitlements`
4. Xcode will automatically find `Assets.xcassets`

### Step 3: Build & Run (3 minutes)

1. Select your development team in **Signing & Capabilities**
2. Press **⌘B** to build
3. Press **⌘R** to run
4. Click **"Open G-Code File"**
5. Open `Tests/SampleFiles/square.gcode`

**Done!** You should see a square in the preview.

## First Test

1. **Open** → `square.gcode`
   - Should see 12 commands
   - Preview shows 50×50mm square
   
2. **Switch to Text mode**
   - Click text editor icon
   - Edit a line
   - Click "Apply Changes"
   
3. **View File Info**
   - Click "More Info..." button
   - Verify statistics match

## Troubleshooting

### Can't build?
- Check you're building for macOS (not iOS)
- Verify minimum deployment: macOS 13.0

### Files not found?
- Make sure you added them to the target
- Check they appear in Xcode's Project Navigator

### Can't open files?
- Go to **Signing & Capabilities**
- Enable **App Sandbox**
- Check **User Selected Files (Read/Write)**

## Next Steps

1. ✅ Test with your own G-code files
2. ✅ Experiment with the UI
3. ✅ Read `IMPLEMENTATION_STATUS.md` for what's next
4. ⏳ Wait for Phase 2: USB Serial Support

## File Locations

```
LaserGRBL-macOS/
├── 📱 LaserGRBLApp.swift         # Start here
├── 📁 Models/                     # Data structures
├── 📁 Managers/                   # File operations
├── 📁 Views/                      # UI components
├── 📁 Tests/SampleFiles/         # Test with these
├── 📄 SETUP.md                    # Detailed setup
├── 📄 BUILDING.md                 # Build reference
└── 📄 README.md                   # Technical docs
```

## Support

- **Setup issues?** → See `SETUP.md`
- **Build errors?** → See `BUILDING.md`
- **Want to understand the code?** → See `README.md`
- **Check progress?** → See `IMPLEMENTATION_STATUS.md`

## What Works Right Now

| Feature | Status |
|---------|--------|
| Open G-code files | ✅ Working |
| Parse commands | ✅ Working |
| Display list | ✅ Working |
| Edit text | ✅ Working |
| 2D preview | ✅ Working |
| Save files | ✅ Working |
| Calculate bounds | ✅ Working |
| Estimate time | ✅ Working |
| USB connectivity | ⏳ Phase 2 |
| Image import | ⏳ Phase 3 |
| SVG import | ⏳ Phase 4 |

## Limitations

- 2D preview only (no 3D yet)
- Arcs displayed as lines
- Basic time estimates
- No undo/redo
- No printer/laser control (Phase 2)

## That's It!

You now have a working macOS G-code viewer and editor. Enjoy!

For detailed technical information, see the other documentation files in this directory.

---

**Questions?** Check the detailed docs or open an issue.  
**Contributing?** Read `CONTRIBUTING.md` (coming soon).  
**Curious?** Explore the C# source in `/LaserGRBL/` for reference.

