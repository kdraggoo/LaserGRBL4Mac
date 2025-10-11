# Phase 2 Setup Guide

**LaserGRBL for macOS - USB Serial & GRBL Control**

This guide will help you integrate Phase 2 (USB Serial Connectivity) into your Xcode project.

---

## Prerequisites

- ✅ Phase 1 already set up (see QUICKSTART.md)
- ✅ Xcode 15.0 or later
- ✅ macOS 13.0+ target
- ✅ USB GRBL device (optional, for testing)

---

## Step 1: Add ORSSerialPort Dependency

Phase 2 requires the ORSSerialPort library for USB serial communication.

### Option A: Swift Package Manager (Recommended)

1. Open your project in Xcode
2. **File → Add Package Dependencies...**
3. Enter URL: `https://github.com/armadsen/ORSSerialPort`
4. Select "Up to Next Major Version"
5. Click "Add Package"
6. Select "LaserGRBL" target
7. Click "Add Package"

### Option B: Manual Installation

If SPM doesn't work:

1. Clone ORSSerialPort: `git clone https://github.com/armadsen/ORSSerialPort.git`
2. Drag `Source/ORSSerial.framework` into your Xcode project
3. Add to "Frameworks, Libraries, and Embedded Content"

---

## Step 2: Add Phase 2 Files to Xcode

All Phase 2 files have been created. Now add them to your Xcode project:

### New Model Files
1. Drag `Models/GrblCommand.swift` into Xcode Models folder
2. Drag `Models/GrblResponse.swift` into Xcode Models folder

### New Manager Files
1. Drag `Managers/SerialPortManager.swift` into Xcode Managers folder
2. Drag `Managers/GrblController.swift` into Xcode Managers folder

### New View Files
1. Drag `Views/ConnectionView.swift` into Xcode Views folder
2. Drag `Views/ControlPanelView.swift` into Xcode Views folder
3. Drag `Views/ConsoleView.swift` into Xcode Views folder

### Updated Files (already in Xcode)
- `LaserGRBLApp.swift` - Updated with new managers
- `Views/ContentView.swift` - Updated with tab navigation

**Important:** Make sure to check "Add to targets: LaserGRBL" when adding files!

---

## Step 3: Verify Entitlements

Phase 2 requires USB serial port access. Check `LaserGRBL.entitlements`:

```xml
<!-- USB/Serial Port Access -->
<key>com.apple.security.device.serial</key>
<true/>
```

✅ This is already configured in the entitlements file!

---

## Step 4: Build & Run

1. **Clean Build Folder**: ⌘ + Shift + K
2. **Build**: ⌘ + B
3. **Run**: ⌘ + R

### Expected Build Time
- First build: ~2-3 minutes (ORSSerialPort compilation)
- Subsequent builds: ~30 seconds

---

## Step 5: Test Phase 2 Features

### Without Hardware

You can test the UI without a GRBL device:

1. **Launch app** - You should see updated UI with tabs
2. **Check sidebar** - Connection panel should be at top
3. **Switch tabs:**
   - G-Code tab (Phase 1 features)
   - Control tab (machine controls)
   - Console tab (communication log)
4. **Port selection** - Click "Refresh Ports" to see available ports

### With GRBL Hardware

If you have a GRBL device connected:

1. **Connect USB cable** to your GRBL device
2. **Launch app**
3. **Sidebar → Connection:**
   - Click "Refresh Ports"
   - Select your device (usually `/dev/cu.usbserial-...` or `/dev/cu.usbmodem...`)
   - Choose baud rate (usually 115200)
   - Click "Connect"
4. **Watch console** - Should see "Grbl X.X" startup message
5. **Check status** - Sidebar should show machine state and position
6. **Switch to Control tab** - Try jogging (if homing not required)
7. **Test commands:**
   - Jog controls (if safe)
   - Status query (automatic)
   - Console logging

---

## Common Issues

### ORSSerialPort Not Found

**Problem:** Build error: `Cannot find 'ORSSerialPort' in scope`

**Solution:**
1. File → Add Package Dependencies
2. Re-add ORSSerialPort package
3. Clean build folder (⌘ + Shift + K)
4. Build again

### Serial Port Permission Denied

**Problem:** Cannot open serial port

**Solution:**
1. Check entitlements file has `com.apple.security.device.serial` = `true`
2. Try disabling App Sandbox temporarily for testing:
   - LaserGRBL.entitlements → Set `com.apple.security.app-sandbox` to `false`
3. Restart Xcode and rebuild

### No Ports Found

**Problem:** Port list is empty

**Solution:**
1. Check USB device is connected
2. Open Terminal and run: `ls /dev/cu.*`
3. You should see your device listed
4. Click "Refresh Ports" in the app
5. Try restarting the app

### GRBL Not Responding

**Problem:** Connected but no response

**Solution:**
1. Check baud rate (try 115200, 9600, 57600)
2. Check console for error messages
3. Try disconnecting and reconnecting
4. Press soft reset (^X) in console
5. Power cycle GRBL device

---

## File Structure After Phase 2

```
LaserGRBL-macOS/LaserGRBL/
├── LaserGRBLApp.swift (updated)
├── Models/
│   ├── GCodeCommand.swift (Phase 1)
│   ├── GCodeFile.swift (Phase 1)
│   ├── GrblCommand.swift (Phase 2) ← NEW
│   └── GrblResponse.swift (Phase 2) ← NEW
├── Managers/
│   ├── GCodeFileManager.swift (Phase 1)
│   ├── SerialPortManager.swift (Phase 2) ← NEW
│   └── GrblController.swift (Phase 2) ← NEW
└── Views/
    ├── ContentView.swift (updated)
    ├── GCodeEditorView.swift (Phase 1)
    ├── GCodePreviewView.swift (Phase 1)
    ├── FileInfoView.swift (Phase 1)
    ├── ConnectionView.swift (Phase 2) ← NEW
    ├── ControlPanelView.swift (Phase 2) ← NEW
    └── ConsoleView.swift (Phase 2) ← NEW
```

---

## What's Working

After Phase 2 setup, you should have:

✅ **Connection Management**
- USB serial port discovery
- Connect/disconnect to GRBL
- Connection status display
- Real-time status updates (5Hz)

✅ **Machine Control**
- XY jog pad with configurable distance
- Z-axis up/down controls
- Home machine command
- Zero work position
- Go to work zero
- Clear alarm

✅ **Console Logging**
- All TX/RX communication logged
- Timestamped entries
- Filterable by type (All, Sent, Received, Errors)
- Auto-scroll option
- Text selection/copy

✅ **GRBL Protocol**
- Command queue management
- Automatic buffer control (15 commands)
- Response matching
- Error handling
- Status parsing
- Position tracking

---

## Next Steps

1. **Test thoroughly** with your GRBL device
2. **Report any issues** you encounter
3. **Read PHASE2_COMPLETE.md** for detailed feature list
4. **Wait for Phase 3** - Image import and raster conversion

---

## Support

- **Integration issues?** → See this guide
- **Build errors?** → Check Common Issues section
- **GRBL not working?** → Check baud rate and connections
- **Want to understand the code?** → See PHASE2_COMPLETE.md

---

## Quick Test Checklist

- [ ] App builds without errors
- [ ] Three tabs visible (G-Code, Control, Console)
- [ ] Connection panel in sidebar
- [ ] Can see available serial ports
- [ ] Can connect to GRBL device (if available)
- [ ] Status updates in sidebar
- [ ] Console shows TX/RX messages
- [ ] Jog controls visible in Control tab
- [ ] Can send commands
- [ ] Can pause/resume/stop

---

**Phase 2 Setup Complete!**

You now have a fully functional GRBL controller for macOS! 🎉

*For detailed feature information, see [PHASE2_COMPLETE.md](PHASE2_COMPLETE.md)*

