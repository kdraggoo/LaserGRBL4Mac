# G-Code Preview Arc Rendering Fix

## Issue
When using arc commands (G2/G3), the G-code preview showed straight lines forming a square/diamond shape instead of rendering the actual curved arcs. However, when not using arc commands, the preview correctly showed curves using many small G1 linear segments.

## Root Cause
The macOS G-code preview system (`GCodePreviewView.swift`) was **only rendering linear segments**. It completely ignored G2/G3 arc commands and treated them as straight lines from start point to end point.

### The Problem Code
```swift
// OLD: Only drew straight lines, even for arc commands
var segmentPath = Path()
segmentPath.move(to: startPoint)
segmentPath.addLine(to: endPoint)  // ← Always straight line!
context.stroke(segmentPath, with: .color(lineColor), style: lineStyle)
```

## Solution

### 1. Arc Command Detection
Added detection for arc commands:
```swift
// Determine if this is an arc command
let isArc = command.command == .motion(.arcCW) || command.command == .motion(.arcCCW)
let isClockwise = command.command == .motion(.arcCW)
```

### 2. Arc Path Creation
Created a new `createArcPath` function that properly interprets G2/G3 arc parameters:
```swift
private func createArcPath(from startPoint: CGPoint, to endPoint: CGPoint, i: CGFloat, j: CGFloat, clockwise: Bool) -> Path {
    var path = Path()
    
    // Calculate arc center (I, J are relative to start point)
    let centerX = startPoint.x + i
    let centerY = startPoint.y + j
    
    // Calculate radius
    let radius = sqrt(i * i + j * j)
    
    // Calculate start and end angles
    let startAngle = atan2(startPoint.y - centerY, startPoint.x - centerX)
    let endAngle = atan2(endPoint.y - centerY, endPoint.x - centerX)
    
    // Create arc path using SwiftUI's addArc
    path.move(to: startPoint)
    path.addArc(
        center: CGPoint(x: centerX, y: centerY),
        radius: radius,
        startAngle: Angle(radians: startAngle),
        endAngle: Angle(radians: endAngle),
        clockwise: clockwise
    )
    
    return path
}
```

### 3. Conditional Rendering
Updated the rendering logic to choose between arc and linear paths:
```swift
// Draw the segment if enabled
if shouldDraw {
    if isArc, let i = command.i, let j = command.j {
        // Draw arc using I, J parameters
        let arcPath = createArcPath(
            from: startPoint,
            to: endPoint,
            i: CGFloat(i) * scale,
            j: CGFloat(j) * scale,
            clockwise: isClockwise
        )
        context.stroke(arcPath, with: .color(lineColor), style: lineStyle)
    } else {
        // Draw linear segment
        var segmentPath = Path()
        segmentPath.move(to: startPoint)
        segmentPath.addLine(to: endPoint)
        context.stroke(segmentPath, with: .color(lineColor), style: lineStyle)
    }
}
```

## Technical Details

### G-Code Arc Parameters
- **G2**: Clockwise arc
- **G3**: Counter-clockwise arc  
- **I**: X offset of arc center relative to start point
- **J**: Y offset of arc center relative to start point
- **X, Y**: End point of the arc

### Example G-Code
```gcode
G3 X50.0 Y90.0 I-40.0 J-0.0 S800
```
- Start point: Current position
- End point: (50, 90)
- Arc center: (current_x - 40, current_y + 0)
- Direction: Counter-clockwise
- Laser power: 800

## Benefits

✅ **Accurate preview**: G2/G3 commands now render as proper curves  
✅ **Visual verification**: You can see exactly what the laser will cut  
✅ **Consistent behavior**: Preview matches the actual G-code execution  
✅ **Better debugging**: Easy to spot arc fitting issues  

## Testing

1. **Import a circle SVG** (e.g., `circle.svg` from `Tests/SampleFiles/`)
2. **Enable "Use Arc Commands"** in Vector Settings
3. **Convert to G-code** - should generate G2/G3 commands
4. **Check the preview** - should show a smooth circle, not a diamond/square
5. **Toggle "Use Arc Commands" off** - should still show a circle (using many G1 segments)

### Expected Results

**With Arc Commands (G2/G3):**
- Preview: Smooth circular arcs
- G-code: Fewer commands with G2/G3

**Without Arc Commands (G1 only):**
- Preview: Smooth circle (many small segments)
- G-code: Many G1 commands approximating the curve

Both should render the same visual result in the preview, but with different G-code generation strategies.

## Notes

- The preview now properly handles both clockwise (G2) and counter-clockwise (G3) arcs
- Arc center calculation correctly interprets I, J parameters as relative to start point
- Angle calculations handle the difference between G-code coordinate system (Y+ up) and screen coordinates (Y+ down)
- The fix maintains all existing color coding (blue for first move, red for laser on, orange for travel moves)

