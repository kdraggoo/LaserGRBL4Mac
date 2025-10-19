//
//  RasterSettingsView.swift
//  LaserGRBL
//
//  Created on October 11, 2025.
//  Phase 3: Image Import & Raster Conversion
//

import SwiftUI

struct RasterSettingsView: View {
    @ObservedObject var settings: RasterSettings
    let image: RasterImage

    @State private var selectedPreset: PresetType = .custom

    enum PresetType: String, CaseIterable {
        case custom = "Custom"
        case highQuality = "High Quality"
        case balanced = "Balanced"
        case highSpeed = "High Speed"
        case photo = "Photo"
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                // Conversion mode
                conversionModeSection

                Divider()

                // Preset selector
                presetSection

                Divider()

                // Dimensions
                dimensionsSection

                Divider()

                // Image adjustments
                imageAdjustmentsSection

                Divider()

                // Dithering
                ditheringSection

                Divider()

                // Laser settings
                laserSettingsSection

                Divider()

                // Speed settings
                speedSection

                Divider()

                // Direction
                directionSection

                Divider()

                // Advanced
                advancedSection

                // Bottom padding for scrolling
                Spacer()
                    .frame(height: 20)
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Conversion Mode Section

    private var conversionModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Conversion Mode")
                .font(.headline)

            Picker("Mode", selection: $settings.conversionMode) {
                ForEach(RasterSettings.ConversionMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .help("Line-to-Line: Fast horizontal scanning. Vectorize: Convert to vector paths (higher quality, slower).")

            Text(settings.conversionMode.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Preset Section

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preset")
                .font(.headline)

            Picker("Preset", selection: $selectedPreset) {
                ForEach(PresetType.allCases, id: \.self) { preset in
                    Text(preset.rawValue).tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedPreset) { _, newValue in
                applyPreset(newValue)
            }
        }
    }

    // MARK: - Dimensions Section

    private var dimensionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dimensions")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("Width (mm)")
                        .font(.caption)
                    TextField("Width", value: $settings.width, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: settings.width) { _, newValue in
                            if settings.lockAspectRatio {
                                settings.height = newValue / image.getAspectRatio()
                            }
                        }
                }

                Button(action: { settings.lockAspectRatio.toggle() }) {
                    Image(systemName: settings.lockAspectRatio ? "lock.fill" : "lock.open")
                }
                .buttonStyle(.borderless)
                .help("Lock Aspect Ratio")

                VStack(alignment: .leading) {
                    Text("Height (mm)")
                        .font(.caption)
                    TextField("Height", value: $settings.height, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: settings.height) { _, newValue in
                            if settings.lockAspectRatio {
                                settings.width = newValue * image.getAspectRatio()
                            }
                        }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("DPI")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.0f", settings.dpi))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.dpi, in: 50...1000, step: 1)
                    .help(HelpSystem.shared.tooltip(for: "raster.dpi"))
                Text("\(String(format: "%.3f", 25.4 / settings.dpi)) mm/pixel")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Line Interval (mm)")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.2f", settings.lineInterval))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.lineInterval, in: 0.01...1.0, step: 0.01)
                    .help(HelpSystem.shared.tooltip(for: "raster.lineInterval"))
            }
        }
    }

    // MARK: - Image Adjustments Section

    private var imageAdjustmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image Adjustments")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Brightness")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.2f", settings.brightness))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.brightness, in: -1.0...1.0, step: 0.05)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Contrast")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.2f", settings.contrast))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.contrast, in: 0.0...4.0, step: 0.1)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Gamma")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.2f", settings.gamma))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.gamma, in: 0.1...3.0, step: 0.1)
            }

            Toggle("Invert Image", isOn: $settings.invertImage)
                .font(.caption)
        }
    }

    // MARK: - Dithering Section

    private var ditheringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dithering")
                .font(.headline)

            Picker("Algorithm", selection: $settings.ditheringAlgorithm) {
                ForEach(RasterSettings.DitheringAlgorithm.allCases) { algorithm in
                    Text(algorithm.rawValue).tag(algorithm)
                }
            }
            .pickerStyle(.menu)
            .help(HelpSystem.shared.tooltip(for: "raster.dithering"))

            Text(settings.ditheringAlgorithm.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if settings.ditheringAlgorithm != .none {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Strength")
                            .font(.caption)
                        Spacer()
                        Text(String(format: "%.0f%%", settings.ditheringStrength * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.ditheringStrength, in: 0.0...1.0, step: 0.05)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Threshold")
                        .font(.caption)
                    Spacer()
                    Text("\(settings.threshold)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { Double(settings.threshold) },
                    set: { settings.threshold = Int($0) }
                ), in: 0...255, step: 1)
            }
        }
    }

    // MARK: - Laser Settings Section

    private var laserSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Laser Power")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("Min Power")
                        .font(.caption)
                    TextField("Min", value: $settings.minPower, format: .number)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading) {
                    Text("Max Power")
                        .font(.caption)
                    TextField("Max", value: $settings.maxPower, format: .number)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Toggle("Variable Power", isOn: $settings.useVariablePower)
                .font(.caption)
                .help("Adjust power based on pixel intensity")

            Toggle("Dynamic Power (M4)", isOn: $settings.useDynamicPower)
                .font(.caption)
                .help("Use M4 (dynamic) instead of M3 (constant)")
        }
    }

    // MARK: - Speed Section

    private var speedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Feed Rates")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Engraving Speed (mm/min)")
                        .font(.caption)
                    Spacer()
                    Text("\(settings.engravingSpeed)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { Double(settings.engravingSpeed) },
                    set: { settings.engravingSpeed = Int($0) }
                ), in: 100...5000, step: 100)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Travel Speed (mm/min)")
                        .font(.caption)
                    Spacer()
                    Text("\(settings.travelSpeed)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { Double(settings.travelSpeed) },
                    set: { settings.travelSpeed = Int($0) }
                ), in: 100...5000, step: 100)
            }
        }
    }

    // MARK: - Direction Section

    private var directionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Engraving Direction")
                .font(.headline)

            Picker("Direction", selection: $settings.engravingDirection) {
                ForEach(RasterSettings.EngravingDirection.allCases, id: \.self) { direction in
                    Text(direction.rawValue).tag(direction)
                }
            }
            .pickerStyle(.menu)

            Toggle("Reverse Direction", isOn: $settings.reverseDirection)
                .font(.caption)
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced")
                .font(.headline)

            Toggle("Skip White Pixels", isOn: $settings.skipWhitePixels)
                .font(.caption)
                .help("Optimize by skipping white areas")

            Toggle("Use Rapid Positioning (G0)", isOn: $settings.useRapidPositioning)
                .font(.caption)
                .help("Use G0 for fast moves between lines")

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Overscan (mm)")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.1f", settings.overscan))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.overscan, in: 0.0...10.0, step: 0.5)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Min Pixel Run")
                        .font(.caption)
                    Spacer()
                    Text("\(settings.minPixelRun)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { Double(settings.minPixelRun) },
                    set: { settings.minPixelRun = Int($0) }
                ), in: 1...20, step: 1)
            }

            Toggle("Include Header", isOn: $settings.includeHeader)
                .font(.caption)

            Toggle("Include Footer", isOn: $settings.includeFooter)
                .font(.caption)

            Toggle("Home After Completion", isOn: $settings.homeAfterCompletion)
                .font(.caption)
        }
    }

    // MARK: - Helper Methods

    private func applyPreset(_ preset: PresetType) {
        let newSettings: RasterSettings

        switch preset {
        case .custom:
            return // Don't override custom settings
        case .highQuality:
            newSettings = .highQuality
        case .balanced:
            newSettings = .default
        case .highSpeed:
            newSettings = .highSpeed
        case .photo:
            newSettings = .photo
        }

        // Apply preset values
        settings.dpi = newSettings.dpi
        settings.lineInterval = newSettings.lineInterval
        settings.ditheringAlgorithm = newSettings.ditheringAlgorithm
        settings.engravingSpeed = newSettings.engravingSpeed
        settings.useVariablePower = newSettings.useVariablePower
        settings.skipWhitePixels = newSettings.skipWhitePixels
    }
}

// MARK: - Settings Window Wrapper

struct RasterSettingsWindowView: View {
    @EnvironmentObject var imageImporter: ImageImporter
    @EnvironmentObject var rasterConverter: RasterConverter
    @EnvironmentObject var fileManager: GCodeFileManager
    
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom title bar
            HStack {
                Text("Raster Settings")
                    .font(.headline)
                    .padding(.leading, 12)
                Spacer()
            }
            .frame(height: 40)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Settings content
            if let image = imageImporter.currentImage {
                VStack(spacing: 0) {
                    RasterSettingsView(settings: imageImporter.rasterSettings, image: image)
                    
                    // Action buttons at bottom
                    Divider()
                    
                    actionButtons(image: image)
                }
            } else {
                // No image loaded state
                VStack(spacing: 16) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Image Loaded")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("Import an image in the Image tab to configure raster settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .controlBackgroundColor))
            }
        }
        .alert("G-Code Generated!", isPresented: $showSuccessAlert) {
            Button("OK") { }
        } message: {
            if let stats = rasterConverter.stats {
                Text("Successfully generated \(stats.totalCommands) G-code commands. Switch to the G-Code tab to view and export.")
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
    
    // MARK: - Action Buttons
    
    private func actionButtons(image: RasterImage) -> some View {
        HStack(spacing: 12) {
            if rasterConverter.isConverting {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Converting...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(rasterConverter.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: { convertToGCode(image: image) }) {
                Label(fileManager.currentFile?.fileName.contains("raster") == true ? "Update G-Code" : "Generate G-Code", 
                      systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderedProminent)
            .disabled(rasterConverter.isConverting)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Actions
    
    private func convertToGCode(image: RasterImage) {
        Task {
            do {
                // First convert image to grayscale if needed
                if image.processedImage == nil {
                    _ = try await image.convertToGrayscale()
                }

                // Apply adjustments
                _ = try await image.adjustBrightnessContrast(
                    brightness: imageImporter.rasterSettings.brightness,
                    contrast: imageImporter.rasterSettings.contrast
                )

                // Convert to G-code
                let gcodeFile = try await rasterConverter.convert(
                    image: image, 
                    settings: imageImporter.rasterSettings
                )

                // Set filename based on original image
                gcodeFile.fileName = image.fileName.replacingOccurrences(of: ".", with: "_") + "_raster"

                // Load into file manager
                await MainActor.run {
                    fileManager.currentFile = gcodeFile
                    showSuccessAlert = true
                }

                print("Conversion complete! Generated \(gcodeFile.commands.count) commands")

            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RasterSettingsView(
        settings: RasterSettings.default,
        image: RasterImage(
            image: NSImage(systemSymbolName: "photo", accessibilityDescription: nil)!,
            fileName: "test.png",
            fileSize: 1024
        )
    )
    .frame(width: 320, height: 700)
}
