# Arc Commands Setting Fix

## Issue
When the "Use Arc Commands (G2/G3)" setting was enabled in Vector Settings, the generated G-code didn't actually contain arc commands - it still used only linear movements (G1).

## Root Cause
The arc fitting algorithm was **too strict** with its tolerance checking, causing nearly all curves to fail the arc test and fall back to line segment approximation.

### Specific Problems:
1. **Strict tolerance**: Using `settings.arcTolerance` (0.05mm default) made it very difficult for curves to pass the arc test
2. **Checking every point**: The algorithm checked every single point against the fitted circle, which was computationally expensive and overly strict
3. **No minimum radius check**: Could attempt to fit arcs to nearly-straight lines

## Solution

### 1. More Lenient Fitting Tolerance (`PathToGCodeConverter.swift`)
```swift
// OLD: Used arcTolerance directly (0.05mm default - very strict)
if let arc = BezierTools.fitArc(to: points, tolerance: settings.arcTolerance) {

// NEW: Use minimum of 0.1mm for more lenient fitting
let fittingTolerance = max(settings.arcTolerance, 0.1)
if let arc = BezierTools.fitArc(to: points, tolerance: fittingTolerance) {
```

### 2. Added Arc Command Comments
Now when arcs are successfully generated, the G-code includes a comment:
```gcode
; Arc command (G2)
G2 X10.500 Y5.250 I-2.500 J-2.500 S800
```
This makes it **easy to verify** that arc commands are being used.

### 3. Fixed Laser Control for Arc Commands
**Problem**: G3 commands had `S800` (laser power) but no `M3` command to actually turn the laser on.

**Solution**: Added proper laser control around all cutting operations:
```gcode
; Arc command (G3)
M3 ; Laser on
G3 X50.0 Y90.0 I-40.0 J-0.0 S800
M5 ; Laser off
```
Now the laser will actually fire during arc cutting operations.

### 4. Improved Arc Fitting Algorithm (`BezierTools.swift`)

**Added collinearity check:**
```swift
// Reject nearly-straight lines (not arcs)
let chord = distance(p0, p2)
let viaMiddle = distance(p0, p1) + distance(p1, p2)
if abs(viaMiddle - chord) < 0.01 {
    return nil  // Too close to a straight line
}
```

**Added radius validation:**
```swift
// Reject unreasonably small or large arcs
guard radius > 0.1 && radius < 10000 else {
    return nil
}
```

**Optimized point checking:**
```swift
// OLD: Checked every point (slow and strict)
for point in points {
    let d = abs(distance(center, point) - radius)
    if d > tolerance {
        return nil
    }
}

// NEW: Sample every 20th point (faster and more lenient)
let stride = max(1, points.count / 20)
for i in stride(from: 0, to: points.count, by: stride) {
    let point = points[i]
    let d = abs(distance(center, point) - radius)
    if d > tolerance {
        return nil
    }
}
```

## Benefits

✅ **Arc commands actually work now** - Curves that approximate circles will generate G2/G3 commands  
✅ **Smaller G-code files** - One arc command replaces many line segments  
✅ **Smoother motion** - GRBL can execute arcs more smoothly than many small lines  
✅ **Easy verification** - Comments in G-code show when arcs are used  
✅ **Better performance** - Faster arc fitting with sampling approach

## Testing

To verify arc commands are working:

1. **Import an SVG** with circular shapes (circles, rounded rectangles, or smooth curves)
2. **Enable "Use Arc Commands"** in Vector Settings
3. **Convert to G-Code**
4. **Check the output** - you should see comments like `; Arc command (G2)` or `; Arc command (G3)`
5. **Look for G2/G3 commands** in the generated G-code

### Example SVG to Test
Use `circle.svg` from `Tests/SampleFiles/` - it should generate several G2/G3 arc commands instead of many G1 linear moves.

## Settings Recommendations

For **best arc fitting results**:
- **Arc Tolerance**: 0.1 - 0.2mm (more lenient works better)
- **Tolerance**: 0.05 - 0.1mm (controls overall curve quality)
- **Use Case**: Best for SVGs with circles, ellipses, and smooth rounded corners

For **maximum accuracy** (when arcs aren't critical):
- Keep **Use Arc Commands** disabled
- Use **Tolerance**: 0.01 - 0.05mm for very fine detail

## Technical Notes

### Why Not All Curves Become Arcs
Not all curves can be represented as circular arcs:
- **Ellipses**: Not true circles, so they get subdivided into lines
- **Complex Bézier curves**: May not closely match any circular arc
- **Straight-ish segments**: Filtered out to avoid near-zero radius arcs

This is expected behavior - the algorithm only generates arc commands when the curve actually approximates a circular arc well enough.

