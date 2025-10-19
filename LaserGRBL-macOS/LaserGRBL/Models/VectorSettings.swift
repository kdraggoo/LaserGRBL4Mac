//
//  VectorSettings.swift
//  LaserGRBL
//
//  Phase 4: SVG Vector Import
//  Created on October 19, 2025
//

import Foundation
import AppKit
import Combine

/// Settings for SVG to G-code conversion
class VectorSettings: ObservableObject {
    
    // MARK: - Conversion Settings
    
    /// Tolerance for curve approximation (mm)
    @Published var tolerance: Double = 0.1
    
    /// Feed rate for cutting/engraving (mm/min)
    @Published var feedRate: Int = 1000
    
    /// Laser power (S value, 0-1000)
    @Published var laserPower: Int = 800
    
    /// Depth per pass (mm)
    @Published var passDepth: Double = 0.5
    
    /// Number of passes
    @Published var passes: Int = 1
    
    // MARK: - Path Optimization
    
    /// Optimize path order to minimize travel
    @Published var optimizeOrder: Bool = true
    
    /// Minimize rapid travel moves
    @Published var minimizeTravel: Bool = true
    
    /// Group paths by color/layer
    @Published var groupByColor: Bool = false
    
    /// Start from origin (0,0)
    @Published var startFromOrigin: Bool = true
    
    // MARK: - Rendering Mode
    
    /// How to render the paths
    @Published var renderMode: RenderMode = .stroke
    
    enum RenderMode: String, CaseIterable, Identifiable {
        case stroke = "Stroke Only"
        case fill = "Fill Only"
        case strokeAndFill = "Stroke & Fill"
        
        var id: String { rawValue }
    }
    
    // MARK: - Fill Settings
    
    /// Fill pattern type
    @Published var fillPattern: FillPattern = .horizontal
    
    enum FillPattern: String, CaseIterable, Identifiable {
        case horizontal = "Horizontal Lines"
        case vertical = "Vertical Lines"
        case diagonal = "Diagonal Lines"
        case crosshatch = "Crosshatch"
        case spiral = "Spiral"
        
        var id: String { rawValue }
    }
    
    /// Fill line spacing (mm)
    @Published var fillSpacing: Double = 0.5
    
    /// Fill angle (degrees, for diagonal patterns)
    @Published var fillAngle: Double = 45
    
    // MARK: - Advanced Settings
    
    /// Use G2/G3 arc commands when possible
    @Published var useArcCommands: Bool = false
    
    /// Arc fitting tolerance (mm)
    @Published var arcTolerance: Double = 0.05
    
    /// Add Z-axis moves (for 3D work)
    @Published var enableZAxis: Bool = false
    
    /// Z safe height (mm)
    @Published var zSafeHeight: Double = 5.0
    
    /// Z cutting height (mm)
    @Published var zCutHeight: Double = 0.0
    
    // MARK: - Units
    
    /// Output units
    @Published var units: Units = .millimeters
    
    enum Units: String, CaseIterable, Identifiable {
        case millimeters = "Millimeters (G21)"
        case inches = "Inches (G20)"
        
        var id: String { rawValue }
        
        var gcode: String {
            switch self {
            case .millimeters: return "G21"
            case .inches: return "G20"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Use default values
    }
    
    init(preset: VectorPreset) {
        applyPreset(preset)
    }
    
    // MARK: - Presets
    
    func applyPreset(_ preset: VectorPreset) {
        tolerance = preset.tolerance
        feedRate = preset.feedRate
        laserPower = preset.laserPower
        passDepth = preset.passDepth
        passes = preset.passes
        optimizeOrder = preset.optimizeOrder
        minimizeTravel = preset.minimizeTravel
        renderMode = preset.renderMode
        fillSpacing = preset.fillSpacing
        useArcCommands = preset.useArcCommands
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        tolerance > 0 &&
        feedRate > 0 &&
        laserPower >= 0 && laserPower <= 1000 &&
        passDepth > 0 &&
        passes > 0 &&
        fillSpacing > 0
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        if tolerance <= 0 {
            errors.append("Tolerance must be greater than 0")
        }
        if feedRate <= 0 {
            errors.append("Feed rate must be greater than 0")
        }
        if laserPower < 0 || laserPower > 1000 {
            errors.append("Laser power must be between 0 and 1000")
        }
        if passDepth <= 0 {
            errors.append("Pass depth must be greater than 0")
        }
        if passes <= 0 {
            errors.append("Number of passes must be at least 1")
        }
        if fillSpacing <= 0 {
            errors.append("Fill spacing must be greater than 0")
        }
        
        return errors
    }
}

// MARK: - Vector Preset

struct VectorPreset: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let tolerance: Double
    let feedRate: Int
    let laserPower: Int
    let passDepth: Double
    let passes: Int
    let optimizeOrder: Bool
    let minimizeTravel: Bool
    let renderMode: VectorSettings.RenderMode
    let fillSpacing: Double
    let useArcCommands: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        tolerance: Double = 0.1,
        feedRate: Int = 1000,
        laserPower: Int = 800,
        passDepth: Double = 0.5,
        passes: Int = 1,
        optimizeOrder: Bool = true,
        minimizeTravel: Bool = true,
        renderMode: VectorSettings.RenderMode = .stroke,
        fillSpacing: Double = 0.5,
        useArcCommands: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.tolerance = tolerance
        self.feedRate = feedRate
        self.laserPower = laserPower
        self.passDepth = passDepth
        self.passes = passes
        self.optimizeOrder = optimizeOrder
        self.minimizeTravel = minimizeTravel
        self.renderMode = renderMode
        self.fillSpacing = fillSpacing
        self.useArcCommands = useArcCommands
    }
    
    // MARK: - Default Presets
    
    static let presets: [VectorPreset] = [
        .fast,
        .balanced,
        .highQuality,
        .cutting,
        .engraving
    ]
    
    /// Fast preview/testing
    static let fast = VectorPreset(
        name: "Fast Preview",
        description: "Quick conversion for testing (lower quality)",
        tolerance: 0.5,
        feedRate: 2000,
        laserPower: 500,
        passDepth: 1.0,
        passes: 1,
        useArcCommands: false
    )
    
    /// Balanced quality and speed
    static let balanced = VectorPreset(
        name: "Balanced",
        description: "Good balance of quality and speed",
        tolerance: 0.1,
        feedRate: 1000,
        laserPower: 800,
        passDepth: 0.5,
        passes: 1,
        useArcCommands: false
    )
    
    /// High quality, slower
    static let highQuality = VectorPreset(
        name: "High Quality",
        description: "Best quality (slower conversion)",
        tolerance: 0.05,
        feedRate: 500,
        laserPower: 800,
        passDepth: 0.25,
        passes: 2,
        useArcCommands: true
    )
    
    /// Cutting through material
    static let cutting = VectorPreset(
        name: "Cutting",
        description: "Cut through material (multiple passes)",
        tolerance: 0.1,
        feedRate: 300,
        laserPower: 1000,
        passDepth: 0.5,
        passes: 3,
        useArcCommands: false
    )
    
    /// Surface engraving
    static let engraving = VectorPreset(
        name: "Engraving",
        description: "Surface engraving (single pass)",
        tolerance: 0.08,
        feedRate: 800,
        laserPower: 600,
        passDepth: 0.1,
        passes: 1,
        useArcCommands: true
    )
}

