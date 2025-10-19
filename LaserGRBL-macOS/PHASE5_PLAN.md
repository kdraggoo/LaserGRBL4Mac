# Phase 5: Feature Parity & Essential Enhancements

**LaserGRBL for macOS**

**Target Timeline**: 11 weeks  
**Status**: 📋 Planning  
**Date**: October 19, 2025

---

## Executive Summary

After analyzing the original Windows LaserGRBL application against the macOS implementation, identified **17 major feature gaps**. Phase 5 focuses on implementing the **8 most critical features** to achieve functional parity for production use, with emphasis on user experience through comprehensive help and tooltips.

**Note:** Phase 4 (SVG Vector Import) will be implemented separately and is not part of this plan.

## Current Status: macOS Implementation

### ✅ Completed (Phases 1-3)

- G-Code loading, editing, parsing, export
- 2D Canvas preview with zoom/pan
- USB Serial communication (ORSSerialPort)
- GRBL v1.1 protocol implementation
- Real-time status monitoring (5Hz)
- Machine control (jog, home, zero, pause/resume/stop)
- Console logging with TX/RX filtering
- Image import (6 formats: PNG, JPG, BMP, TIFF, GIF, HEIC)
- Raster conversion (9 dithering algorithms)
- G-code generation with optimization

### 🎯 Phase 5 Target Features

## Priority 1: Essential Features (Weeks 1-5)

### 1. Feed/Spindle/Rapid Overrides (Week 1)

**PC Reference:** `GrblCore.cs` lines 2859-2920, `LabelTB.cs`, `MainForm.cs` lines 641-672

**Requirements:**

- Real-time speed adjustment during job execution
  - Feed rate: 10-200% (1% increments, ±10% large steps)
  - Spindle/laser power: 10-200% (1% increments, ±10% large steps)
  - Rapid rate: 25%, 50%, 100% (discrete values)
- GRBL v1.1 realtime override commands (bytes 144-157)
- Parse override values from status reports: `Ov:100,100,100`
- Visual feedback: sliders with color coding (blue=slow, normal, red=fast)
- Keyboard shortcuts (⌘+ increase, ⌘- decrease, ⌘0 reset)

**Implementation:**

- Add to `GrblController.swift`:
  - `@Published var feedOverride: Int = 100`
  - `@Published var spindleOverride: Int = 100`
  - `@Published var rapidOverride: Int = 100`
  - `func setFeedOverride(_ percent: Int)` - sends bytes 144-148
  - `func setSpindleOverride(_ percent: Int)` - sends bytes 153-157
  - `func setRapidOverride(_ percent: Int)` - sends bytes 149-151
  - Parse `Ov:` prefix in status response

- Update `ControlPanelView.swift`:
  - Three slider controls in new "Overrides" section
  - Reset buttons for each override
  - Color-coded labels (10-99% blue, 100% default, 101-200% red)
  - Tooltip: "Adjust speed/power in real-time without stopping job"

**Impact:** Critical for fine-tuning jobs during execution without stopping

---

### 2. GRBL Configuration Editor (Weeks 2-3)

**PC Reference:** `GrblConfig.cs`, `GrblConfig.Designer.cs`

**Requirements:**

- Read all GRBL $$ settings ($0 through $132)
- Display in grouped, categorized table
- Edit individual settings with validation
- Write settings back to controller ($N=value format)
- Import/Export configuration (.json or .grbl files)
- Setting descriptions with detailed tooltips
- Error/Alarm code reference (errors 1-38, alarms 1-9)

**Settings Categories:**

1. **Stepper Settings** ($0-$2): Step pulse, idle delay, inversion
2. **Motion** ($3-$5): Direction inversion, soft limits, probe
3. **Limits** ($20-$27): Soft/hard limits, homing configuration
4. **Interface** ($10-$13): Status reports, units, arc tolerance
5. **Speeds & Feeds** ($110-$132): Max rates, accelerations, travel
6. **Spindle/Laser** ($30-$32): Max/min spindle speed, laser mode

**Implementation:**

- New `GrblSettings.swift` model:
  ```swift
  struct GrblSetting: Identifiable, Codable {
      let id: Int                    // $0, $1, etc.
      let name: String               // "Step pulse time"
      let description: String        // Full explanation
      let tooltip: String            // How it affects behavior
      var value: Double              // Current value
      let unit: String               // "µs", "mm/min", etc.
      let range: ClosedRange<Double>?
      let category: SettingCategory
      let grblVersion: String        // "1.1", "1.1f", etc.
  }
  
  enum SettingCategory {
      case stepper, motion, limits, interface, speedsFeeds, spindle
  }
  ```

- New `GrblSettingsView.swift`:
  - Grouped table view by category
  - Inline editing with validation
  - Import/Export buttons
  - Refresh button (re-read from controller)
  - Write All / Write Changed buttons
  - Search/filter capability

- Update `GrblController.swift`:
  - `func readSettings()` - sends $$
  - `func writeSetting(id: Int, value: Double)` - sends $N=value
  - Parse $$ response format: `$0=10`

**Impact:** Essential for initial machine setup and troubleshooting

---

### 3. Help System & Comprehensive Tooltips (Weeks 4-5)

**PC Reference:** Tooltips throughout UI, .resx resource strings

**Requirements:**

**A. Help Menu System:**

- Help → Quick Start Guide (opens web page or in-app viewer)
- Help → GRBL Settings Reference (searchable documentation)
- Help → Error & Alarm Codes (lookup table with solutions)
- Help → Material Recommendations (power/speed charts)
- Help → Keyboard Shortcuts (complete reference)
- Help → About LaserGRBL (version, credits, license)

**B. GRBL Settings Tooltips** (all 132 settings):

Examples:

- `$0` Step pulse: "Minimum pulse width (µs). Affects stepper driver compatibility. Too low may cause missed steps."
- `$10` Status report: "Bitmask for status report content. Default 1 = machine position."
- `$30` Max spindle speed: "Maximum S value (RPM or power units). Used for S word scaling."
- `$32` Laser mode: "Enable constant laser power during curves (1=on, 0=off). Critical for quality."
- `$110-$112` Max rate: "Maximum speed on each axis (mm/min). Exceeding causes errors."
- `$120-$122` Acceleration: "How quickly axis can change speed (mm/sec²). Higher = faster direction changes."

**C. UI Control Tooltips** (hover tooltips):

- All buttons: Action description
- All toggles/checkboxes: What they enable/disable + impact
- All sliders: Range explanation + effect on output
- All numeric inputs: Units and valid range
- Settings panel controls: How they affect laser result

**Tooltip Examples:**

- Grid toggle: "Show/hide 10mm grid overlay on preview"
- Zoom slider: "Preview magnification (10% - 400%)"
- DPI input: "Dots per inch - higher = finer detail, longer job time"
- Line interval: "Spacing between raster lines (mm) - smaller = better quality, slower"
- Dithering: "Convert grayscale to black/white pattern - simulates shading"
- Overscan: "Distance laser travels beyond image edges (mm) - prevents edge artifacts"
- Skip white: "Laser off for white pixels - faster jobs, less wear"
- Bidirectional: "Engrave left-to-right AND right-to-left - 50% faster"

**D. Error Code Reference:**

Built-in lookup for GRBL errors (1-38) and alarms (1-9):

- Error 1: "Expected command letter (G, M, $, etc.)"
- Error 2: "Bad number format"
- Error 9: "G-code locked during alarm or jog"
- Alarm 1: "Hard limit triggered - check limit switches"
- Alarm 2: "Soft limit exceeded - position outside work area"
- Each with "Solution" and "Prevention" tips

**Implementation:**

- New `HelpSystem.swift` manager:
  ```swift
  class HelpSystem {
      static let shared = HelpSystem()
      
      func settingTooltip(for id: Int) -> String
      func errorDescription(code: Int) -> String
      func alarmDescription(code: Int) -> String
      func controlTooltip(for control: String) -> String
  }
  ```

- New `HelpResources.swift`:
  - Complete setting descriptions (all $0-$132)
  - Error/alarm lookup tables
  - UI control tooltip strings

- Add `.help()` modifiers throughout SwiftUI views:
  ```swift
  Toggle("Grid", isOn: $showGrid)
      .help("Show/hide 10mm grid overlay on preview")
  
  Slider(value: $dpi, in: 50...1000)
      .help("Dots per inch - higher = finer detail, longer job")
  ```

- Update `ContentView.swift`:
  - Add Help menu to macOS menu bar
  - Menu items open help resources

**Impact:** Critical for user onboarding, dramatically reduces learning curve and support burden

---

## Priority 2: Enhanced Features (Weeks 6-8)

### 4. Material Database & Power-Speed Helper (Week 6-7)

**PC Reference:** `PSHelper/MaterialDB.cs`, `PSHelperForm.cs`

**Requirements:**

- Structured material database
- Hierarchy: Laser Model → Material → Thickness → Action
- Store recommended: Power (%), Speed (mm/min), Passes
- Quick-apply to current job
- Import from cloud/file
- Export/share custom presets
- Built-in presets for common scenarios

**Default Materials (20+ presets):**

- **Wood** (3mm, 6mm): Cut @ 80%, 500mm/min | Engrave @ 20%, 2000mm/min
- **Acrylic** (3mm, 6mm): Cut @ 60%, 300mm/min | Engrave @ 15%, 2500mm/min
- **Leather** (1mm, 2mm): Cut @ 40%, 800mm/min | Engrave @ 10%, 1500mm/min
- **Cardboard** (2mm, 4mm): Cut @ 30%, 1200mm/min | Engrave @ 8%, 3000mm/min
- **MDF** (3mm, 6mm): Cut @ 85%, 400mm/min | Engrave @ 25%, 1800mm/min
- **Cork** (3mm): Cut @ 35%, 900mm/min
- **Paper** (1mm): Cut @ 15%, 2000mm/min

**Implementation:**

- New `MaterialDatabase.swift`:
  ```swift
  struct MaterialPreset: Identifiable, Codable {
      let id: UUID
      let laserModel: String      // "Ortur LM2 20W", "K40", etc.
      let material: String        // "Wood", "Acrylic", etc.
      let thickness: Double       // mm
      let action: String          // "Cut", "Engrave", "Score"
      let power: Int              // 1-100%
      let speed: Int              // mm/min
      let passes: Int             // number of passes
      let remarks: String         // notes/tips
      var isCustom: Bool          // user-created vs built-in
  }
  
  class MaterialDatabase: ObservableObject {
      @Published var presets: [MaterialPreset] = []
      
      func loadDefaults()
      func importFromFile(url: URL)
      func exportToFile(url: URL)
      func filterBy(model: String, material: String)
  }
  ```

- New `MaterialDatabaseView.swift`:
  - Cascading pickers: Model → Material → Thickness → Action
  - Display recommended settings
  - "Apply to Job" button
  - Add/Edit/Delete custom presets
  - Import/Export buttons

**Impact:** Significantly improves workflow, reduces trial-and-error, prevents material waste

---

### 5. Custom Buttons (Week 8)

**PC Reference:** `CustomButton.cs`, `CustomButtonForm.cs`

**Requirements:**

- User-defined buttons executing custom G-code
- Three button types:
  - **Button:** Single-click executes G-code once
  - **TwoStateButton:** Toggle on/off (two G-code sequences)
  - **PushButton:** Hold to execute, release to stop
- Enable conditions:
  - Always, Connected, Idle, Run, IdleProgram
- Custom labels and icons (SF Symbols on macOS)
- Tooltips for each button
- Reorderable via drag-and-drop
- Import/Export button sets

**Common Use Cases:**

- Quick tool change: `M6 T1` (tool 1)
- Frame job: Low-power boundary trace
- Focus assist: Laser pulse for focusing
- Custom homing: Specific sequence
- Emergency commands: Custom stop/pause

**Implementation:**

- New `CustomButton.swift`:
  ```swift
  struct CustomButton: Identifiable, Codable {
      let id: UUID
      var label: String
      var gcode: String           // Primary G-code
      var gcode2: String?         // Secondary (for TwoState)
      var tooltip: String
      var icon: String            // SF Symbol name
      var buttonType: ButtonType
      var enableCondition: EnableCondition
      
      enum ButtonType { case button, twoState, push }
      enum EnableCondition { 
          case always, connected, idle, run, idleProgram 
      }
  }
  ```

- New `CustomButtonEditorView.swift`:
  - Form for creating/editing buttons
  - G-code text editor with syntax check
  - Icon picker (SF Symbols browser)
  - Type and condition selectors

- Update `ControlPanelView.swift`:
  - Horizontal scrolling button bar
  - Context menu: Edit, Delete, Reorder
  - "+" button to add new

**Impact:** Power users, specialized workflows, machine-specific operations

---

## Priority 3: Extended Features (Weeks 9-11)

### 6. WiFi/Network Connectivity (Week 9-10)

**PC Reference:** `ComWrapper/LaserWebESP8266.cs`, `WiFiConfigurator/`

**Requirements:**

- ESP8266 WebSocket: `ws://192.168.x.x:81/`
- Telnet: `192.168.x.x:23` (or custom port)
- Network device discovery
- Connection persistence (remember last IP)
- Fallback to USB if network fails

**Implementation:**

- New `NetworkConnectionManager.swift`:
  ```swift
  class NetworkConnectionManager: ObservableObject {
      @Published var connectionType: ConnectionType = .usb
      @Published var networkAddress: String = ""
      @Published var port: Int = 23
      
      enum ConnectionType { case usb, websocket, telnet }
      
      func connectWebSocket(address: String, port: Int)
      func connectTelnet(address: String, port: Int)
      func discoverDevices() -> [NetworkDevice]
  }
  ```

- Extend `SerialPortManager.swift`:
  - Abstract common interface for USB/Network
  - Protocol for send/receive regardless of transport

- New `NetworkConnectionView.swift`:
  - IP address input
  - Port selection
  - Protocol picker (WebSocket/Telnet)
  - Discover button
  - Test connection button

**Impact:** Enables wireless operation, eliminates USB cable constraints

---

### 7. Laser Life Tracking (Week 11)

**PC Reference:** `LaserUsage.cs`, `GrblCore.cs` LaserLifeHandler (lines 4315-4630)

**Requirements:**

- Track total runtime
- Track power-normalized usage time
- 10 power class buckets (1-10%, 11-20%, ..., 91-100%)
- Multiple laser module support
- Purchase/monitoring/death dates
- Average power factor calculation
- Usage charts and statistics

**Metrics:**

- **Runtime:** Total time machine in Run state
- **Active Time:** Time laser actually firing (>3% power)
- **Normalized Time:** Usage weighted by power (100% power = 1.0, 50% = 0.5)
- **Stress Time:** Time in 91-100% power range
- **Average Power:** Normalized / Active time

**Implementation:**

- New `LaserLifeTracker.swift`:
  ```swift
  class LaserLifeTracker: ObservableObject {
      @Published var modules: [LaserModule] = []
      @Published var currentModule: LaserModule?
      
      func recordUsage(power: Float, duration: TimeInterval)
      func calculateNormalizedTime() -> TimeInterval
      func powerDistribution() -> [Int: TimeInterval]
  }
  
  struct LaserModule: Identifiable, Codable {
      let id: UUID
      var name: String
      var brand: String
      var model: String
      var opticalPower: Double?      // Watts
      var purchaseDate: Date?
      var monitoringStartDate: Date
      var deathDate: Date?
      var lastUsed: Date?
      var runtime: TimeInterval
      var normalizedTime: TimeInterval
      var powerClasses: [TimeInterval] // 10 buckets
  }
  ```

- New `LaserLifeView.swift`:
  - Module selector
  - Statistics display
  - Power distribution chart
  - Add/Edit/Delete modules
  - Export statistics

- Integration in `GrblController.swift`:
  - Parse spindle/laser power from status: `FS:500,0`
  - Call `tracker.recordUsage()` during Run state

**Impact:** Maintenance planning, laser tube/diode replacement timing

---

### 8. Resume Job & Run from Position (Week 11)

**PC Reference:** `ResumeJobForm.cs`, `RunFromPositionForm.cs`

**Requirements:**

- Resume job after pause/stop/error
- Start from arbitrary line number
- Position verification before resume
- Option to re-sync machine position
- Warning if position has changed

**Implementation:**

- Update `GrblController.swift`:
  ```swift
  func resumeFromLine(_ lineNumber: Int)
  func runFromPosition(_ lineNumber: Int, syncPosition: Bool)
  func verifyPosition() -> Bool
  ```

- Update `ControlPanelView.swift`:
  - "Resume from Line..." button
  - Sheet with line number input
  - Position verification display
  - "Sync Position First" toggle

**Impact:** Recover from failures, power loss, emergency stops without full restart

---

## Implementation Architecture

### File Structure

**New Files:**

```
LaserGRBL-macOS/LaserGRBL/
├── Models/
│   ├── GrblSettings.swift           (132 setting definitions)
│   ├── MaterialDatabase.swift       (material presets)
│   ├── CustomButton.swift           (custom button model)
│   ├── LaserLifeTracker.swift       (usage tracking)
│   └── HelpResources.swift          (tooltips, descriptions)
├── Managers/
│   ├── NetworkConnectionManager.swift  (WebSocket/Telnet)
│   ├── ConfigurationManager.swift      (settings import/export)
│   └── HelpSystem.swift                (help lookup)
├── Views/
│   ├── GrblSettingsView.swift       (settings editor UI)
│   ├── MaterialDatabaseView.swift   (material selector)
│   ├── CustomButtonEditorView.swift (button creator)
│   ├── LaserLifeView.swift          (usage statistics)
│   └── NetworkConnectionView.swift  (WiFi setup)
```

**Modified Files:**

```
├── Views/
│   ├── ControlPanelView.swift       (+ overrides, custom buttons, resume)
│   ├── ContentView.swift            (+ settings tab, help menu)
│   ├── RasterSettingsView.swift    (+ tooltips)
│   ├── ImageImportView.swift       (+ tooltips)
│   └── GCodeEditorView.swift       (+ tooltips)
├── Managers/
│   ├── GrblController.swift         (+ overrides, settings, network, tracking)
│   └── SerialPortManager.swift      (+ network abstraction)
└── LaserGRBLApp.swift              (+ environment objects)
```

### Code Patterns

**Override Commands:**

```swift
// GRBL v1.1 realtime override bytes
enum OverrideCommand: UInt8 {
    case feedReset = 144      // 0x90
    case feedPlus10 = 145     // 0x91
    case feedMinus10 = 146    // 0x92
    case feedPlus1 = 147      // 0x93
    case feedMinus1 = 148     // 0x94
    
    case rapidReset = 149     // 0x95
    case rapid50 = 150        // 0x96
    case rapid25 = 151        // 0x97
    
    case spindleReset = 153   // 0x99
    case spindlePlus10 = 154  // 0x9A
    case spindleMinus10 = 155 // 0x9B
    case spindlePlus1 = 156   // 0x9C
    case spindleMinus1 = 157  // 0x9D
}
```

**Tooltip Helper:**

```swift
extension View {
    func helpTooltip(_ key: String) -> some View {
        self.help(HelpSystem.shared.tooltip(for: key))
    }
}

// Usage:
Toggle("Grid", isOn: $showGrid)
    .helpTooltip("preview.grid.toggle")
```

---

## Success Criteria

### Must Have (Phase 5 Complete):

- ✅ Override controls adjust feed/spindle/rapid in real-time
- ✅ Can read and write all GRBL $$ settings with validation
- ✅ Comprehensive help system with menu and tooltips
- ✅ Every control has descriptive tooltip explaining impact
- ✅ Material database with 20+ built-in presets
- ✅ Custom buttons execute user-defined G-code
- ✅ Can connect via WiFi (WebSocket or Telnet)
- ✅ Laser usage tracked with power-normalized metrics
- ✅ Can resume job from any line number

### Quality Bar:

- All tooltips clear, concise, actionable
- Help system searchable and comprehensive
- No crashes or data loss
- Settings validation prevents invalid values
- Network connection handles timeouts gracefully

---

## Timeline & Milestones

**Total Duration:** 11 weeks

| Week | Focus | Deliverables |
|------|-------|--------------|
| 1 | Overrides | ControlPanelView sliders, GrblController commands |
| 2-3 | GRBL Settings | GrblSettings model, GrblSettingsView UI, read/write |
| 4-5 | Help System | HelpResources, tooltips throughout app, Help menu |
| 6-7 | Material DB | MaterialDatabase model, MaterialDatabaseView UI |
| 8 | Custom Buttons | CustomButton model, editor, button bar |
| 9-10 | WiFi | NetworkConnectionManager, WebSocket/Telnet |
| 11 | Life+Resume | LaserLifeTracker, resume controls |

**Checkpoints:**

- Week 3: Priority 1 features testable
- Week 5: All tooltips and help content complete
- Week 8: Priority 2 features complete
- Week 11: Full Phase 5 integration testing

---

## Risk Assessment

**Low Risk:**

- Overrides (GRBL protocol well-documented)
- Settings editor (straightforward read/write)
- Material database (local data, no dependencies)
- Tooltips (SwiftUI .help() modifier)

**Medium Risk:**

- Help system (content creation time-intensive)
- Custom buttons (UI/UX complexity, state management)
- WiFi connectivity (network stack, firewall, discovery)
- Laser tracking (accurate power measurement from status)

**Mitigation:**

- Help content: Prioritize most-used features first
- Custom buttons: Start with simple button type, add advanced later
- WiFi: Test with ESP8266 emulator before hardware
- Tracking: Validate against PC app metrics

---

## Testing Strategy

### Unit Tests:

- Override command generation
- Settings validation logic
- Material database queries
- Custom button conditions

### Integration Tests:

- Override commands with real GRBL controller
- Settings read/write cycles
- Network connection (WebSocket/Telnet)
- Resume from various positions

### User Acceptance:

- All tooltips reviewed for clarity
- Help system searchable and complete
- Material presets tested on real materials
- Custom buttons work in all states

---

## Post-Phase 5 Roadmap

**Phase 6:** Advanced Features (Future)

- 3D OpenGL preview (SceneKit/Metal)
- Multiple firmware support (Smoothie, Marlin)
- Image vectorization (Potrace port)
- Advanced recovery features

**Phase 7:** Polish & Distribution (Future)

- Multi-language support (15+ languages)
- Auto-update system (GitHub releases)
- Color schemes/themes (safety glass optimization)
- macOS App Store preparation
- Code signing and notarization

**Not Planned:**

- GRBL Emulator (development tool only)
- Usage statistics upload (privacy concerns)
- Multi-run feature (edge case, workaround exists)

---

## Documentation Deliverables

After Phase 5 completion:

1. **PHASE5_COMPLETE.md** - Feature summary and accomplishments
2. **PHASE5_INTEGRATION_GUIDE.md** - Setup and testing instructions
3. **HELP_CONTENT.md** - All help text and tooltips reference
4. **SETTINGS_REFERENCE.md** - Complete GRBL $$ settings guide
5. **MATERIAL_PRESETS.md** - Default materials database
6. Updated **IMPLEMENTATION_STATUS.md** - Overall project progress
7. Updated **README.md** - Phase 5 completion notice

---

## Notes & Constraints

- **PC Application Reference:** All implementations reference original C# code in `LaserGRBL/` directory
- **GRBL Protocol:** Strict adherence to GRBL v1.1 specification
- **macOS Design:** Follow Apple Human Interface Guidelines for all UI
- **Testing:** Each feature requires hardware testing with real GRBL controller
- **Backward Compatibility:** Maintain full compatibility with Phases 1-3 features
- **Performance:** No degradation in responsiveness or real-time status updates
- **Accessibility:** All tooltips and help text screen-reader compatible

---

**Status:** Planning Complete - Ready for Approval  
**Created:** October 19, 2025  
**Target Start:** TBD  
**Estimated Completion:** +11 weeks from start  
**Dependencies:** Phases 1-3 complete, Phase 4 (SVG) independent

