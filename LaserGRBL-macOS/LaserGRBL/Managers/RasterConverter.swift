//
//  RasterConverter.swift
//  LaserGRBL
//
//  Created on October 11, 2025.
//  Phase 3: Image Import & Raster Conversion
//

import Foundation
import AppKit
import SwiftUI
import Combine

/// Converts raster images to G-code for laser engraving
@MainActor
class RasterConverter: ObservableObject {

    // MARK: - Published Properties

    /// Conversion progress (0.0 to 1.0)
    @Published var progress: Double = 0.0

    /// Is currently converting
    @Published var isConverting: Bool = false

    /// Generated G-code lines
    @Published var generatedGCode: [String] = []

    /// Conversion statistics
    @Published var stats: ConversionStats?

    // MARK: - Conversion

    /// Convert image to G-code
    func convert(image: RasterImage, settings: RasterSettings) async throws -> GCodeFile {
        await MainActor.run {
            isConverting = true
            progress = 0.0
            generatedGCode = []
            stats = nil
        }

        do {
            // Validate settings
            try settings.validate()

            // Step 1: Get pixel data (10% progress)
            let pixelData = try image.getPixelData()
            await updateProgress(0.1)

            // Step 2: Convert to grayscale (20%)
            let grayscaleData = convertToGrayscale(pixelData: pixelData, width: image.pixelWidth, height: image.pixelHeight)
            await updateProgress(0.2)

            // Step 3: Apply brightness/contrast/gamma (30%)
            let adjustedData = applyAdjustments(
                grayscaleData: grayscaleData,
                brightness: settings.brightness,
                contrast: settings.contrast,
                gamma: settings.gamma
            )
            await updateProgress(0.3)

            // Step 4: Process based on conversion mode (50%)
            let gcode: [String]
            switch settings.conversionMode {
            case .raster:
                // Apply dithering for raster engraving
                let ditheredData = applyDithering(
                    grayscaleData: adjustedData,
                    width: image.pixelWidth,
                    height: image.pixelHeight,
                    algorithm: settings.ditheringAlgorithm,
                    threshold: settings.threshold,
                    strength: settings.ditheringStrength,
                    invert: settings.invertImage
                )
                gcode = try generateRasterGCode(
                    bitmapData: ditheredData,
                    width: image.pixelWidth,
                    height: image.pixelHeight,
                    settings: settings
                )

            case .vectorize:
                // Generate vector G-code using edge detection
                gcode = try generateVectorGCode(
                    grayscaleData: adjustedData,
                    width: image.pixelWidth,
                    height: image.pixelHeight,
                    settings: settings
                )

            case .centerline:
                // Generate centerline G-code
                gcode = try generateCenterlineGCode(
                    grayscaleData: adjustedData,
                    width: image.pixelWidth,
                    height: image.pixelHeight,
                    settings: settings
                )
            }
            await updateProgress(0.9)

            // Step 6: Create GCodeFile object (100%)
            let gcodeFile = try await createGCodeFile(from: gcode, settings: settings, image: image)
            await updateProgress(1.0)

            await MainActor.run {
                isConverting = false
            }

            return gcodeFile

        } catch {
            await MainActor.run {
                isConverting = false
                progress = 0.0
            }
            throw error
        }
    }

    // MARK: - Image Processing

    /// Convert RGBA pixel data to grayscale
    private func convertToGrayscale(pixelData: [UInt8], width: Int, height: Int) -> [UInt8] {
        var grayscale = [UInt8](repeating: 0, count: width * height)

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let r = Double(pixelData[offset])
                let g = Double(pixelData[offset + 1])
                let b = Double(pixelData[offset + 2])

                // Use weighted average for perceptual grayscale
                let gray = UInt8(r * 0.299 + g * 0.587 + b * 0.114)
                grayscale[y * width + x] = gray
            }
        }

        return grayscale
    }

    /// Apply brightness, contrast, and gamma adjustments
    private func applyAdjustments(grayscaleData: [UInt8], brightness: Double, contrast: Double, gamma: Double) -> [UInt8] {
        return grayscaleData.map { pixel in
            var value = Double(pixel) / 255.0

            // Apply brightness (-1.0 to 1.0)
            value = value + brightness

            // Apply contrast (0.0 to 4.0)
            value = (value - 0.5) * contrast + 0.5

            // Apply gamma (0.1 to 3.0)
            if gamma != 1.0 {
                value = pow(value, 1.0 / gamma)
            }

            // Clamp to 0-1
            value = max(0.0, min(1.0, value))

            return UInt8(value * 255.0)
        }
    }

    /// Apply dithering algorithm
    private func applyDithering(
        grayscaleData: [UInt8],
        width: Int,
        height: Int,
        algorithm: RasterSettings.DitheringAlgorithm,
        threshold: Int,
        strength: Double,
        invert: Bool
    ) -> [Bool] {
        // Create mutable copy for error diffusion
        var workingData = grayscaleData.map { Double($0) }
        var bitmapData = [Bool](repeating: false, count: width * height)

        switch algorithm {
        case .none:
            // Simple threshold
            for i in 0..<workingData.count {
                let value = workingData[i]
                bitmapData[i] = value >= Double(threshold)
            }

        case .floydSteinberg:
            applyFloydSteinberg(data: &workingData, bitmap: &bitmapData, width: width, height: height, threshold: threshold, strength: strength)

        case .atkinson:
            applyAtkinson(data: &workingData, bitmap: &bitmapData, width: width, height: height, threshold: threshold, strength: strength)

        case .jarvisJudiceNinke:
            applyJarvisJudiceNinke(data: &workingData, bitmap: &bitmapData, width: width, height: height, threshold: threshold, strength: strength)

        case .stucki:
            applyStucki(data: &workingData, bitmap: &bitmapData, width: width, height: height, threshold: threshold, strength: strength)

        case .burkes:
            applyBurkes(data: &workingData, bitmap: &bitmapData, width: width, height: height, threshold: threshold, strength: strength)

        case .sierra:
            applySierra(data: &workingData, bitmap: &bitmapData, width: width, height: height, threshold: threshold, strength: strength)

        case .twoRowSierra:
            applyTwoRowSierra(data: &workingData, bitmap: &bitmapData, width: width, height: height, threshold: threshold, strength: strength)

        case .sierraLite:
            applySierraLite(data: &workingData, bitmap: &bitmapData, width: width, height: height, threshold: threshold, strength: strength)
        }

        // Apply inversion if needed
        if invert {
            bitmapData = bitmapData.map { !$0 }
        }

        return bitmapData
    }

    // MARK: - Dithering Algorithms

    /// Floyd-Steinberg dithering
    private func applyFloydSteinberg(data: inout [Double], bitmap: inout [Bool], width: Int, height: Int, threshold: Int, strength: Double) {
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let oldPixel = data[index]
                let newPixel = oldPixel >= Double(threshold) ? 255.0 : 0.0

                bitmap[index] = newPixel > 0
                let error = (oldPixel - newPixel) * strength

                // Distribute error
                if x + 1 < width {
                    data[index + 1] += error * 7.0 / 16.0
                }
                if y + 1 < height {
                    if x > 0 {
                        data[index + width - 1] += error * 3.0 / 16.0
                    }
                    data[index + width] += error * 5.0 / 16.0
                    if x + 1 < width {
                        data[index + width + 1] += error * 1.0 / 16.0
                    }
                }
            }
        }
    }

    /// Atkinson dithering
    private func applyAtkinson(data: inout [Double], bitmap: inout [Bool], width: Int, height: Int, threshold: Int, strength: Double) {
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let oldPixel = data[index]
                let newPixel = oldPixel >= Double(threshold) ? 255.0 : 0.0

                bitmap[index] = newPixel > 0
                let error = (oldPixel - newPixel) * strength / 8.0

                // Distribute error
                if x + 1 < width { data[index + 1] += error }
                if x + 2 < width { data[index + 2] += error }
                if y + 1 < height {
                    if x > 0 { data[index + width - 1] += error }
                    data[index + width] += error
                    if x + 1 < width { data[index + width + 1] += error }
                }
                if y + 2 < height {
                    data[index + width * 2] += error
                }
            }
        }
    }

    /// Jarvis-Judice-Ninke dithering
    private func applyJarvisJudiceNinke(data: inout [Double], bitmap: inout [Bool], width: Int, height: Int, threshold: Int, strength: Double) {
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let oldPixel = data[index]
                let newPixel = oldPixel >= Double(threshold) ? 255.0 : 0.0

                bitmap[index] = newPixel > 0
                let error = (oldPixel - newPixel) * strength / 48.0

                // Current row
                if x + 1 < width { data[index + 1] += error * 7.0 }
                if x + 2 < width { data[index + 2] += error * 5.0 }

                // Next row
                if y + 1 < height {
                    if x > 1 { data[index + width - 2] += error * 3.0 }
                    if x > 0 { data[index + width - 1] += error * 5.0 }
                    data[index + width] += error * 7.0
                    if x + 1 < width { data[index + width + 1] += error * 5.0 }
                    if x + 2 < width { data[index + width + 2] += error * 3.0 }
                }

                // Two rows down
                if y + 2 < height {
                    if x > 1 { data[index + width * 2 - 2] += error * 1.0 }
                    if x > 0 { data[index + width * 2 - 1] += error * 3.0 }
                    data[index + width * 2] += error * 5.0
                    if x + 1 < width { data[index + width * 2 + 1] += error * 3.0 }
                    if x + 2 < width { data[index + width * 2 + 2] += error * 1.0 }
                }
            }
        }
    }

    /// Stucki dithering
    private func applyStucki(data: inout [Double], bitmap: inout [Bool], width: Int, height: Int, threshold: Int, strength: Double) {
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let oldPixel = data[index]
                let newPixel = oldPixel >= Double(threshold) ? 255.0 : 0.0

                bitmap[index] = newPixel > 0
                let error = (oldPixel - newPixel) * strength / 42.0

                // Current row
                if x + 1 < width { data[index + 1] += error * 8.0 }
                if x + 2 < width { data[index + 2] += error * 4.0 }

                // Next row
                if y + 1 < height {
                    if x > 1 { data[index + width - 2] += error * 2.0 }
                    if x > 0 { data[index + width - 1] += error * 4.0 }
                    data[index + width] += error * 8.0
                    if x + 1 < width { data[index + width + 1] += error * 4.0 }
                    if x + 2 < width { data[index + width + 2] += error * 2.0 }
                }

                // Two rows down
                if y + 2 < height {
                    if x > 1 { data[index + width * 2 - 2] += error * 1.0 }
                    if x > 0 { data[index + width * 2 - 1] += error * 2.0 }
                    data[index + width * 2] += error * 4.0
                    if x + 1 < width { data[index + width * 2 + 1] += error * 2.0 }
                    if x + 2 < width { data[index + width * 2 + 2] += error * 1.0 }
                }
            }
        }
    }

    /// Burkes dithering
    private func applyBurkes(data: inout [Double], bitmap: inout [Bool], width: Int, height: Int, threshold: Int, strength: Double) {
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let oldPixel = data[index]
                let newPixel = oldPixel >= Double(threshold) ? 255.0 : 0.0

                bitmap[index] = newPixel > 0
                let error = (oldPixel - newPixel) * strength / 32.0

                // Current row
                if x + 1 < width { data[index + 1] += error * 8.0 }
                if x + 2 < width { data[index + 2] += error * 4.0 }

                // Next row
                if y + 1 < height {
                    if x > 1 { data[index + width - 2] += error * 2.0 }
                    if x > 0 { data[index + width - 1] += error * 4.0 }
                    data[index + width] += error * 8.0
                    if x + 1 < width { data[index + width + 1] += error * 4.0 }
                    if x + 2 < width { data[index + width + 2] += error * 2.0 }
                }
            }
        }
    }

    /// Sierra dithering
    private func applySierra(data: inout [Double], bitmap: inout [Bool], width: Int, height: Int, threshold: Int, strength: Double) {
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let oldPixel = data[index]
                let newPixel = oldPixel >= Double(threshold) ? 255.0 : 0.0

                bitmap[index] = newPixel > 0
                let error = (oldPixel - newPixel) * strength / 32.0

                // Current row
                if x + 1 < width { data[index + 1] += error * 5.0 }
                if x + 2 < width { data[index + 2] += error * 3.0 }

                // Next row
                if y + 1 < height {
                    if x > 1 { data[index + width - 2] += error * 2.0 }
                    if x > 0 { data[index + width - 1] += error * 4.0 }
                    data[index + width] += error * 5.0
                    if x + 1 < width { data[index + width + 1] += error * 4.0 }
                    if x + 2 < width { data[index + width + 2] += error * 2.0 }
                }

                // Two rows down
                if y + 2 < height {
                    if x > 0 { data[index + width * 2 - 1] += error * 2.0 }
                    data[index + width * 2] += error * 3.0
                    if x + 1 < width { data[index + width * 2 + 1] += error * 2.0 }
                }
            }
        }
    }

    /// Two-Row Sierra dithering
    private func applyTwoRowSierra(data: inout [Double], bitmap: inout [Bool], width: Int, height: Int, threshold: Int, strength: Double) {
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let oldPixel = data[index]
                let newPixel = oldPixel >= Double(threshold) ? 255.0 : 0.0

                bitmap[index] = newPixel > 0
                let error = (oldPixel - newPixel) * strength / 16.0

                // Current row
                if x + 1 < width { data[index + 1] += error * 4.0 }
                if x + 2 < width { data[index + 2] += error * 3.0 }

                // Next row
                if y + 1 < height {
                    if x > 1 { data[index + width - 2] += error * 1.0 }
                    if x > 0 { data[index + width - 1] += error * 2.0 }
                    data[index + width] += error * 3.0
                    if x + 1 < width { data[index + width + 1] += error * 2.0 }
                    if x + 2 < width { data[index + width + 2] += error * 1.0 }
                }
            }
        }
    }

    /// Sierra Lite dithering
    private func applySierraLite(data: inout [Double], bitmap: inout [Bool], width: Int, height: Int, threshold: Int, strength: Double) {
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let oldPixel = data[index]
                let newPixel = oldPixel >= Double(threshold) ? 255.0 : 0.0

                bitmap[index] = newPixel > 0
                let error = (oldPixel - newPixel) * strength / 4.0

                // Current row
                if x + 1 < width { data[index + 1] += error * 2.0 }

                // Next row
                if y + 1 < height {
                    if x > 0 { data[index + width - 1] += error * 1.0 }
                    data[index + width] += error * 1.0
                }
            }
        }
    }

    // MARK: - G-code Generation

    /// Generate raster G-code from bitmap data
    private func generateRasterGCode(
        bitmapData: [Bool],
        width: Int,
        height: Int,
        settings: RasterSettings
    ) throws -> [String] {
        var gcode: [String] = []
        var stats = ConversionStats()

        // Add header
        if settings.includeHeader {
            gcode.append("; LaserGRBL Raster Engraving")
            gcode.append("; Generated: \(Date().formatted())")
            gcode.append("; Image size: \(width) x \(height) pixels")
            gcode.append("; Physical size: \(String(format: "%.2f", settings.width)) x \(String(format: "%.2f", settings.height)) mm")
            gcode.append("; Resolution: \(String(format: "%.1f", settings.dpi)) DPI")
            gcode.append("; Line interval: \(String(format: "%.2f", settings.lineInterval)) mm")
            gcode.append("; Dithering: \(settings.ditheringAlgorithm.rawValue)")
            gcode.append("")
        }

        // Initialize
        gcode.append("; Initialize")
        if settings.useMillimeters {
            gcode.append("G21 ; Use millimeters")
        }
        if settings.useAbsolutePositioning {
            gcode.append("G90 ; Absolute positioning")
        }
        gcode.append("M5 ; Laser off")
        gcode.append("")

        // Move to start position
        let xOffset = settings.getEffectiveXOffset()
        let yOffset = settings.getEffectiveYOffset()

        gcode.append("; Move to start position")
        if settings.useRapidPositioning {
            gcode.append(String(format: "G0 X%.3f Y%.3f", xOffset, yOffset))
        } else {
            gcode.append(String(format: "G1 X%.3f Y%.3f F%d", xOffset, yOffset, settings.travelSpeed))
        }
        gcode.append("")

        // Calculate step size
        let pixelWidth = settings.width / Double(width)
        let lineStep = settings.lineInterval

        // Generate raster lines
        gcode.append("; Begin raster engraving")

        let laserMode = settings.useDynamicPower ? "M4" : "M3"

        for line in 0..<height {
            let yPos = yOffset + Double(line) * lineStep

            // Determine scan direction
            let isReverse = settings.engravingDirection == .bidirectional && line % 2 == 1
            let startX = isReverse ? width - 1 : 0
            let endX = isReverse ? -1 : width
            let step = isReverse ? -1 : 1

            var laserOn = false
            var runStart: Int?

            for x in stride(from: startX, to: endX, by: step) {
                let index = line * width + x
                let pixel = bitmapData[index]

                if pixel && !laserOn {
                    // Start laser run
                    runStart = x
                    laserOn = true
                } else if !pixel && laserOn {
                    // End laser run
                    if let start = runStart {
                        let runLength = abs(x - start)
                        if runLength >= settings.minPixelRun {
                            let x1 = xOffset + Double(start) * pixelWidth
                            let x2 = xOffset + Double(x) * pixelWidth

                            // Move to start with overscan
                            let overscanStart = isReverse ? x1 + settings.overscan : x1 - settings.overscan
                            if settings.useRapidPositioning {
                                gcode.append(String(format: "G0 X%.3f Y%.3f", overscanStart, yPos))
                            } else {
                                gcode.append(String(format: "G1 X%.3f Y%.3f F%d", overscanStart, yPos, settings.travelSpeed))
                            }

                            // Engrave line
                            gcode.append("\(laserMode) S\(settings.maxPower)")
                            gcode.append(String(format: "G1 X%.3f Y%.3f F%d", x2, yPos, settings.engravingSpeed))
                            gcode.append("M5")

                            stats.totalLines += 1
                            stats.totalDistance += Double(runLength) * pixelWidth
                        }
                    }
                    laserOn = false
                    runStart = nil
                }
            }

            // Handle run that extends to edge
            if laserOn, let start = runStart {
                let x1 = xOffset + Double(start) * pixelWidth
                let x2 = xOffset + (isReverse ? 0.0 : Double(width) * pixelWidth)

                let overscanStart = isReverse ? x1 + settings.overscan : x1 - settings.overscan
                if settings.useRapidPositioning {
                    gcode.append(String(format: "G0 X%.3f Y%.3f", overscanStart, yPos))
                } else {
                    gcode.append(String(format: "G1 X%.3f Y%.3f F%d", overscanStart, yPos, settings.travelSpeed))
                }

                gcode.append("\(laserMode) S\(settings.maxPower)")
                gcode.append(String(format: "G1 X%.3f Y%.3f F%d", x2, yPos, settings.engravingSpeed))
                gcode.append("M5")

                stats.totalLines += 1
            }

            // Update progress
            if line % 10 == 0 {
                let lineProgress = 0.5 + (Double(line) / Double(height)) * 0.4
                Task { await updateProgress(lineProgress) }
            }
        }

        gcode.append("")

        // Footer
        gcode.append("; End raster engraving")
        gcode.append("M5 ; Laser off")

        if settings.homeAfterCompletion {
            if settings.useRapidPositioning {
                gcode.append("G0 X0 Y0 ; Return to origin")
            } else {
                gcode.append(String(format: "G1 X0 Y0 F%d ; Return to origin", settings.travelSpeed))
            }
        }

        if settings.includeFooter {
            gcode.append("")
            gcode.append("; Engraving complete")
            gcode.append("; Total lines: \(stats.totalLines)")
            gcode.append("; Total distance: \(String(format: "%.2f", stats.totalDistance)) mm")
        }

        stats.totalCommands = gcode.filter { !$0.isEmpty && !$0.hasPrefix(";") }.count

        // Debug output
        print("🔧 Raster Debug:")
        print("   Image size: \(width) x \(height)")
        print("   Physical size: \(String(format: "%.2f", settings.width)) x \(String(format: "%.2f", settings.height)) mm")
        print("   DPI: \(String(format: "%.1f", settings.dpi))")
        print("   Pixel width: \(String(format: "%.4f", pixelWidth)) mm")
        print("   Line interval: \(String(format: "%.3f", lineStep)) mm")
        print("   Total G-code lines: \(gcode.count)")
        print("   Motion commands: \(stats.totalCommands)")
        print("   Sample G-code (first 10 lines):")
        for (i, line) in gcode.prefix(10).enumerated() {
            print("     \(i+1): \(line)")
        }

        Task { @MainActor in
            self.stats = stats
            self.generatedGCode = gcode
        }

        return gcode
    }

    /// Generate vector G-code using edge detection
    private func generateVectorGCode(
        grayscaleData: [UInt8],
        width: Int,
        height: Int,
        settings: RasterSettings
    ) throws -> [String] {
        // TODO: Implement vector cutting using edge detection
        // For now, return a simple message
        return [
            "; Vector Cutting - Coming Soon!",
            "; This will trace the edges of your line art",
            "; for clean, precise cutting instead of raster engraving",
            "G21 ; Use millimeters",
            "G90 ; Absolute positioning",
            "M5 ; Laser off",
            "; Vector paths will be generated here",
            "M5 ; Laser off"
        ]
    }

    /// Generate centerline G-code
    private func generateCenterlineGCode(
        grayscaleData: [UInt8],
        width: Int,
        height: Int,
        settings: RasterSettings
    ) throws -> [String] {
        // TODO: Implement centerline vectorization
        // For now, return a simple message
        return [
            "; Centerline Vectorization - Coming Soon!",
            "; This will trace the center of thin lines",
            "; perfect for detailed line art",
            "G21 ; Use millimeters",
            "G90 ; Absolute positioning",
            "M5 ; Laser off",
            "; Centerline paths will be generated here",
            "M5 ; Laser off"
        ]
    }

    /// Create GCodeFile from generated code
    private func createGCodeFile(from gcode: [String], settings: RasterSettings, image: RasterImage) async throws -> GCodeFile {
        let gcodeText = gcode.joined(separator: "\n")
        let gcodeFile = GCodeFile()

        // Parse the generated G-code
        try await gcodeFile.loadFromText(gcodeText)

        return gcodeFile
    }

    // MARK: - Helper Methods

    private func updateProgress(_ value: Double) async {
        await MainActor.run {
            self.progress = value
        }
    }
}

// MARK: - Conversion Statistics

struct ConversionStats {
    var totalCommands: Int = 0
    var totalLines: Int = 0
    var totalDistance: Double = 0.0
    var estimatedTime: TimeInterval = 0.0
}
