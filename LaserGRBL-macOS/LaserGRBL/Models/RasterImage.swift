//
//  RasterImage.swift
//  LaserGRBL
//
//  Created on October 11, 2025.
//  Phase 3: Image Import & Raster Conversion
//

import SwiftUI
import CoreImage
import AppKit
import Combine

/// Represents an imported image for raster laser engraving
class RasterImage: ObservableObject, Identifiable {
    let id = UUID()

    // MARK: - Properties

    /// Original imported image
    @Published var originalImage: NSImage

    /// Processed grayscale image
    @Published var processedImage: NSImage?

    /// Image metadata
    @Published var fileName: String
    @Published var fileSize: Int64
    @Published var pixelWidth: Int
    @Published var pixelHeight: Int
    @Published var dpi: Double

    /// Physical dimensions (in mm)
    @Published var physicalWidth: Double
    @Published var physicalHeight: Double

    /// Processing status
    @Published var isProcessing: Bool = false
    @Published var processingProgress: Double = 0.0

    // MARK: - Initialization

    init(image: NSImage, fileName: String, fileSize: Int64) {
        self.originalImage = image
        self.fileName = fileName
        self.fileSize = fileSize

        // Get image dimensions
        let width: Int
        let height: Int
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            width = cgImage.width
            height = cgImage.height
        } else {
            width = Int(image.size.width)
            height = Int(image.size.height)
        }
        self.pixelWidth = width
        self.pixelHeight = height

        // Default DPI (can be updated from file metadata)
        let dpiValue = 254.0 // 254 DPI = 0.1mm per pixel (good default for laser engraving)
        self.dpi = dpiValue

        // Calculate physical dimensions
        self.physicalWidth = Double(width) / dpiValue * 25.4 // Convert to mm
        self.physicalHeight = Double(height) / dpiValue * 25.4
    }

    // MARK: - Image Processing

    /// Convert image to grayscale
    func convertToGrayscale() async throws -> NSImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: RasterImageError.processingFailed)
                    return
                }

                guard let cgImage = self.originalImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                    continuation.resume(throwing: RasterImageError.invalidImage)
                    return
                }

                // Create CIImage from CGImage
                let ciImage = CIImage(cgImage: cgImage)

                // Apply grayscale filter
                guard let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono") else {
                    continuation.resume(throwing: RasterImageError.filterNotAvailable)
                    return
                }

                grayscaleFilter.setValue(ciImage, forKey: kCIInputImageKey)

                guard let outputImage = grayscaleFilter.outputImage else {
                    continuation.resume(throwing: RasterImageError.processingFailed)
                    return
                }

                // Convert back to NSImage
                let context = CIContext()
                guard let cgOutput = context.createCGImage(outputImage, from: outputImage.extent) else {
                    continuation.resume(throwing: RasterImageError.processingFailed)
                    return
                }

                let nsImage = NSImage(cgImage: cgOutput, size: NSSize(width: cgOutput.width, height: cgOutput.height))

                DispatchQueue.main.async {
                    self.processedImage = nsImage
                }

                continuation.resume(returning: nsImage)
            }
        }
    }

    /// Adjust brightness and contrast
    func adjustBrightnessContrast(brightness: Double, contrast: Double) async throws -> NSImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: RasterImageError.processingFailed)
                    return
                }

                let sourceImage = self.processedImage ?? self.originalImage

                guard let cgImage = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                    continuation.resume(throwing: RasterImageError.invalidImage)
                    return
                }

                let ciImage = CIImage(cgImage: cgImage)

                // Apply brightness and contrast
                guard let filter = CIFilter(name: "CIColorControls") else {
                    continuation.resume(throwing: RasterImageError.filterNotAvailable)
                    return
                }

                filter.setValue(ciImage, forKey: kCIInputImageKey)
                filter.setValue(brightness, forKey: kCIInputBrightnessKey) // -1.0 to 1.0
                filter.setValue(contrast, forKey: kCIInputContrastKey)     // 0.0 to 4.0

                guard let outputImage = filter.outputImage else {
                    continuation.resume(throwing: RasterImageError.processingFailed)
                    return
                }

                let context = CIContext()
                guard let cgOutput = context.createCGImage(outputImage, from: outputImage.extent) else {
                    continuation.resume(throwing: RasterImageError.processingFailed)
                    return
                }

                let nsImage = NSImage(cgImage: cgOutput, size: NSSize(width: cgOutput.width, height: cgOutput.height))

                DispatchQueue.main.async {
                    self.processedImage = nsImage
                }

                continuation.resume(returning: nsImage)
            }
        }
    }

    /// Get pixel data for processing
    func getPixelData() throws -> [UInt8] {
        let sourceImage = processedImage ?? originalImage

        guard let cgImage = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw RasterImageError.invalidImage
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        guard let ctx = context else {
            throw RasterImageError.processingFailed
        }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return pixelData
    }

    /// Update physical dimensions based on DPI
    func updateDimensions(dpi: Double) {
        self.dpi = dpi
        self.physicalWidth = Double(pixelWidth) / dpi * 25.4
        self.physicalHeight = Double(pixelHeight) / dpi * 25.4
    }

    /// Resize image to target dimensions
    func resize(targetWidth: Double, targetHeight: Double) async throws -> NSImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: RasterImageError.processingFailed)
                    return
                }

                let sourceImage = self.processedImage ?? self.originalImage

                let newSize = NSSize(width: targetWidth, height: targetHeight)
                let newImage = NSImage(size: newSize)

                newImage.lockFocus()
                sourceImage.draw(
                    in: NSRect(origin: .zero, size: newSize),
                    from: NSRect(origin: .zero, size: sourceImage.size),
                    operation: .copy,
                    fraction: 1.0
                )
                newImage.unlockFocus()

                DispatchQueue.main.async {
                    self.processedImage = newImage
                    if let cgImage = newImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                        self.pixelWidth = cgImage.width
                        self.pixelHeight = cgImage.height
                    }
                }

                continuation.resume(returning: newImage)
            }
        }
    }

    // MARK: - Helper Methods

    /// Get file size as human-readable string
    func getFileSizeString() -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    /// Get aspect ratio
    func getAspectRatio() -> Double {
        return Double(pixelWidth) / Double(pixelHeight)
    }
}

// MARK: - Error Types

enum RasterImageError: LocalizedError {
    case invalidImage
    case filterNotAvailable
    case processingFailed
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image file is invalid or corrupted"
        case .filterNotAvailable:
            return "Required image filter is not available"
        case .processingFailed:
            return "Image processing failed"
        case .unsupportedFormat:
            return "Unsupported image format"
        }
    }
}
