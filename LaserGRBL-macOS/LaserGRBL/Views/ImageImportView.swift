//
//  ImageImportView.swift
//  LaserGRBL
//
//  Created on October 11, 2025.
//  Phase 3: Image Import & Raster Conversion
//

import SwiftUI

struct ImageImportView: View {
    @ObservedObject var imageImporter: ImageImporter
    @ObservedObject var rasterConverter: RasterConverter
    @EnvironmentObject var fileManager: GCodeFileManager

    @State private var imageScale: CGFloat = 1.0
    @State private var showGrid = true
    @State private var previewMode: PreviewMode = .original
    @State private var showSuccessAlert = false
    @State private var showSettings = true
    
    private var settings: RasterSettings {
        imageImporter.rasterSettings
    }

    enum PreviewMode: String, CaseIterable {
        case original = "Original"
        case grayscale = "Grayscale"
        case processed = "Processed"
        case dithered = "Dithered"
    }

    var body: some View {
        HSplitView {
            // Main content area
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Toolbar
                    toolbar
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(nsColor: .windowBackgroundColor))

                    Divider()

                    // Main content
                    if let image = imageImporter.currentImage {
                        // Full-width preview
                        imagePreviewSection(image: image, geometry: geometry)
                    } else {
                        // Welcome/drop zone
                        emptyState
                    }

                    // Status bar
                    if let image = imageImporter.currentImage {
                        Divider()
                        statusBar(image: image)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(nsColor: .windowBackgroundColor))
                    }
                }
            }
            
            // Settings sidebar
            if showSettings, let image = imageImporter.currentImage {
                RasterSettingsView(settings: settings, image: image)
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
            }
        }
        .alert("Error", isPresented: $imageImporter.showError) {
            Button("OK") { imageImporter.showError = false }
        } message: {
            Text(imageImporter.errorMessage ?? "Unknown error")
        }
        .alert("G-Code Generated!", isPresented: $showSuccessAlert) {
            Button("OK") { }
        } message: {
            if let stats = rasterConverter.stats {
                Text("Successfully generated \(stats.totalCommands) G-code commands. Switch to the G-Code tab to view and export.")
            }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack {
            // Import button
            Button(action: {
                Task {
                    await imageImporter.importImage()
                }
            }) {
                Label("Import Image", systemImage: "photo")
            }
            .disabled(imageImporter.isLoading || rasterConverter.isConverting)

            if imageImporter.currentImage != nil {
                Button(action: { imageImporter.clearImage() }) {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(rasterConverter.isConverting)
            }

            Divider()
                .frame(height: 20)

            // Preview mode picker
            if imageImporter.currentImage != nil {
                Picker("Preview", selection: $previewMode) {
                    ForEach(PreviewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 320)
            }

            Spacer()

            // View controls
            if imageImporter.currentImage != nil {
                Toggle(isOn: $showGrid) {
                    Image(systemName: "grid")
                }
                .toggleStyle(.button)
                .help("Toggle Grid")

                Button(action: { imageScale = 1.0 }) {
                    Image(systemName: "1.magnifyingglass")
                }
                .help("Reset Zoom")

                Divider()
                    .frame(height: 20)

                Button {
                    withAnimation {
                        showSettings.toggle()
                    }
                } label: {
                    Label("Settings", systemImage: showSettings ? "sidebar.right" : "sidebar.left")
                }
                .help(showSettings ? "Hide Settings" : "Show Settings")
            }

            // Convert button
            if imageImporter.currentImage != nil {
                Button(action: convertToGCode) {
                    Label("Convert to G-Code", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(rasterConverter.isConverting)
            }
        }
    }

    // MARK: - Image Preview

    private func imagePreviewSection(image: RasterImage, geometry: GeometryProxy) -> some View {
        ZStack {
            Color(nsColor: .textBackgroundColor)

            if imageImporter.isLoading {
                ProgressView("Loading image...")
            } else if rasterConverter.isConverting {
                VStack(spacing: 16) {
                    ProgressView(value: rasterConverter.progress, total: 1.0)
                        .frame(width: 300)
                    Text("Converting to G-Code...")
                    Text("\(Int(rasterConverter.progress * 100))%")
                        .font(.headline)
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))
                .cornerRadius(8)
            } else {
                ScrollView([.horizontal, .vertical]) {
                    imageCanvas(image: image)
                        .scaleEffect(imageScale)
                }
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            imageScale = max(0.1, min(5.0, value))
                        }
                )
            }
        }
    }

    private func imageCanvas(image: RasterImage) -> some View {
        ZStack {
            // Checkerboard background for transparency
            checkerboardPattern()
                .frame(width: CGFloat(image.pixelWidth), height: CGFloat(image.pixelHeight))

            // Image
            if let displayImage = getDisplayImage(image: image) {
                Image(nsImage: displayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: CGFloat(image.pixelWidth), height: CGFloat(image.pixelHeight))
            }

            // Grid overlay
            if showGrid {
                gridOverlay(width: image.pixelWidth, height: image.pixelHeight)
            }

            // Dimensions overlay
            dimensionsOverlay(image: image)
        }
    }

    private func getDisplayImage(image: RasterImage) -> NSImage? {
        switch previewMode {
        case .original:
            return image.originalImage
        case .grayscale, .processed, .dithered:
            return image.processedImage ?? image.originalImage
        }
    }

    private func checkerboardPattern() -> some View {
        Canvas { context, size in
            let squareSize: CGFloat = 10
            let rows = Int(ceil(size.height / squareSize))
            let cols = Int(ceil(size.width / squareSize))

            for row in 0..<rows {
                for col in 0..<cols {
                    let isEven = (row + col) % 2 == 0
                    let rect = CGRect(
                        x: CGFloat(col) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )
                    context.fill(
                        Path(rect),
                        with: .color(isEven ? .white : Color.gray.opacity(0.2))
                    )
                }
            }
        }
    }

    private func gridOverlay(width: Int, height: Int) -> some View {
        Canvas { context, _ in
            let mmSize = 10.0 // 10mm grid
            let pixelsPerMM = settings.pixelsPerMM
            let gridSpacing = mmSize * pixelsPerMM

            context.stroke(
                Path { path in
                    // Vertical lines
                    var x: Double = 0
                    while x <= Double(width) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: Double(height)))
                        x += gridSpacing
                    }

                    // Horizontal lines
                    var y: Double = 0
                    while y <= Double(height) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: Double(width), y: y))
                        y += gridSpacing
                    }
                },
                with: .color(.blue.opacity(0.3)),
                lineWidth: 1
            )
        }
        .frame(width: CGFloat(width), height: CGFloat(height))
    }

    private func dimensionsOverlay(image: RasterImage) -> some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(image.pixelWidth) × \(image.pixelHeight) px")
                        .font(.caption)
                    Text(String(format: "%.1f × %.1f mm", image.physicalWidth, image.physicalHeight))
                        .font(.caption2)
                }
                .padding(8)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(6)

                Spacer()
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("Import Image for Raster Engraving")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Supported formats: \(ImageImporter.getSupportedTypesString())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(action: {
                Task {
                    await imageImporter.importImage()
                }
            }) {
                Label("Choose Image File", systemImage: "photo")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            VStack(alignment: .leading, spacing: 8) {
                Text("Features:")
                    .font(.caption)
                    .fontWeight(.semibold)

                featureRow(icon: "slider.horizontal.3", text: "Brightness, contrast, and gamma adjustments")
                featureRow(icon: "square.grid.3x3", text: "Multiple dithering algorithms")
                featureRow(icon: "arrow.left.and.right", text: "Bidirectional and zigzag scanning")
                featureRow(icon: "bolt", text: "Variable power and speed control")
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
        .frame(maxWidth: 500)
        .padding()
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Status Bar

    private func statusBar(image: RasterImage) -> some View {
        HStack {
            Label("\(image.fileName)", systemImage: "photo")
                .font(.caption)

            Divider()
                .frame(height: 12)

            Text(image.getFileSizeString())
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()
                .frame(height: 12)

            Text("Zoom: \(Int(imageScale * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if let stats = rasterConverter.stats {
                Text("\(stats.totalCommands) commands")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()
                    .frame(height: 12)

                Text(String(format: "%.1f mm", stats.totalDistance))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func convertToGCode() {
        guard let image = imageImporter.currentImage else { return }

        Task {
            do {
                // First convert image to grayscale if needed
                if image.processedImage == nil {
                    _ = try await image.convertToGrayscale()
                }

                // Apply adjustments
                _ = try await image.adjustBrightnessContrast(
                    brightness: settings.brightness,
                    contrast: settings.contrast
                )

                // Convert to G-code
                let gcodeFile = try await rasterConverter.convert(image: image, settings: settings)

                // Set filename based on original image
                gcodeFile.fileName = image.fileName.replacingOccurrences(of: ".", with: "_") + "_raster"

                // Load into file manager
                await MainActor.run {
                    fileManager.currentFile = gcodeFile
                    showSuccessAlert = true
                }

                print("Conversion complete! Generated \(gcodeFile.commands.count) commands")

            } catch {
                imageImporter.errorMessage = error.localizedDescription
                imageImporter.showError = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ImageImportView(
        imageImporter: ImageImporter(),
        rasterConverter: RasterConverter()
    )
    .environmentObject(GCodeFileManager())
    .frame(width: 1000, height: 700)
}
