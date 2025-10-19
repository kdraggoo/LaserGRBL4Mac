//
//  RasterSettings.swift
//  LaserGRBL
//
//  Created on October 11, 2025.
//  Phase 3: Image Import & Raster Conversion
//

import Foundation
import Combine

/// Settings for raster G-code conversion
class RasterSettings: ObservableObject, Codable {

    // MARK: - Engraving Mode

    /// Engraving direction
    enum EngravingDirection: String, Codable, CaseIterable {
        case horizontal = "Horizontal (Left to Right)"
        case vertical = "Vertical (Top to Bottom)"
        case diagonal = "Diagonal"
        case bidirectional = "Bidirectional (Zigzag)"
    }

    /// Line direction for bidirectional engraving
    enum LineDirection: String, Codable {
        case leftToRight = "Left to Right"
        case rightToLeft = "Right to Left"
        case topToBottom = "Top to Bottom"
        case bottomToTop = "Bottom to Top"
    }

    // MARK: - Dithering Algorithm

    /// Dithering algorithms for 1-bit conversion
    enum DitheringAlgorithm: String, Codable, CaseIterable, Identifiable {
        case none = "None (Threshold)"
        case floydSteinberg = "Floyd-Steinberg"
        case atkinson = "Atkinson"
        case jarvisJudiceNinke = "Jarvis-Judice-Ninke"
        case stucki = "Stucki"
        case burkes = "Burkes"
        case sierra = "Sierra"
        case twoRowSierra = "Two-Row Sierra"
        case sierraLite = "Sierra Lite"

        var id: String { rawValue }

        var description: String {
            switch self {
            case .none:
                return "Simple threshold without dithering. Fast but loses detail."
            case .floydSteinberg:
                return "Classic error diffusion. Good balance of speed and quality."
            case .atkinson:
                return "Lighter dithering with less noise. Good for photos."
            case .jarvisJudiceNinke:
                return "High-quality diffusion with wider error distribution."
            case .stucki:
                return "Similar to Jarvis but slightly faster."
            case .burkes:
                return "Simplified error diffusion, faster than Floyd-Steinberg."
            case .sierra:
                return "Three-row error diffusion. Very high quality."
            case .twoRowSierra:
                return "Two-row variant of Sierra. Good quality, faster."
            case .sierraLite:
                return "Lightweight Sierra variant. Fast with good results."
            }
        }
    }

    // MARK: - Conversion Mode

    /// Conversion mode for image processing
    @Published var conversionMode: ConversionMode = .raster

    enum ConversionMode: String, CaseIterable, Codable {
        case raster = "Raster Engraving"
        case vectorize = "Vector Cutting"
        case centerline = "Centerline"

        var description: String {
            switch self {
            case .raster:
                return "Line-by-line raster engraving. Good for photos and detailed images."
            case .vectorize:
                return "Vector cutting using edge detection. Perfect for line art and logos."
            case .centerline:
                return "Centerline vectorization. Good for thin line art."
            }
        }
    }

    // MARK: - Resolution & Dimensions

    /// Resolution in dots per inch
    @Published var dpi: Double = 254.0 // 0.1mm per pixel

    /// Line interval in millimeters (distance between scan lines)
    @Published var lineInterval: Double = 0.1

    /// Physical width in millimeters
    @Published var width: Double = 100.0

    /// Physical height in millimeters
    @Published var height: Double = 100.0

    /// Lock aspect ratio when resizing
    @Published var lockAspectRatio: Bool = true

    // MARK: - Image Processing

    /// Brightness adjustment (-1.0 to 1.0)
    @Published var brightness: Double = 0.0

    /// Contrast adjustment (0.0 to 4.0, 1.0 = normal)
    @Published var contrast: Double = 1.0

    /// Gamma correction (0.1 to 3.0, 1.0 = no correction)
    @Published var gamma: Double = 1.0

    /// Invert image (white becomes black, black becomes white)
    @Published var invertImage: Bool = false

    /// Threshold for binary conversion (0-255)
    @Published var threshold: Int = 128

    // MARK: - Dithering

    /// Selected dithering algorithm
    @Published var ditheringAlgorithm: DitheringAlgorithm = .floydSteinberg

    /// Dithering strength (0.0 to 1.0)
    @Published var ditheringStrength: Double = 1.0

    // MARK: - Engraving Direction

    /// Engraving direction
    @Published var engravingDirection: EngravingDirection = .bidirectional

    /// Reverse engraving direction
    @Published var reverseDirection: Bool = false

    // MARK: - Laser Power

    /// Minimum laser power (0-1000)
    @Published var minPower: Int = 0

    /// Maximum laser power (0-1000)
    @Published var maxPower: Int = 1000

    /// Use variable power based on pixel intensity
    @Published var useVariablePower: Bool = true

    /// Laser mode (M3 = constant, M4 = dynamic)
    @Published var useDynamicPower: Bool = true // M4

    // MARK: - Feed Rates

    /// Engraving feed rate (mm/min)
    @Published var engravingSpeed: Int = 1000

    /// Travel feed rate when moving between lines (mm/min)
    @Published var travelSpeed: Int = 3000

    // MARK: - Optimization

    /// Skip white pixels (laser off optimization)
    @Published var skipWhitePixels: Bool = true

    /// Minimum pixel run length to engrave (optimization)
    @Published var minPixelRun: Int = 1

    /// Overscan distance in millimeters (move beyond image edges)
    @Published var overscan: Double = 2.0

    /// Use G0 for rapid moves (vs G1 with travelSpeed)
    @Published var useRapidPositioning: Bool = true

    // MARK: - Positioning

    /// X offset from origin (mm)
    @Published var xOffset: Double = 0.0

    /// Y offset from origin (mm)
    @Published var yOffset: Double = 0.0

    /// Center image on work area
    @Published var centerOnWorkArea: Bool = false

    /// Work area width (mm) - for centering
    @Published var workAreaWidth: Double = 300.0

    /// Work area height (mm) - for centering
    @Published var workAreaHeight: Double = 200.0

    // MARK: - G-code Options

    /// Add header comment with settings
    @Published var includeHeader: Bool = true

    /// Add footer comment
    @Published var includeFooter: Bool = true

    /// Home after completion
    @Published var homeAfterCompletion: Bool = false

    /// Use absolute positioning (G90)
    @Published var useAbsolutePositioning: Bool = true

    /// Use millimeters (G21)
    @Published var useMillimeters: Bool = true

    // MARK: - Initialization

    init() {}

    // MARK: - Defaults

    static var `default`: RasterSettings {
        return RasterSettings()
    }

    static var highQuality: RasterSettings {
        var settings = RasterSettings()
        settings.dpi = 508.0 // 0.05mm per pixel
        settings.lineInterval = 0.05
        settings.ditheringAlgorithm = .jarvisJudiceNinke
        settings.engravingSpeed = 800
        return settings
    }

    static var highSpeed: RasterSettings {
        var settings = RasterSettings()
        settings.dpi = 127.0 // 0.2mm per pixel
        settings.lineInterval = 0.2
        settings.ditheringAlgorithm = .floydSteinberg
        settings.engravingSpeed = 2000
        settings.skipWhitePixels = true
        return settings
    }

    static var photo: RasterSettings {
        var settings = RasterSettings()
        settings.dpi = 318.0 // 0.08mm per pixel
        settings.lineInterval = 0.08
        settings.ditheringAlgorithm = .atkinson
        settings.useVariablePower = true
        settings.engravingSpeed = 1000
        return settings
    }

    // MARK: - Computed Properties

    /// Pixels per millimeter
    var pixelsPerMM: Double {
        return dpi / 25.4
    }

    /// Get effective X offset (with centering)
    func getEffectiveXOffset() -> Double {
        if centerOnWorkArea {
            return (workAreaWidth - width) / 2.0
        }
        return xOffset
    }

    /// Get effective Y offset (with centering)
    func getEffectiveYOffset() -> Double {
        if centerOnWorkArea {
            return (workAreaHeight - height) / 2.0
        }
        return yOffset
    }

    /// Validate settings
    func validate() throws {
        guard dpi > 0 && dpi <= 2540 else {
            throw RasterSettingsError.invalidDPI
        }

        guard lineInterval > 0 && lineInterval <= 10 else {
            throw RasterSettingsError.invalidLineInterval
        }

        guard width > 0 && width <= 1000 else {
            throw RasterSettingsError.invalidDimensions
        }

        guard height > 0 && height <= 1000 else {
            throw RasterSettingsError.invalidDimensions
        }

        guard minPower >= 0 && minPower <= 1000 else {
            throw RasterSettingsError.invalidPower
        }

        guard maxPower >= 0 && maxPower <= 1000 else {
            throw RasterSettingsError.invalidPower
        }

        guard minPower <= maxPower else {
            throw RasterSettingsError.invalidPower
        }

        guard engravingSpeed > 0 && engravingSpeed <= 10000 else {
            throw RasterSettingsError.invalidSpeed
        }

        guard travelSpeed > 0 && travelSpeed <= 10000 else {
            throw RasterSettingsError.invalidSpeed
        }
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case dpi, lineInterval, width, height, lockAspectRatio
        case brightness, contrast, gamma, invertImage, threshold
        case ditheringAlgorithm, ditheringStrength
        case engravingDirection, reverseDirection
        case minPower, maxPower, useVariablePower, useDynamicPower
        case engravingSpeed, travelSpeed
        case skipWhitePixels, minPixelRun, overscan, useRapidPositioning
        case xOffset, yOffset, centerOnWorkArea, workAreaWidth, workAreaHeight
        case includeHeader, includeFooter, homeAfterCompletion
        case useAbsolutePositioning, useMillimeters
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        dpi = try container.decode(Double.self, forKey: .dpi)
        lineInterval = try container.decode(Double.self, forKey: .lineInterval)
        width = try container.decode(Double.self, forKey: .width)
        height = try container.decode(Double.self, forKey: .height)
        lockAspectRatio = try container.decode(Bool.self, forKey: .lockAspectRatio)

        brightness = try container.decode(Double.self, forKey: .brightness)
        contrast = try container.decode(Double.self, forKey: .contrast)
        gamma = try container.decode(Double.self, forKey: .gamma)
        invertImage = try container.decode(Bool.self, forKey: .invertImage)
        threshold = try container.decode(Int.self, forKey: .threshold)

        ditheringAlgorithm = try container.decode(DitheringAlgorithm.self, forKey: .ditheringAlgorithm)
        ditheringStrength = try container.decode(Double.self, forKey: .ditheringStrength)

        engravingDirection = try container.decode(EngravingDirection.self, forKey: .engravingDirection)
        reverseDirection = try container.decode(Bool.self, forKey: .reverseDirection)

        minPower = try container.decode(Int.self, forKey: .minPower)
        maxPower = try container.decode(Int.self, forKey: .maxPower)
        useVariablePower = try container.decode(Bool.self, forKey: .useVariablePower)
        useDynamicPower = try container.decode(Bool.self, forKey: .useDynamicPower)

        engravingSpeed = try container.decode(Int.self, forKey: .engravingSpeed)
        travelSpeed = try container.decode(Int.self, forKey: .travelSpeed)

        skipWhitePixels = try container.decode(Bool.self, forKey: .skipWhitePixels)
        minPixelRun = try container.decode(Int.self, forKey: .minPixelRun)
        overscan = try container.decode(Double.self, forKey: .overscan)
        useRapidPositioning = try container.decode(Bool.self, forKey: .useRapidPositioning)

        xOffset = try container.decode(Double.self, forKey: .xOffset)
        yOffset = try container.decode(Double.self, forKey: .yOffset)
        centerOnWorkArea = try container.decode(Bool.self, forKey: .centerOnWorkArea)
        workAreaWidth = try container.decode(Double.self, forKey: .workAreaWidth)
        workAreaHeight = try container.decode(Double.self, forKey: .workAreaHeight)

        includeHeader = try container.decode(Bool.self, forKey: .includeHeader)
        includeFooter = try container.decode(Bool.self, forKey: .includeFooter)
        homeAfterCompletion = try container.decode(Bool.self, forKey: .homeAfterCompletion)
        useAbsolutePositioning = try container.decode(Bool.self, forKey: .useAbsolutePositioning)
        useMillimeters = try container.decode(Bool.self, forKey: .useMillimeters)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(dpi, forKey: .dpi)
        try container.encode(lineInterval, forKey: .lineInterval)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(lockAspectRatio, forKey: .lockAspectRatio)

        try container.encode(brightness, forKey: .brightness)
        try container.encode(contrast, forKey: .contrast)
        try container.encode(gamma, forKey: .gamma)
        try container.encode(invertImage, forKey: .invertImage)
        try container.encode(threshold, forKey: .threshold)

        try container.encode(ditheringAlgorithm, forKey: .ditheringAlgorithm)
        try container.encode(ditheringStrength, forKey: .ditheringStrength)

        try container.encode(engravingDirection, forKey: .engravingDirection)
        try container.encode(reverseDirection, forKey: .reverseDirection)

        try container.encode(minPower, forKey: .minPower)
        try container.encode(maxPower, forKey: .maxPower)
        try container.encode(useVariablePower, forKey: .useVariablePower)
        try container.encode(useDynamicPower, forKey: .useDynamicPower)

        try container.encode(engravingSpeed, forKey: .engravingSpeed)
        try container.encode(travelSpeed, forKey: .travelSpeed)

        try container.encode(skipWhitePixels, forKey: .skipWhitePixels)
        try container.encode(minPixelRun, forKey: .minPixelRun)
        try container.encode(overscan, forKey: .overscan)
        try container.encode(useRapidPositioning, forKey: .useRapidPositioning)

        try container.encode(xOffset, forKey: .xOffset)
        try container.encode(yOffset, forKey: .yOffset)
        try container.encode(centerOnWorkArea, forKey: .centerOnWorkArea)
        try container.encode(workAreaWidth, forKey: .workAreaWidth)
        try container.encode(workAreaHeight, forKey: .workAreaHeight)

        try container.encode(includeHeader, forKey: .includeHeader)
        try container.encode(includeFooter, forKey: .includeFooter)
        try container.encode(homeAfterCompletion, forKey: .homeAfterCompletion)
        try container.encode(useAbsolutePositioning, forKey: .useAbsolutePositioning)
        try container.encode(useMillimeters, forKey: .useMillimeters)
    }
}

// MARK: - Error Types

enum RasterSettingsError: LocalizedError {
    case invalidDPI
    case invalidLineInterval
    case invalidDimensions
    case invalidPower
    case invalidSpeed

    var errorDescription: String? {
        switch self {
        case .invalidDPI:
            return "DPI must be between 1 and 2540"
        case .invalidLineInterval:
            return "Line interval must be between 0 and 10mm"
        case .invalidDimensions:
            return "Image dimensions must be between 0 and 1000mm"
        case .invalidPower:
            return "Power values must be between 0 and 1000, with min ≤ max"
        case .invalidSpeed:
            return "Speed values must be between 0 and 10000 mm/min"
        }
    }
}
