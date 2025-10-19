//
//  ImageImporter.swift
//  LaserGRBL
//
//  Created on October 11, 2025.
//  Phase 3: Image Import & Raster Conversion
//

import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers

/// Manager for importing image files for raster engraving
@MainActor
class ImageImporter: ObservableObject {

    // MARK: - Published Properties

    /// Currently loaded image
    @Published var currentImage: RasterImage?

    /// Loading state
    @Published var isLoading: Bool = false

    /// Error message
    @Published var errorMessage: String?

    /// Show error alert
    @Published var showError: Bool = false
    
    /// Raster conversion settings (shared with settings window)
    @Published var rasterSettings: RasterSettings = .default

    // MARK: - Supported File Types

    static let supportedTypes: [UTType] = [
        .png,
        .jpeg,
        .bmp,
        .tiff,
        .gif,
        .heic
    ]

    static let supportedExtensions = ["png", "jpg", "jpeg", "bmp", "tif", "tiff", "gif", "heic"]

    // MARK: - Import Methods

    /// Show file picker and import image
    func importImage() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        // Create open panel
        let panel = NSOpenPanel()
        panel.title = "Import Image"
        panel.message = "Choose an image file to convert to G-code"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = Self.supportedTypes

        // Show panel
        let response = await panel.begin()

        guard response == .OK, let url = panel.url else {
            await MainActor.run {
                isLoading = false
            }
            return
        }

        // Load image from URL
        await loadImage(from: url)
    }

    /// Load image from URL
    func loadImage(from url: URL) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            // Start accessing security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            // Read file attributes
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0

            // Load image
            guard let nsImage = NSImage(contentsOf: url) else {
                throw ImageImportError.invalidImage
            }

            // Validate image
            guard nsImage.isValid else {
                throw ImageImportError.invalidImage
            }

            // Create RasterImage
            let fileName = url.lastPathComponent
            let rasterImage = RasterImage(image: nsImage, fileName: fileName, fileSize: fileSize)

            // Try to read DPI from file metadata
            if let dpi = try? readDPIFromImage(url: url) {
                rasterImage.updateDimensions(dpi: dpi)
            }

            await MainActor.run {
                self.currentImage = rasterImage
                self.isLoading = false
            }

        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
            }
        }
    }

    /// Read DPI from image metadata
    private func readDPIFromImage(url: URL) throws -> Double? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return nil
        }

        // Try to get DPI from various metadata keys
        if let dpiWidth = imageProperties[kCGImagePropertyDPIWidth as String] as? Double,
           dpiWidth > 0 {
            return dpiWidth
        }

        if let dpiHeight = imageProperties[kCGImagePropertyDPIHeight as String] as? Double,
           dpiHeight > 0 {
            return dpiHeight
        }

        return nil
    }

    /// Clear current image
    func clearImage() {
        currentImage = nil
        errorMessage = nil
        showError = false
    }

    /// Check if file type is supported
    static func isSupported(fileExtension: String) -> Bool {
        return supportedExtensions.contains(fileExtension.lowercased())
    }

    /// Get supported file types as string
    static func getSupportedTypesString() -> String {
        return supportedExtensions.map { ".\($0)" }.joined(separator: ", ")
    }
}

// MARK: - Error Types

enum ImageImportError: LocalizedError {
    case invalidImage
    case fileNotFound
    case unsupportedFormat
    case fileTooLarge
    case readError

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The selected file is not a valid image"
        case .fileNotFound:
            return "The image file could not be found"
        case .unsupportedFormat:
            return "This image format is not supported"
        case .fileTooLarge:
            return "The image file is too large (max 50MB)"
        case .readError:
            return "Failed to read the image file"
        }
    }
}
