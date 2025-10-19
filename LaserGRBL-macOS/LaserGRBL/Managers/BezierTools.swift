//
//  BezierTools.swift
//  LaserGRBL
//
//  Phase 4: SVG Vector Import
//  Created on October 19, 2025
//

import Foundation
import AppKit

/// Tools for working with Bézier curves and converting them to line segments
struct BezierTools {
    
    // MARK: - Bézier Curve Structures
    
    struct QuadraticBezier {
        let p0: CGPoint  // Start point
        let p1: CGPoint  // Control point
        let p2: CGPoint  // End point
    }
    
    struct CubicBezier {
        let p0: CGPoint  // Start point
        let p1: CGPoint  // Control point 1
        let p2: CGPoint  // Control point 2
        let p3: CGPoint  // End point
    }
    
    struct Arc {
        let center: CGPoint
        let radius: Double
        let startAngle: Double
        let endAngle: Double
        let clockwise: Bool
    }
    
    // MARK: - Cubic Bézier Subdivision
    
    /// Subdivide a cubic Bézier curve into line segments using adaptive subdivision
    /// - Parameters:
    ///   - curve: The cubic Bézier curve to subdivide
    ///   - tolerance: Maximum allowed distance from curve (in mm)
    /// - Returns: Array of points representing the subdivided curve
    static func subdivideCubic(
        _ curve: CubicBezier,
        tolerance: Double
    ) -> [CGPoint] {
        var points: [CGPoint] = []
        subdivideCubicRecursive(
            curve.p0, curve.p1, curve.p2, curve.p3,
            tolerance: tolerance,
            points: &points
        )
        points.append(curve.p3)  // Add final point
        return points
    }
    
    /// Recursive helper for cubic Bézier subdivision
    private static func subdivideCubicRecursive(
        _ p0: CGPoint,
        _ p1: CGPoint,
        _ p2: CGPoint,
        _ p3: CGPoint,
        tolerance: Double,
        points: inout [CGPoint]
    ) {
        // Add start point if this is the first segment
        if points.isEmpty {
            points.append(p0)
        }
        
        // Check if curve is flat enough
        if isCubicFlatEnough(p0, p1, p2, p3, tolerance: tolerance) {
            // Curve is flat enough, no need to subdivide further
            return
        }
        
        // Split curve at t = 0.5 using de Casteljau's algorithm
        let (left, right) = splitCubic(p0, p1, p2, p3, at: 0.5)
        
        // Recursively subdivide left half
        subdivideCubicRecursive(
            left.p0, left.p1, left.p2, left.p3,
            tolerance: tolerance,
            points: &points
        )
        
        // Add the split point
        points.append(left.p3)
        
        // Recursively subdivide right half
        subdivideCubicRecursive(
            right.p0, right.p1, right.p2, right.p3,
            tolerance: tolerance,
            points: &points
        )
    }
    
    /// Check if a cubic Bézier curve is flat enough (within tolerance)
    private static func isCubicFlatEnough(
        _ p0: CGPoint,
        _ p1: CGPoint,
        _ p2: CGPoint,
        _ p3: CGPoint,
        tolerance: Double
    ) -> Bool {
        // Calculate perpendicular distances from control points to chord
        let d1 = perpendicularDistance(p1, to: (p0, p3))
        let d2 = perpendicularDistance(p2, to: (p0, p3))
        
        // Check if both control points are within tolerance
        return max(d1, d2) <= tolerance
    }
    
    /// Split a cubic Bézier curve at parameter t using de Casteljau's algorithm
    private static func splitCubic(
        _ p0: CGPoint,
        _ p1: CGPoint,
        _ p2: CGPoint,
        _ p3: CGPoint,
        at t: Double
    ) -> (left: CubicBezier, right: CubicBezier) {
        // First level of interpolation
        let q0 = lerp(p0, p1, t: t)
        let q1 = lerp(p1, p2, t: t)
        let q2 = lerp(p2, p3, t: t)
        
        // Second level
        let r0 = lerp(q0, q1, t: t)
        let r1 = lerp(q1, q2, t: t)
        
        // Third level (split point)
        let s = lerp(r0, r1, t: t)
        
        // Construct left and right curves
        let left = CubicBezier(p0: p0, p1: q0, p2: r0, p3: s)
        let right = CubicBezier(p0: s, p1: r1, p2: q2, p3: p3)
        
        return (left, right)
    }
    
    // MARK: - Quadratic Bézier Subdivision
    
    /// Subdivide a quadratic Bézier curve into line segments
    static func subdivideQuadratic(
        _ curve: QuadraticBezier,
        tolerance: Double
    ) -> [CGPoint] {
        var points: [CGPoint] = []
        subdivideQuadraticRecursive(
            curve.p0, curve.p1, curve.p2,
            tolerance: tolerance,
            points: &points
        )
        points.append(curve.p2)
        return points
    }
    
    private static func subdivideQuadraticRecursive(
        _ p0: CGPoint,
        _ p1: CGPoint,
        _ p2: CGPoint,
        tolerance: Double,
        points: inout [CGPoint]
    ) {
        if points.isEmpty {
            points.append(p0)
        }
        
        // Check if flat enough
        if isQuadraticFlatEnough(p0, p1, p2, tolerance: tolerance) {
            return
        }
        
        // Split at t = 0.5
        let (left, right) = splitQuadratic(p0, p1, p2, at: 0.5)
        
        subdivideQuadraticRecursive(left.p0, left.p1, left.p2, tolerance: tolerance, points: &points)
        points.append(left.p2)
        subdivideQuadraticRecursive(right.p0, right.p1, right.p2, tolerance: tolerance, points: &points)
    }
    
    private static func isQuadraticFlatEnough(
        _ p0: CGPoint,
        _ p1: CGPoint,
        _ p2: CGPoint,
        tolerance: Double
    ) -> Bool {
        let d = perpendicularDistance(p1, to: (p0, p2))
        return d <= tolerance
    }
    
    private static func splitQuadratic(
        _ p0: CGPoint,
        _ p1: CGPoint,
        _ p2: CGPoint,
        at t: Double
    ) -> (left: QuadraticBezier, right: QuadraticBezier) {
        let q0 = lerp(p0, p1, t: t)
        let q1 = lerp(p1, p2, t: t)
        let s = lerp(q0, q1, t: t)
        
        let left = QuadraticBezier(p0: p0, p1: q0, p2: s)
        let right = QuadraticBezier(p0: s, p1: q1, p2: p2)
        
        return (left, right)
    }
    
    // MARK: - Arc Fitting (Optional Enhancement)
    
    /// Attempt to fit a circular arc to a sequence of points
    /// Returns nil if the points don't fit an arc well enough
    static func fitArc(
        to points: [CGPoint],
        tolerance: Double = 0.1
    ) -> Arc? {
        guard points.count >= 3 else { return nil }
        
        // Use first, middle, and last points for fitting
        let p0 = points.first!
        let p1 = points[points.count / 2]
        let p2 = points.last!
        
        // Check if points are nearly collinear (would be a line, not an arc)
        let chord = distance(p0, p2)
        let viaMiddle = distance(p0, p1) + distance(p1, p2)
        if abs(viaMiddle - chord) < 0.01 {
            return nil  // Points are too close to a straight line
        }
        
        // Find circle center from three points
        guard let center = findCircleCenter(p0: p0, p1: p1, p2: p2) else {
            return nil
        }
        
        // Calculate radius
        let radius = distance(center, p0)
        
        // Reject unreasonably small or large arcs
        guard radius > 0.1 && radius < 10000 else {
            return nil
        }
        
        // Check if points fit the circle well enough
        // Use a sampling approach - check every 5th point to improve performance
        let stepSize = max(1, points.count / 20)
        for i in stride(from: 0, to: points.count, by: stepSize) {
            let point = points[i]
            let d = abs(distance(center, point) - radius)
            if d > tolerance {
                return nil  // Point is too far from circle
            }
        }
        
        // Calculate angles
        let startAngle = atan2(p0.y - center.y, p0.x - center.x)
        let endAngle = atan2(p2.y - center.y, p2.x - center.x)
        
        // Determine direction (clockwise or counter-clockwise)
        let clockwise = isClockwise(p0, p1, p2)
        
        return Arc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        )
    }
    
    /// Find the center of a circle passing through three points
    private static func findCircleCenter(
        p0: CGPoint,
        p1: CGPoint,
        p2: CGPoint
    ) -> CGPoint? {
        let ax = p0.x
        let ay = p0.y
        let bx = p1.x
        let by = p1.y
        let cx = p2.x
        let cy = p2.y
        
        let d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
        
        guard abs(d) > 1e-10 else {
            return nil  // Points are collinear
        }
        
        let ux = ((ax * ax + ay * ay) * (by - cy) + (bx * bx + by * by) * (cy - ay) + (cx * cx + cy * cy) * (ay - by)) / d
        let uy = ((ax * ax + ay * ay) * (cx - bx) + (bx * bx + by * by) * (ax - cx) + (cx * cx + cy * cy) * (bx - ax)) / d
        
        return CGPoint(x: ux, y: uy)
    }
    
    /// Determine if three points form a clockwise turn
    private static func isClockwise(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint) -> Bool {
        let cross = (p1.x - p0.x) * (p2.y - p0.y) - (p1.y - p0.y) * (p2.x - p0.x)
        return cross < 0
    }
    
    // MARK: - Helper Functions
    
    /// Linear interpolation between two points
    private static func lerp(_ p0: CGPoint, _ p1: CGPoint, t: Double) -> CGPoint {
        return CGPoint(
            x: p0.x + (p1.x - p0.x) * t,
            y: p0.y + (p1.y - p0.y) * t
        )
    }
    
    /// Calculate perpendicular distance from a point to a line defined by two points
    private static func perpendicularDistance(
        _ point: CGPoint,
        to line: (CGPoint, CGPoint)
    ) -> Double {
        let (p0, p1) = line
        
        let dx = p1.x - p0.x
        let dy = p1.y - p0.y
        
        // Length of line segment
        let length = sqrt(dx * dx + dy * dy)
        
        guard length > 1e-10 else {
            // Line segment is a point
            return distance(point, p0)
        }
        
        // Calculate perpendicular distance using cross product
        let numerator = abs(dy * point.x - dx * point.y + p1.x * p0.y - p1.y * p0.x)
        
        return numerator / length
    }
    
    /// Calculate the length of a cubic Bézier curve (approximation)
    static func cubicBezierLength(
        _ curve: CubicBezier,
        samples: Int = 100
    ) -> Double {
        var length: Double = 0
        var prevPoint = curve.p0
        
        for i in 1...samples {
            let t = Double(i) / Double(samples)
            let point = evaluateCubic(curve, at: t)
            length += distance(prevPoint, point)
            prevPoint = point
        }
        
        return length
    }
    
    /// Evaluate a cubic Bézier curve at parameter t
    private static func evaluateCubic(_ curve: CubicBezier, at t: Double) -> CGPoint {
        let oneMinusT = 1.0 - t
        let oneMinusT2 = oneMinusT * oneMinusT
        let oneMinusT3 = oneMinusT2 * oneMinusT
        let t2 = t * t
        let t3 = t2 * t
        
        let x = oneMinusT3 * curve.p0.x +
                3 * oneMinusT2 * t * curve.p1.x +
                3 * oneMinusT * t2 * curve.p2.x +
                t3 * curve.p3.x
        
        let y = oneMinusT3 * curve.p0.y +
                3 * oneMinusT2 * t * curve.p1.y +
                3 * oneMinusT * t2 * curve.p2.y +
                t3 * curve.p3.y
        
        return CGPoint(x: x, y: y)
    }
    
    /// Calculate the length of a quadratic Bézier curve (approximation)
    static func quadraticBezierLength(
        _ curve: QuadraticBezier,
        samples: Int = 50
    ) -> Double {
        var length: Double = 0
        var prevPoint = curve.p0
        
        for i in 1...samples {
            let t = Double(i) / Double(samples)
            let point = evaluateQuadratic(curve, at: t)
            length += distance(prevPoint, point)
            prevPoint = point
        }
        
        return length
    }
    
    /// Evaluate a quadratic Bézier curve at parameter t
    private static func evaluateQuadratic(_ curve: QuadraticBezier, at t: Double) -> CGPoint {
        let oneMinusT = 1.0 - t
        let oneMinusT2 = oneMinusT * oneMinusT
        let t2 = t * t
        
        let x = oneMinusT2 * curve.p0.x +
                2 * oneMinusT * t * curve.p1.x +
                t2 * curve.p2.x
        
        let y = oneMinusT2 * curve.p0.y +
                2 * oneMinusT * t * curve.p1.y +
                t2 * curve.p2.y
        
        return CGPoint(x: x, y: y)
    }
}

