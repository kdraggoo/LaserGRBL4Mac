# Known Issues

This document tracks known bugs and issues in the LaserGRBL macOS application.

---

## Active Issues

_(None currently)_

---

## Resolved Issues

### Text View Not Updating When Loading New File ✅

**Priority**: Medium  
**Date Reported**: October 10, 2025  
**Date Resolved**: October 10, 2025  
**Component**: GCodeEditorView, ContentView

**Description**:  
When viewing a G-code file in Text mode and then opening a different G-code file, the text editor continued to display the content of the original file. The new file's content only appeared after switching to List view and back to Text view.

**Root Cause**:  
When `GCodeFileManager.loadFile()` is called, it creates a new `GCodeFile` object with a new ID. However, SwiftUI wasn't detecting that the file object reference had changed because `GCodeEditorView` receives it as an `@ObservedObject` parameter. SwiftUI only observes property changes within the object, not the object reference itself changing.

**Solution**:  
Added `.id(file.id)` modifiers to both `GCodeEditorView` and `GCodePreviewView` in `ContentView.swift`. This forces SwiftUI to completely recreate both views when a new file object is loaded, ensuring all state (including `editingText`) is properly initialized for the new file.

**Related Files**:
- `LaserGRBL-macOS/LaserGRBL/Views/ContentView.swift` (lines 26, 31)
- `LaserGRBL-macOS/LaserGRBL/Managers/GCodeFileManager.swift` (creates new file objects)

