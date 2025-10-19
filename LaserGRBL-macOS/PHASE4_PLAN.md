# Phase 4: SVG Vector Import & Path Conversion

**LaserGRBL for macOS**

**Target Timeline**: 6 weeks  
**Status**: 📋 Planning  
**Date**: October 19, 2025

---

## Overview

Implement SVG file import with Bézier curve to G-code conversion, enabling vector laser cutting and engraving from design software (Illustrator, Inkscape, etc.).

## Executive Summary

Phase 4 bridges the gap between design tools and laser execution by adding native SVG support. This allows users to:
- Import vector graphics from Adobe Illustrator, Inkscape, Affinity Designer
- Convert Bézier curves to optimized G-code toolpaths
- Preserve layer information for multi-pass operations
- Apply fill patterns for area engraving
- Optimize path order to minimize travel time

**Dependencies:** Phases 1-3 complete (G-code, GRBL, Image Raster)  
**Independent of:** Phase 5 (Feature Parity)

## Current Status

### ✅ Existing Foundation (Phases 1-3)
- G-code generation pipeline (from Phase 3 raster)
- 2D preview canvas with zoom/pan
- File management and export
- GRBL controller integration

### ❌ Missing for SVG Support
- SVG file parsing
- Bézier curve algorithms
- Path-to-arc conversion (G2/G3)
- Fill pattern generation
- Layer management
- Path optimization

## Phase 4 Scope

### 1. SVG File Import (Week 1)

**PC Reference:** `SvgConverter/GCodeFromSVG.cs`, `SvgLibrary/` (MS SVG Library)

**Requirements:**
- Parse SVG files (paths, circles, rectangles, ellipses, polygons)
- Extract stroke and fill properties
- Handle transforms (translate, rotate, scale, matrix)
- Support nested groups and layers
- Preserve layer names and visibility
- Handle units (px, mm, in, pt)
- Viewport and viewBox scaling

**SVG Elements to Support:**
- `<path>` - Bézier curves (M, L, C, Q, A commands)
- `<line>` - Straight lines
- `<rect>` - Rectangles
- `<circle>` - Circles
- `<ellipse>` - Ellipses
- `<polygon>` / `<polyline>` - Multi-point shapes
- `<g>` - Groups and layers

**Implementation:**
- New `SVGParser.swift`:
  ```swift
  class SVGParser {
      func parse(fileURL: URL) throws -> SVGDocument
      func extractPaths() -> [SVGPath]
      func applyTransforms() -> [TransformedPath]
  }
  
  struct SVGDocument {
      var width: Double
      var height: Double
      var viewBox: CGRect?
      var paths: [SVGPath]
      var layers: [SVGLayer]
  }
  
  struct SVGPath: Identifiable {
      let id: UUID
      var segments: [PathSegment]
      var stroke: SVGStroke?
      var fill: SVGFill?
      var transform: CGAffineTransform
      var layerName: String?
  }
  
  enum PathSegment {
      case moveTo(CGPoint)
      case lineTo(CGPoint)
      case cubicCurve(CGPoint, CGPoint, CGPoint)  // control1, control2, end
      case quadCurve(CGPoint, CGPoint)             // control, end
      case arc(CGPoint, Double, Bool, Bool)        // end, radius, large, sweep
      case closePath
  }
  ```

**Impact:** Foundation for all vector operations

---

### 2. Bézier Curve to G-code Conversion (Weeks 2-3)

**PC Reference:** `SvgConverter/BezierTools.cs`, `Bezier2Biarc/` library

**Requirements:**
- Convert cubic Bézier curves to G-code arcs (G2/G3) or line segments (G1)
- Adaptive subdivision based on tolerance
- Bi-arc approximation for smooth curves
- Linearization fallback for complex curves
- Chord tolerance setting (0.01-1.0mm)

**Algorithms:**
1. **Bi-arc Approximation** (preferred for smooth curves)
   - Fit two circular arcs to cubic Bézier
   - Join point calculation
   - Minimize error over curve length

2. **Recursive Subdivision** (fallback)
   - Split curve at midpoint until flat enough
   - Flatness test: distance from chord
   - Generate G1 line segments

3. **Arc Fitting**
   - Convert bi-arcs to G2/G3 commands
   - Calculate center, radius, direction (CW/CCW)
   - Handle full circles and ellipses

**Implementation:**
- New `BezierTools.swift`:
  ```swift
  class BezierTools {
      static func cubicToBiarcs(
          start: CGPoint,
          control1: CGPoint,
          control2: CGPoint,
          end: CGPoint,
          tolerance: Double
      ) -> [Arc]
      
      static func subdivide(
          cubic: CubicBezier,
          tolerance: Double
      ) -> [CGPoint]
      
      static func arcToGCode(
          arc: Arc,
          clockwise: Bool
      ) -> String
  }
  
  struct Arc {
      var center: CGPoint
      var radius: Double
      var startAngle: Double
      var endAngle: Double
      var clockwise: Bool
  }
  ```

- New `PathToGCode.swift`:
  ```swift
  class PathToGCode {
      var tolerance: Double = 0.1  // mm
      var useArcs: Bool = true
      var optimizePaths: Bool = true
      
      func convert(paths: [SVGPath]) -> [String]
      func generateGCode(for path: SVGPath) -> [String]
  }
  ```

**Impact:** Core conversion engine, determines quality and smoothness

---

### 3. Fill Pattern Generation (Week 4)

**PC Reference:** `SvgConverter/` fill algorithms

**Requirements:**
- Detect closed paths with fill
- Generate fill patterns:
  - **Horizontal lines** (raster-style)
  - **Vertical lines**
  - **Diagonal lines** (45°)
  - **Cross-hatch** (perpendicular lines)
  - **Spiral** (inside-out)
  - **Concentric** (offset paths)
- Line spacing control (0.1-5mm)
- Fill angle control (0-360°)
- Path offsetting (inset/outset)

**Algorithms:**
1. **Line Fill:**
   - Scan lines across bounding box
   - Calculate intersections with path
   - Sort intersection points
   - Generate alternating fill segments

2. **Offset Fill:**
   - Generate inward offsets of path
   - Handle self-intersections
   - Continue until center reached

**Implementation:**
- New `FillGenerator.swift`:
  ```swift
  class FillGenerator {
      enum FillPattern {
          case horizontal, vertical, diagonal
          case crossHatch, spiral, concentric
      }
      
      func generateFill(
          for path: SVGPath,
          pattern: FillPattern,
          spacing: Double,
          angle: Double
      ) -> [SVGPath]
      
      func offsetPath(
          _ path: SVGPath,
          distance: Double
      ) -> SVGPath?
  }
  ```

**Impact:** Enable area engraving, solid fills

---

### 4. Path Optimization (Week 5)

**PC Reference:** `SvgConverter/gcodeRelated.cs`, optimization algorithms

**Requirements:**
- Reorder paths to minimize travel time
- Nearest-neighbor sorting
- Connect nearby endpoints
- Avoid redundant moves
- Group by layer/color
- Optional lead-in/lead-out moves

**Optimization Strategies:**
1. **Nearest Neighbor:**
   - Start from origin (or custom point)
   - Find closest unprocessed path
   - Consider path reversal to minimize travel

2. **Layer Grouping:**
   - Process all paths in layer before moving to next
   - Respect layer order or optimize globally

3. **Travel Moves:**
   - G0 rapid for travels > threshold
   - Optional lift Z between paths
   - Retract laser during travel

**Implementation:**
- New `PathOptimizer.swift`:
  ```swift
  class PathOptimizer {
      func optimize(paths: [SVGPath]) -> [SVGPath]
      func calculateTravelDistance(from: CGPoint, to: CGPoint) -> Double
      func shouldReverse(_ path: SVGPath, from: CGPoint) -> Bool
      func insertLeadInOut(path: SVGPath, length: Double) -> SVGPath
  }
  ```

**Impact:** Faster job execution, reduced laser wear

---

### 5. SVG Import UI (Week 6)

**Requirements:**
- Import SVG files via NSOpenPanel
- Layer visibility toggles
- Path preview with color coding
- Conversion settings panel
- Real-time preview updates
- Export to G-code

**UI Components:**

**A. SVG Import View:**
- File selection
- SVG preview (rendered paths)
- Layer list with visibility toggles
- Bounding box and statistics
- Zoom/pan controls

**B. Conversion Settings:**
- Tolerance (0.01-1mm)
- Use arcs vs linearize
- Fill pattern and spacing
- Optimize path order
- Feed rate and power
- Lead-in/out length

**C. Preview Modes:**
- Original SVG rendering
- G-code toolpath preview
- Layer-by-layer view
- Travel moves visualization

**Implementation:**
- New `SVGImportView.swift`:
  ```swift
  struct SVGImportView: View {
      @ObservedObject var svgImporter: SVGImporter
      @State private var selectedLayers: Set<String> = []
      @State private var showTravels: Bool = false
      
      var body: some View {
          HSplitView {
              // Left: Layer list and settings
              // Right: Preview canvas
          }
      }
  }
  ```

- New `SVGImporter.swift`:
  ```swift
  class SVGImporter: ObservableObject {
      @Published var document: SVGDocument?
      @Published var settings: ConversionSettings
      @Published var isConverting: Bool = false
      @Published var progress: Double = 0
      
      func importFile(url: URL) async throws
      func convertToGCode() async throws -> GCodeFile
  }
  
  struct ConversionSettings {
      var tolerance: Double = 0.1
      var useArcs: Bool = true
      var fillPattern: FillPattern = .horizontal
      var fillSpacing: Double = 0.5
      var optimizePaths: Bool = true
      var feedRate: Int = 1000
      var power: Int = 80
  }
  ```

**Impact:** User-friendly SVG workflow

---

## Technical Architecture

### File Structure

**New Files:**
```
LaserGRBL-macOS/LaserGRBL/
├── Models/
│   ├── SVGDocument.swift       (SVG data structures)
│   ├── PathSegment.swift       (Bézier curve types)
│   └── ConversionSettings.swift (user preferences)
├── Managers/
│   ├── SVGParser.swift         (XML parsing, path extraction)
│   ├── SVGImporter.swift       (file import, orchestration)
│   ├── BezierTools.swift       (curve mathematics)
│   ├── PathToGCode.swift       (conversion engine)
│   ├── FillGenerator.swift     (fill patterns)
│   └── PathOptimizer.swift     (travel optimization)
└── Views/
    ├── SVGImportView.swift     (main import UI)
    ├── SVGPreviewCanvas.swift  (path rendering)
    └── SVGSettingsPanel.swift  (conversion options)
```

**Modified Files:**
```
├── Views/
│   └── ContentView.swift       (add SVG tab)
├── Models/
│   └── GCodeFile.swift         (extend for SVG metadata)
└── LaserGRBLApp.swift         (environment objects)
```

### Dependencies

**Swift Packages (optional):**
- SwiftSVG (if native parsing insufficient)
- Or use XMLParser (built-in)

**No External Libraries Required:**
- Implement Bézier math natively
- Use Core Graphics for transforms
- Use Swift Charts for visualization

### Mathematical Foundation

**Cubic Bézier Formula:**
```
B(t) = (1-t)³P₀ + 3(1-t)²tP₁ + 3(1-t)t²P₂ + t³P₃
where t ∈ [0,1], P₀,P₁,P₂,P₃ are control points
```

**Arc Center Calculation:**
```
Given start, end, radius, large_arc, sweep:
1. Calculate midpoint
2. Solve for center using radius constraint
3. Determine angles for G2/G3
```

**Flatness Test:**
```
distance(chord, curve_midpoint) < tolerance
```

---

## Success Criteria

### Must Have (Phase 4 Complete):
- ✅ Import SVG files with paths, shapes, and layers
- ✅ Convert cubic Bézier curves to G2/G3 arcs
- ✅ Generate fill patterns for closed paths
- ✅ Optimize path order for minimal travel
- ✅ Preview SVG with layer control
- ✅ Export to valid G-code
- ✅ Tolerance control for quality vs speed

### Quality Bar:
- Smooth curves (no visible faceting)
- Accurate dimensions (±0.1mm)
- Fill patterns complete and uniform
- No missed paths or layers
- Preview matches final output

---

## Timeline

**Total Duration:** 6 weeks

| Week | Focus | Deliverables |
|------|-------|--------------|
| 1 | SVG Parsing | SVGParser, SVGDocument model |
| 2 | Bézier Math | BezierTools, arc fitting algorithms |
| 3 | Path Conversion | PathToGCode, G2/G3 generation |
| 4 | Fill Patterns | FillGenerator, line/offset fills |
| 5 | Optimization | PathOptimizer, travel minimization |
| 6 | UI & Testing | SVGImportView, integration tests |

**Checkpoints:**
- Week 2: Parse simple SVG, extract paths
- Week 3: Convert straight lines and arcs to G-code
- Week 4: Handle complex Bézier curves
- Week 5: Fill patterns working
- Week 6: Full workflow functional

---

## Risk Assessment

**Medium Risk:**
- Bézier to bi-arc conversion (complex mathematics)
  - Mitigation: Reference PC implementation, use proven algorithms
  
- Fill pattern self-intersections
  - Mitigation: Use Clipper library if needed (available in Swift)

- SVG spec coverage (huge specification)
  - Mitigation: Focus on common subset used by design tools

**Low Risk:**
- SVG parsing (XML is standard)
- UI implementation (similar to Phase 3)
- G-code generation (established pipeline)

---

## Testing Strategy

### Unit Tests:
- Bézier subdivision accuracy
- Arc center calculation
- Path intersection detection
- Fill pattern generation

### Integration Tests:
- Import SVGs from Illustrator, Inkscape
- Convert variety of shapes (circles, curves, polygons)
- Fill closed and open paths
- Optimize 100+ path collections

### Acceptance Tests:
- Real laser cutting accuracy (±0.1mm)
- Smooth curves (no visible facets)
- Complete fills (no gaps)
- Execution time reasonable (<2min for complex file)

---

## Example SVG Workflow

**User Journey:**
1. Create design in Illustrator
2. Export as SVG
3. Import into LaserGRBL macOS
4. Toggle layers (cut vs engrave)
5. Adjust tolerance and fill settings
6. Preview toolpath
7. Export G-code
8. Send to laser

**Sample Files to Test:**
- Simple shapes (circle, square, star)
- Text with curves
- Logo with fills
- Mechanical parts with precision paths
- Artistic designs with gradients (ignore, warn)

---

## Documentation Deliverables

After Phase 4 completion:

1. **PHASE4_COMPLETE.md** - Feature summary
2. **PHASE4_INTEGRATION_GUIDE.md** - Setup instructions
3. **SVG_GUIDE.md** - User guide for SVG import
4. **BEZIER_ALGORITHMS.md** - Technical documentation
5. Updated **IMPLEMENTATION_STATUS.md**
6. Updated **README.md**

---

## Post-Phase 4: What's Next?

**Phase 5:** Feature Parity (independent track)
- Overrides, GRBL settings, help system
- See PHASE5_PLAN.md

**Phase 6:** Advanced Features
- Image vectorization (raster → vector)
- DXF import
- 3D preview with SceneKit

---

## Notes

- **PC Reference:** `SvgConverter/BezierTools.cs`, `Bezier2Biarc/` (Laszlo's algorithm)
- **Math Library:** Implement natively, don't rely on external Bézier libraries
- **SVG Subset:** Focus on Illustrator/Inkscape output, not full SVG 2.0 spec
- **Testing:** Requires real laser for dimensional accuracy verification
- **Performance:** Optimize for files with 1000+ paths

---

**Status:** Plan Complete - Ready for Approval  
**Created:** October 19, 2025  
**Dependencies:** Phases 1-3 complete  
**Estimated Duration:** 6 weeks  
**Next Phase:** Phase 5 (Feature Parity) - independent track
