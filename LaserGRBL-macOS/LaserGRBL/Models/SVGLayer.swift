//
//  SVGLayer.swift
//  LaserGRBL
//
//  Phase 4: SVG Vector Import
//  Created on October 19, 2025
//

import Foundation
import AppKit

/// Represents a layer in an SVG document
struct SVGLayer: Identifiable {
    let id: UUID
    var name: String
    var paths: [SVGPath]
    var isVisible: Bool
    var isLocked: Bool
    var color: NSColor
    var opacity: Double
    
    /// Initialize a new layer
    init(
        id: UUID = UUID(),
        name: String,
        paths: [SVGPath] = [],
        isVisible: Bool = true,
        isLocked: Bool = false,
        color: NSColor = .black,
        opacity: Double = 1.0
    ) {
        self.id = id
        self.name = name
        self.paths = paths
        self.isVisible = isVisible
        self.isLocked = isLocked
        self.color = color
        self.opacity = opacity
    }
    
    /// Get the bounding box of all paths in this layer
    var boundingBox: CGRect {
        guard !paths.isEmpty else { return .zero }
        
        var minX = Double.infinity
        var minY = Double.infinity
        var maxX = -Double.infinity
        var maxY = -Double.infinity
        
        for path in paths {
            let box = path.boundingBox
            minX = min(minX, box.minX)
            minY = min(minY, box.minY)
            maxX = max(maxX, box.maxX)
            maxY = max(maxY, box.maxY)
        }
        
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
    
    /// Get total path count
    var pathCount: Int {
        paths.count
    }
    
    /// Get total approximate length of all paths
    func totalLength(tolerance: Double = 0.1) -> Double {
        paths.reduce(0) { $0 + $1.approximateLength(tolerance: tolerance) }
    }
    
    /// Add a path to this layer
    mutating func addPath(_ path: SVGPath) {
        var updatedPath = path
        updatedPath.layerId = self.id
        paths.append(updatedPath)
    }
    
    /// Remove a path by ID
    mutating func removePath(_ pathId: UUID) {
        paths.removeAll { $0.id == pathId }
    }
    
    /// Clear all paths
    mutating func clearPaths() {
        paths.removeAll()
    }
    
    /// Duplicate this layer
    func duplicate() -> SVGLayer {
        SVGLayer(
            id: UUID(),
            name: name + " Copy",
            paths: paths.map { path in
                SVGPath(
                    id: UUID(),
                    cgPath: path.cgPath,
                    strokeWidth: path.strokeWidth,
                    strokeColor: path.strokeColor,
                    fillColor: path.fillColor,
                    transform: path.transform,
                    isClosed: path.isClosed
                )
            },
            isVisible: isVisible,
            isLocked: false,
            color: color,
            opacity: opacity
        )
    }
}

// MARK: - Default Layers

extension SVGLayer {
    /// Create a default layer
    static var defaultLayer: SVGLayer {
        SVGLayer(name: "Layer 1", color: .black)
    }
    
    /// Create a background layer
    static var backgroundLayer: SVGLayer {
        SVGLayer(
            name: "Background",
            isLocked: true,
            color: .lightGray,
            opacity: 0.3
        )
    }
}

