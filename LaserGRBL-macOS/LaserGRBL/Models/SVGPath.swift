//
//  SVGPath.swift
//  LaserGRBL
//
//  Phase 4: SVG Vector Import
//  Created on October 19, 2025
//

import Foundation
import AppKit

/// Represents a single path extracted from an SVG document
struct SVGPath: Identifiable, Equatable {
    let id: UUID
    let cgPath: CGPath
    let strokeWidth: Double
    let strokeColor: NSColor?
    let fillColor: NSColor?
    let transform: CGAffineTransform
    var isClosed: Bool
    var boundingBox: CGRect
    var layerId: UUID?
    
    /// Path rendering type
    enum PathType: String, Codable {
        case stroke
        case fill
        case strokeAndFill
    }
    
    var pathType: PathType {
        if strokeColor != nil && fillColor != nil {
            return .strokeAndFill
        } else if fillColor != nil {
            return .fill
        } else {
            return .stroke
        }
    }
    
    /// Initialize a new SVG path
    init(
        id: UUID = UUID(),
        cgPath: CGPath,
        strokeWidth: Double = 1.0,
        strokeColor: NSColor? = .black,
        fillColor: NSColor? = nil,
        transform: CGAffineTransform = .identity,
        isClosed: Bool = false,
        layerId: UUID? = nil
    ) {
        self.id = id
        self.cgPath = cgPath
        self.strokeWidth = strokeWidth
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.transform = transform
        self.isClosed = isClosed
        self.boundingBox = cgPath.boundingBoxOfPath
        self.layerId = layerId
    }
    
    /// Get the start point of the path
    var startPoint: CGPoint? {
        var start: CGPoint?
        cgPath.applyWithBlock { element in
            if start == nil {
                switch element.pointee.type {
                case .moveToPoint:
                    start = element.pointee.points[0]
                case .addLineToPoint:
                    start = element.pointee.points[0]
                case .addQuadCurveToPoint:
                    start = element.pointee.points[0]
                case .addCurveToPoint:
                    start = element.pointee.points[0]
                default:
                    break
                }
            }
        }
        return start
    }
    
    /// Get the end point of the path
    var endPoint: CGPoint? {
        var end: CGPoint?
        cgPath.applyWithBlock { element in
            switch element.pointee.type {
            case .addLineToPoint:
                end = element.pointee.points[0]
            case .addQuadCurveToPoint:
                end = element.pointee.points[1]
            case .addCurveToPoint:
                end = element.pointee.points[2]
            default:
                break
            }
        }
        return end
    }
    
    /// Get all path elements
    func getElements() -> [PathElement] {
        var elements: [PathElement] = []
        
        cgPath.applyWithBlock { element in
            let type = element.pointee.type
            let points = element.pointee.points
            
            switch type {
            case .moveToPoint:
                elements.append(.move(to: points[0]))
                
            case .addLineToPoint:
                elements.append(.line(to: points[0]))
                
            case .addQuadCurveToPoint:
                elements.append(.quadCurve(to: points[1], control: points[0]))
                
            case .addCurveToPoint:
                elements.append(.cubicCurve(
                    to: points[2],
                    control1: points[0],
                    control2: points[1]
                ))
                
            case .closeSubpath:
                elements.append(.close)
                
            @unknown default:
                break
            }
        }
        
        return elements
    }
    
    /// Calculate the length of the path (approximation)
    func approximateLength(tolerance: Double = 0.1) -> Double {
        var length: Double = 0
        var currentPoint: CGPoint?
        
        cgPath.applyWithBlock { element in
            let type = element.pointee.type
            let points = element.pointee.points
            
            switch type {
            case .moveToPoint:
                currentPoint = points[0]
                
            case .addLineToPoint:
                if let current = currentPoint {
                    length += distance(current, points[0])
                }
                currentPoint = points[0]
                
            case .addQuadCurveToPoint:
                if let current = currentPoint {
                    // Approximate quadratic curve length
                    length += approximateQuadCurveLength(
                        from: current,
                        control: points[0],
                        to: points[1],
                        tolerance: tolerance
                    )
                }
                currentPoint = points[1]
                
            case .addCurveToPoint:
                if let current = currentPoint {
                    // Approximate cubic curve length
                    length += approximateCubicCurveLength(
                        from: current,
                        control1: points[0],
                        control2: points[1],
                        to: points[2],
                        tolerance: tolerance
                    )
                }
                currentPoint = points[2]
                
            default:
                break
            }
        }
        
        return length
    }
    
    // MARK: - Equatable
    
    static func == (lhs: SVGPath, rhs: SVGPath) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Path Elements

/// Represents a single element in a path
enum PathElement {
    case move(to: CGPoint)
    case line(to: CGPoint)
    case quadCurve(to: CGPoint, control: CGPoint)
    case cubicCurve(to: CGPoint, control1: CGPoint, control2: CGPoint)
    case close
}

// MARK: - Helper Functions

/// Calculate distance between two points
func distance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
    let dx = p2.x - p1.x
    let dy = p2.y - p1.y
    return sqrt(dx * dx + dy * dy)
}

/// Approximate the length of a quadratic Bézier curve
func approximateQuadCurveLength(
    from p0: CGPoint,
    control p1: CGPoint,
    to p2: CGPoint,
    tolerance: Double
) -> Double {
    // Simple subdivision approach
    let chord = distance(p0, p2)
    let controlDist = distance(p0, p1) + distance(p1, p2)
    
    if controlDist - chord < tolerance {
        return (chord + controlDist) / 2
    }
    
    // Subdivide at t = 0.5
    let q0 = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
    let q1 = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    let r = CGPoint(x: (q0.x + q1.x) / 2, y: (q0.y + q1.y) / 2)
    
    return approximateQuadCurveLength(from: p0, control: q0, to: r, tolerance: tolerance) +
           approximateQuadCurveLength(from: r, control: q1, to: p2, tolerance: tolerance)
}

/// Approximate the length of a cubic Bézier curve
func approximateCubicCurveLength(
    from p0: CGPoint,
    control1 p1: CGPoint,
    control2 p2: CGPoint,
    to p3: CGPoint,
    tolerance: Double
) -> Double {
    // Simple subdivision approach
    let chord = distance(p0, p3)
    let controlDist = distance(p0, p1) + distance(p1, p2) + distance(p2, p3)
    
    if controlDist - chord < tolerance {
        return (chord + controlDist) / 2
    }
    
    // Subdivide at t = 0.5
    let q0 = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
    let q1 = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    let q2 = CGPoint(x: (p2.x + p3.x) / 2, y: (p2.y + p3.y) / 2)
    let r0 = CGPoint(x: (q0.x + q1.x) / 2, y: (q0.y + q1.y) / 2)
    let r1 = CGPoint(x: (q1.x + q2.x) / 2, y: (q1.y + q2.y) / 2)
    let s = CGPoint(x: (r0.x + r1.x) / 2, y: (r0.y + r1.y) / 2)
    
    return approximateCubicCurveLength(from: p0, control1: q0, control2: r0, to: s, tolerance: tolerance) +
           approximateCubicCurveLength(from: s, control1: r1, control2: q2, to: p3, tolerance: tolerance)
}

