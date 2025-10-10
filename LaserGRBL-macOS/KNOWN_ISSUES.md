# Known Issues

This document tracks known bugs and issues in the LaserGRBL macOS application.

---

## Active Issues

### Text View Not Updating When Loading New File

**Priority**: Medium  
**Date Reported**: October 10, 2025  
**Component**: GCodeEditorView

**Description**:  
When viewing a G-code file in Text mode and then opening a different G-code file, the text editor continues to display the content of the original file. The new file's content only appears after switching to List view and back to Text view.

**Steps to Reproduce**:
1. Open a G-code file (e.g., `circle.gcode`)
2. Switch to Text view mode using the segmented control
3. Open a different G-code file (e.g., `square.gcode`)
4. Observe that the text still shows the first file's content
5. Switch to List view, then back to Text view
6. The second file's content now displays correctly

**Expected Behavior**:  
The text editor should immediately display the newly opened file's content, regardless of which view mode is active.

**Technical Notes**:
- Attempted fixes:
  - Adding `.id(file.id)` modifier to force view recreation
  - Using `.onChange(of: file.id)` to detect file changes
  - Using `.onChange(of: file.fileName)` to observe file property changes
  - Moving `.id()` modifier to different view hierarchy levels
- The issue suggests SwiftUI is not properly detecting the file change or the `@State private var editingText` is not updating correctly
- List view works correctly because it directly observes `file.commands` which is `@Published`

**Workaround**:  
Toggle between List and Text view modes after loading a new file.

**Related Files**:
- `LaserGRBL-macOS/Views/GCodeEditorView.swift`
- `LaserGRBL-macOS/Views/ContentView.swift`
- `LaserGRBL-macOS/Models/GCodeFile.swift`

---

## Resolved Issues

_(None yet)_

