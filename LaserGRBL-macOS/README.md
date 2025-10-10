# LaserGRBL for macOS - Swift/SwiftUI Implementation

This is a native macOS port of LaserGRBL built with Swift and SwiftUI, optimized for Apple Silicon (M1/M2/M3) Macs.

## Project Structure

```
LaserGRBL-macOS/
├── LaserGRBLApp.swift          # Main app entry point
├── Models/
│   ├── GCodeCommand.swift       # G-code command model
│   └── GCodeFile.swift          # File management
├── Managers/
│   └── GCodeFileManager.swift   # File operations
├── Views/
│   ├── ContentView.swift        # Main application view
│   ├── GCodeEditorView.swift    # List/text editor
│   ├── GCodePreviewView.swift   # 2D canvas preview
│   └── FileInfoView.swift       # File information sheet
└── Info.plist                   # App configuration
```

## Building the Project

### Requirements
- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Setup

1. Open Xcode
2. Create a new macOS App project:
   - Product Name: LaserGRBL
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployment: macOS 13.0

3. Replace the default files with the files in this directory

4. Add these files to your Xcode project:
   - LaserGRBLApp.swift
   - All files in Models/, Managers/, and Views/ folders
   - Info.plist

5. Configure the project:
   - Set Bundle Identifier: `com.yourname.LaserGRBL`
   - Enable App Sandbox (for distribution)
   - Enable User Selected Files (Read/Write)
   - Enable Hardened Runtime

### Quick Import to Xcode

Run these commands to set up the proper Xcode project structure:

```bash
cd "/Volumes/Development (Case Sense)/Projects/LaserGRBL4Mac/LaserGRBL4Mac"

# Create Xcode project (you'll need to do this manually in Xcode)
# File > New > Project > macOS > App
# - Name: LaserGRBL
# - Interface: SwiftUI
# - Save in: LaserGRBL-macOS/
```

## Features Implemented (Phase 1)

### Core Functionality
- ✅ G-code command parsing (G0, G1, G2, G3, M3, M4, M5, etc.)
- ✅ File loading (.gcode, .nc, .tap files)
- ✅ File saving with header/footer
- ✅ Bounding box calculation
- ✅ Estimated time calculation

### User Interface
- ✅ Main split view layout
- ✅ Command list view with syntax highlighting
- ✅ Text editor with live updates
- ✅ 2D preview canvas
- ✅ File information dialog
- ✅ Welcome screen

### Preview Features
- ✅ Toolpath visualization
- ✅ Grid display
- ✅ Bounding box overlay
- ✅ Zoom and pan controls
- ✅ Origin marker

## Testing

### Sample G-Code Files

Test files are located in `Tests/SampleFiles/`:
- `square.gcode` - Simple square test
- `circle.gcode` - Circular motion test
- `engraving.gcode` - Complex engraving pattern

### Manual Testing

1. Run the app in Xcode (⌘R)
2. Click "Open G-Code File"
3. Select a test file
4. Verify:
   - Commands load correctly
   - Preview displays the toolpath
   - File info shows correct statistics
   - Can edit and save changes

## Architecture

### MVVM Pattern
- **Models**: `GCodeCommand`, `GCodeFile`
- **ViewModels**: `GCodeFileManager` (ObservableObject)
- **Views**: SwiftUI views with `@ObservedObject` bindings

### Key Design Decisions

1. **Async/Await**: File loading uses modern Swift concurrency
2. **Canvas API**: Preview uses SwiftUI Canvas for performance
3. **Protocol-Oriented**: Extensible command parsing system
4. **Value Types**: Structs for commands (immutable by default)

## Next Steps (Phase 2)

### USB Serial Connectivity
- [ ] Integrate ORSSerialPort library
- [ ] Implement GRBL streaming protocol
- [ ] Add serial port selection UI
- [ ] Real-time status display
- [ ] Command queue visualization

### Planned Dependencies
```swift
dependencies: [
    .package(url: "https://github.com/armadsen/ORSSerialPort", from: "2.1.0")
]
```

## Known Limitations

- No Z-axis visualization yet (2D only)
- Arc commands (G2/G3) displayed as lines
- Time estimation is approximate
- No undo/redo support yet

## Contributing

This is a port of the Windows LaserGRBL application. Core algorithms and logic are adapted from:
- Original: https://github.com/arkypita/LaserGRBL
- License: GPLv3

## License

This project inherits the GPLv3 license from the original LaserGRBL project.

