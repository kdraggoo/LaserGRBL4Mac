//
//  HelpResources.swift
//  LaserGRBL for macOS
//
//  Comprehensive help content, tooltips, and documentation
//

import Foundation

/// Static help resources database
struct HelpResources {
    
    // MARK: - UI Control Tooltips
    
    static let tooltips: [String: String] = [
        // Preview Controls
        "preview.grid.toggle": "Show/hide 10mm grid overlay on preview canvas",
        "preview.zoom": "Preview magnification (10% - 400%). Use scroll wheel or pinch gesture to zoom.",
        "preview.pan": "Click and drag to pan around the preview",
        "preview.fit": "Fit entire G-code path in view",
        "preview.reset": "Reset zoom and pan to default view",
        
        // Raster Settings
        "raster.dpi": "Dots per inch - higher values create finer detail but increase job time. Range: 50-1000 DPI. Typical: 254 DPI (0.1mm).",
        "raster.lineInterval": "Spacing between raster scan lines in millimeters. Smaller = better quality but slower. Typical: 0.1mm.",
        "raster.dithering": "Convert grayscale image to black/white pattern that simulates shading. Essential for photo engraving.",
        "raster.overscan": "Distance laser travels beyond image edges (mm) to prevent acceleration artifacts at boundaries. Typical: 3-5mm.",
        "raster.skipWhite": "Laser turns off for white pixels - speeds up jobs and reduces laser wear. Always recommended.",
        "raster.bidirectional": "Engrave both left-to-right AND right-to-left passes. 50% faster but may cause slight alignment offset.",
        "raster.laserPower": "Laser power percentage (1-100%). Start low and test. Typical: 10-30% for engraving.",
        "raster.feedRate": "Speed of laser movement in mm/min. Faster = lighter engraving. Typical: 1000-3000 mm/min.",
        "raster.direction": "Scan direction: Horizontal (faster for wide images) or Vertical (faster for tall images)",
        "raster.quality": "Balance between speed and quality. High quality uses finer settings.",
        
        // Vector Settings
        "vector.strokeSpeed": "Speed for cutting/engraving vector paths in mm/min. Slower = deeper cuts. Typical: 300-1000 mm/min.",
        "vector.strokePower": "Laser power for vector paths (1-100%). Higher = deeper cuts. Test on scrap material first.",
        "vector.fillEnable": "Fill closed shapes with raster pattern",
        "vector.fillLineSpacing": "Distance between fill lines in mm. Smaller = more solid fill. Typical: 0.1-0.5mm.",
        "vector.passes": "Number of times to repeat the path. Multiple passes for cutting thick materials.",
        "vector.cornerMode": "How to handle sharp corners: Round (faster) or Exact (more accurate)",
        
        // Connection
        "connection.port": "USB serial port connected to GRBL controller. Refresh if port not listed.",
        "connection.baudRate": "Communication speed. GRBL default is 115200. Must match controller firmware.",
        "connection.connect": "Establish connection to GRBL controller",
        "connection.disconnect": "Close connection to GRBL controller",
        
        // Control Panel
        "control.jog.distance": "Distance to move for each jog button press",
        "control.jog.feedrate": "Speed of jogging movement in mm/min",
        "control.home": "Move to home position using limit switches (requires $22=1)",
        "control.zero": "Set current position as work zero (0,0,0)",
        "control.goto.zero": "Move to work zero position",
        "control.clear.alarm": "Clear alarm state and unlock GRBL",
        "control.pause": "Pause job execution (feed hold). Can be resumed.",
        "control.resume": "Resume paused job from current position",
        "control.stop": "Emergency stop - resets GRBL and clears job queue. Cannot be resumed.",
        
        // Override Controls
        "override.feed": "Adjust feed rate speed in real-time without stopping job (10-200%). Does NOT save to G-code.",
        "override.spindle": "Adjust laser/spindle power in real-time (10-200%). Use to fine-tune without stopping.",
        "override.rapid": "Adjust rapid (non-cutting) movement speed. 25%, 50%, or 100% only.",
        "override.reset": "Reset override back to 100% (normal speed/power)",
        
        // File Operations
        "file.open": "Open existing G-code file (.nc, .gcode, .tap)",
        "file.save": "Save current G-code file",
        "file.saveas": "Save G-code to new file",
        "file.new": "Create new empty G-code file",
        "file.export": "Export G-code with custom format options",
        
        // Import
        "import.image": "Import raster image (PNG, JPG, BMP, TIFF, GIF, HEIC) for laser engraving",
        "import.svg": "Import vector graphics (SVG) for cutting or engraving",
        "import.preview": "Preview how the import will look before converting to G-code",
        "import.generate": "Convert imported file to G-code with current settings",
        
        // Console
        "console.command": "Send custom G-code or GRBL command directly to controller",
        "console.clear": "Clear console log history",
        "console.filter.tx": "Show transmitted commands",
        "console.filter.rx": "Show received responses",
        "console.filter.status": "Show status updates",
        
        // Settings
        "settings.read": "Read all GRBL settings from controller ($$)",
        "settings.write": "Write all changed settings to controller",
        "settings.write.single": "Write this single setting to controller",
        "settings.import": "Import settings from .json file",
        "settings.export": "Export current settings to .json file",
        "settings.reset": "Reset all settings to defaults (does not write to controller)",
    ]
    
    // MARK: - GRBL Error Codes
    
    static let errors: [Int: ErrorHelp] = [
        1: ErrorHelp(
            code: 1,
            name: "Expected Command Letter",
            description: "G-code words consist of a letter and a value. Letter was not found.",
            solution: "Check G-code syntax. Each command needs a letter (G, M, F, S, etc.) followed by a number.",
            prevention: "Validate G-code before sending. Use a G-code validator or tested generator."
        ),
        2: ErrorHelp(
            code: 2,
            name: "Bad Number Format",
            description: "Numeric value format is not valid or missing an expected value.",
            solution: "Check that all command parameters are valid numbers with correct decimal format.",
            prevention: "Ensure G-code generator produces properly formatted numbers. Avoid special characters."
        ),
        3: ErrorHelp(
            code: 3,
            name: "Invalid Statement",
            description: "Grbl '$' system command was not recognized or supported.",
            solution: "Verify the $ command is valid for GRBL v1.1. Check documentation for supported commands.",
            prevention: "Only use documented GRBL commands. Refer to GRBL v1.1 documentation."
        ),
        9: ErrorHelp(
            code: 9,
            name: "G-code Lock",
            description: "G-code commands cannot be executed while in alarm state or during homing.",
            solution: "Send $X to unlock after alarm. Wait for homing to complete before sending G-code.",
            prevention: "Clear alarms before sending jobs. Don't send commands during homing cycle."
        ),
        10: ErrorHelp(
            code: 10,
            name: "Soft Limit Error",
            description: "Soft limits cannot be enabled without homing also enabled.",
            solution: "Enable homing cycle first ($22=1), then enable soft limits ($20=1).",
            prevention: "Always enable homing before enabling soft limits."
        ),
        20: ErrorHelp(
            code: 20,
            name: "Soft Limit Exceeded",
            description: "Motion command would exceed soft limit boundaries.",
            solution: "Check work position. Reduce size of job or reposition within work area ($130-$132).",
            prevention: "Verify job fits within soft limit boundaries before starting. Use preview."
        ),
        24: ErrorHelp(
            code: 24,
            name: "Modal Group Violation",
            description: "Two G-code commands from the same modal group cannot be on the same line.",
            solution: "Split commands onto separate lines. Each line should have only one motion command (G0, G1, etc.).",
            prevention: "Follow G-code syntax rules. One motion mode per line."
        ),
        33: ErrorHelp(
            code: 33,
            name: "Axis Words Exist",
            description: "Arc command cannot be executed because no offsets were included.",
            solution: "Arc commands (G2/G3) require I, J, K offset values or R radius value.",
            prevention: "Ensure arc generator includes proper I/J/K or R values."
        ),
    ]
    
    // MARK: - GRBL Alarm Codes
    
    static let alarms: [Int: AlarmHelp] = [
        1: AlarmHelp(
            code: 1,
            name: "Hard Limit Triggered",
            description: "Machine hit a hard limit switch during motion.",
            solution: "1. Carefully jog away from limit switch. 2. Send $X to clear alarm. 3. Re-home machine ($H).",
            prevention: "Ensure job fits within work area. Enable soft limits ($20=1) to prevent hard limit hits."
        ),
        2: AlarmHelp(
            code: 2,
            name: "Soft Limit Exceeded",
            description: "Motion command attempted to exceed soft limit boundaries.",
            solution: "1. Clear alarm with $X. 2. Reposition job within work area or adjust soft limits ($130-$132).",
            prevention: "Preview jobs before running. Ensure work area settings match your machine's actual travel."
        ),
        3: AlarmHelp(
            code: 3,
            name: "Reset During Motion",
            description: "Grbl was reset while in motion (safety feature).",
            solution: "1. Clear alarm with $X. 2. Verify machine position. 3. Resume job or restart from safe position.",
            prevention: "Avoid resetting controller during jobs. Use pause/resume for temporary stops."
        ),
        4: AlarmHelp(
            code: 4,
            name: "Probe Fail - Initial",
            description: "Probe is already triggered when probing command started.",
            solution: "1. Check probe wiring and connection. 2. Move probe away from contact. 3. Clear alarm with $X.",
            prevention: "Ensure probe is not in contact before starting probe cycle."
        ),
        5: AlarmHelp(
            code: 5,
            name: "Probe Fail - Contact",
            description: "Probe cycle failed to make contact within travel distance.",
            solution: "1. Check probe placement and wiring. 2. Increase probe distance. 3. Clear alarm with $X.",
            prevention: "Verify probe is positioned correctly and within expected contact distance."
        ),
        6: AlarmHelp(
            code: 6,
            name: "Homing Fail - Reset",
            description: "Homing cycle was interrupted by reset command.",
            solution: "1. Clear alarm with $X. 2. Restart homing cycle ($H). 3. Do not interrupt homing.",
            prevention: "Allow homing cycle to complete fully. Don't send commands during homing."
        ),
        7: AlarmHelp(
            code: 7,
            name: "Homing Fail - Door",
            description: "Safety door was opened during homing cycle.",
            solution: "1. Close safety door. 2. Clear alarm with $X. 3. Restart homing cycle ($H).",
            prevention: "Keep safety door closed during homing. Check door switch wiring."
        ),
        8: AlarmHelp(
            code: 8,
            name: "Homing Fail - Pull-off",
            description: "Limit switch did not clear during homing pull-off move.",
            solution: "1. Check limit switch wiring. 2. Increase pull-off distance ($27). 3. Clear alarm and retry.",
            prevention: "Verify limit switches work properly. Increase $27 if needed (typical: 1-5mm)."
        ),
        9: AlarmHelp(
            code: 9,
            name: "Homing Fail - Approach",
            description: "Limit switch was not triggered within expected distance.",
            solution: "1. Check limit switch wiring and position. 2. Verify $130-$132 match actual travel. 3. Clear and retry.",
            prevention: "Ensure limit switches are properly installed and positioned. Check travel settings."
        ),
    ]
    
    // MARK: - Material Recommendations
    
    static let materialGuide = """
    LASER ENGRAVING & CUTTING GUIDE
    
    ⚠️ SAFETY WARNING: Always test on scrap material first. Use proper ventilation and eye protection.
    
    WOOD (Hardwood):
    • 3mm Engrave: 20% power, 2000 mm/min
    • 3mm Cut: 80% power, 500 mm/min, 2-3 passes
    • 6mm Cut: 100% power, 300 mm/min, 3-4 passes
    • Tips: Maple and cherry engrave beautifully. Avoid resinous woods.
    
    PLYWOOD:
    • 3mm Engrave: 15% power, 2500 mm/min
    • 3mm Cut: 70% power, 600 mm/min, 2 passes
    • Tips: Quality varies - test first. Watch for glue layers.
    
    ACRYLIC (Cast):
    • 3mm Engrave: 10% power, 3000 mm/min
    • 3mm Cut: 60% power, 300 mm/min, 1 pass
    • 6mm Cut: 80% power, 200 mm/min, 2 passes
    • Tips: Cast acrylic better than extruded. Creates frosted white engraving.
    
    LEATHER:
    • 1-2mm Engrave: 8% power, 2000 mm/min
    • 1-2mm Cut: 40% power, 800 mm/min
    • Tips: Natural leather only. Avoid chrome-tanned (toxic fumes).
    
    CARDBOARD/PAPER:
    • Engrave: 5% power, 3000 mm/min
    • Cut: 15-30% power, 1500 mm/min
    • Tips: Highly flammable - watch carefully. Multiple light passes better than one heavy.
    
    MDF:
    • 3mm Engrave: 25% power, 1800 mm/min
    • 3mm Cut: 85% power, 400 mm/min, 2-3 passes
    • Tips: Creates darker contrast than plywood. Good air filtration needed.
    
    ❌ NEVER LASER THESE:
    • PVC/Vinyl (releases chlorine gas - deadly!)
    • Polycarbonate/Lexan (releases toxic gas, catches fire)
    • ABS (releases cyanide gas)
    • Fiberglass (releases particles)
    • Coated Carbon Fiber (toxic)
    • Any unknown plastic
    
    GENERAL TIPS:
    • Always enable laser mode ($32=1)
    • Start with 50% of recommended power and test
    • Multiple light passes better than one heavy pass
    • Use air assist for cleaner cuts
    • Keep fire extinguisher nearby
    • Never leave laser unattended
    """
    
    // MARK: - Keyboard Shortcuts
    
    static let keyboardShortcuts = """
    LASERGRBL KEYBOARD SHORTCUTS
    
    FILE OPERATIONS:
    ⌘O - Open G-code file
    ⌘S - Save file
    ⌘⇧S - Save As
    ⌘I - Import Image
    ⌘V - Import SVG
    ⌘N - New File
    
    CONTROL:
    ⌘P - Pause/Resume job
    ⌘. - Stop job (Emergency stop)
    ⌘H - Home machine
    ⌘0 - Go to work zero
    
    OVERRIDES:
    ⌘+ - Increase feed rate 10%
    ⌘- - Decrease feed rate 10%
    ⌥⌘+ - Increase feed rate 1%
    ⌥⌘- - Decrease feed rate 1%
    ⌘R - Reset all overrides to 100%
    
    VIEW:
    ⌘1 - G-Code tab
    ⌘2 - Import tab
    ⌘3 - Control tab
    ⌘4 - Settings tab
    ⌘5 - Console tab
    ⌘F - Fit preview in window
    
    EDITING:
    ⌘Z - Undo
    ⌘⇧Z - Redo
    ⌘X - Cut
    ⌘C - Copy
    ⌘V - Paste
    ⌘A - Select All
    """
}

