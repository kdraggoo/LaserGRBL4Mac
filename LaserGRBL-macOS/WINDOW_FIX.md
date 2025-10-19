# Window Display Fix

## Problem
When launching the app, only the "Raster Settings" window appeared instead of the main application window.

## Root Cause
The app was trying to create a separate `Window` scene for raster settings that referenced a non-existent `RasterSettingsWindowView`, causing window management issues.

## Solution
**Removed the separate Raster Settings window** and integrated the settings directly into the main app interface as a sidebar panel, similar to the Vector Import view.

## Changes Made

### 1. LaserGRBLApp.swift
- **Removed** the separate `Window("Raster Settings")` scene
- Now only creates the main `WindowGroup` with `ContentView`

### 2. ImageImportView.swift
- **Removed** `@Environment(\.openWindow)` reference
- **Added** `@State private var showSettings = true` to control sidebar visibility
- **Wrapped** main content in `HSplitView` with integrated `RasterSettingsView` sidebar
- **Changed** the settings button from opening a window to toggling the sidebar visibility

## Benefits
✅ **Simpler architecture** - Single main window instead of multiple windows
✅ **Better UX** - Settings are immediately visible in context
✅ **Consistency** - Matches the Vector Import interface pattern
✅ **No window management issues** - Everything in one window

## Testing
After building, you should now see:
1. ✅ Main application window with all tabs (G-Code, Vector, Image, Control, Console)
2. ✅ Raster settings visible as a sidebar in the Image tab
3. ✅ Settings can be toggled with the sidebar button in the toolbar

## Additional Fixes

### Vector Settings Scrolling Issue
**Problem**: The Vector Settings sidebar couldn't scroll down to see all options.

**Solution**: Added proper constraints to ensure the ScrollView can expand:
- Added `.frame(maxHeight: .infinity)` to allow the ScrollView to fill available space
- Added extra bottom padding (`Color.clear.frame(height: 20)`) to ensure the last items are fully visible when scrolled to the bottom

## Note
The `RasterSettingsWindowView` struct still exists in `RasterSettingsView.swift` but is no longer used. It can be safely removed in a future cleanup if desired.

