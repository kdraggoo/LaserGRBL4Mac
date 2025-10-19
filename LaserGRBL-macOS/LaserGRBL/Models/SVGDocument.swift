//
//  SVGDocument.swift
//  LaserGRBL
//
//  Phase 4: SVG Vector Import
//  Created on October 19, 2025
//

import Foundation
import AppKit
import Combine

/// Represents a complete SVG document with layers and paths
class SVGDocument: ObservableObject {
    @Published var paths: [SVGPath] = []
    @Published var layers: [SVGLayer] = []
    @Published var viewBox: CGRect = .zero
    @Published var width: Double = 0
    @Published var height: Double = 0
    @Published var dpi: Double = 96.0  // Default SVG DPI
    @Published var metadata: SVGMetadata = SVGMetadata()
    
    var url: URL?
    
    init() {
        // Initialize with a default layer
        self.layers = [.defaultLayer]
    }
    
    /// Initialize with a URL
    init(url: URL) {
        self.url = url
        self.layers = [.defaultLayer]
    }
    
    /// Calculate overall bounding box
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
    var totalPathCount: Int {
        paths.count
    }
    
    /// Get visible path count
    var visiblePathCount: Int {
        paths.filter { path in
            if let layerId = path.layerId {
                return layers.first(where: { $0.id == layerId })?.isVisible ?? true
            }
            return true
        }.count
    }
    
    /// Get all visible paths
    var visiblePaths: [SVGPath] {
        paths.filter { path in
            if let layerId = path.layerId {
                return layers.first(where: { $0.id == layerId })?.isVisible ?? true
            }
            return true
        }
    }
    
    /// Add a path to the document
    func addPath(_ path: SVGPath, to layerId: UUID? = nil) {
        var updatedPath = path
        
        // Assign to specified layer or first layer
        if let layerId = layerId {
            updatedPath.layerId = layerId
        } else if !layers.isEmpty {
            updatedPath.layerId = layers[0].id
        }
        
        paths.append(updatedPath)
        
        // Also add to the layer
        if let layerIndex = layers.firstIndex(where: { $0.id == updatedPath.layerId }) {
            layers[layerIndex].addPath(updatedPath)
        }
    }
    
    /// Add a layer
    func addLayer(_ layer: SVGLayer) {
        layers.append(layer)
    }
    
    /// Remove a layer
    func removeLayer(_ layerId: UUID) {
        // Remove all paths in this layer
        paths.removeAll { $0.layerId == layerId }
        
        // Remove the layer
        layers.removeAll { $0.id == layerId }
    }
    
    /// Toggle layer visibility
    func toggleLayerVisibility(_ layerId: UUID) {
        if let index = layers.firstIndex(where: { $0.id == layerId }) {
            layers[index].isVisible.toggle()
        }
    }
    
    /// Clear all paths and layers
    func clear() {
        paths.removeAll()
        layers = [.defaultLayer]
        viewBox = .zero
        width = 0
        height = 0
    }
    
    /// Calculate dimensions in millimeters
    func dimensionsInMM() -> (width: Double, height: Double) {
        let mmPerInch = 25.4
        let widthMM = (width / dpi) * mmPerInch
        let heightMM = (height / dpi) * mmPerInch
        return (widthMM, heightMM)
    }
    
    /// Estimate total cutting/engraving time
    func estimateTime(feedRate: Int) -> TimeInterval {
        guard feedRate > 0 else { return 0 }
        
        let totalLength = paths.reduce(0.0) { sum, path in
            sum + path.approximateLength()
        }
        
        // Convert mm/min to mm/sec
        let feedRatePerSec = Double(feedRate) / 60.0
        
        return totalLength / feedRatePerSec
    }
}

// MARK: - SVG Metadata

struct SVGMetadata {
    var title: String?
    var description: String?
    var creator: String?
    var creationDate: Date?
    var software: String?
    var units: String = "px"
    
    init(
        title: String? = nil,
        description: String? = nil,
        creator: String? = nil,
        creationDate: Date? = nil,
        software: String? = nil,
        units: String = "px"
    ) {
        self.title = title
        self.description = description
        self.creator = creator
        self.creationDate = creationDate
        self.software = software
        self.units = units
    }
}

// MARK: - SVG Parse Error

enum SVGParseError: Error, LocalizedError {
    case fileNotFound
    case invalidFormat
    case noPathsFound
    case unsupportedFeature(String)
    case parsingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "SVG file not found"
        case .invalidFormat:
            return "Invalid SVG format"
        case .noPathsFound:
            return "No paths found in SVG"
        case .unsupportedFeature(let feature):
            return "Unsupported SVG feature: \(feature)"
        case .parsingFailed(let reason):
            return "Failed to parse SVG: \(reason)"
        }
    }
}

