//
//  UnifiedImportView.swift
//  LaserGRBL for macOS
//
//  Unified import workflow for both SVG and image files
//  Created on October 19, 2025
//

import SwiftUI
import UniformTypeIdentifiers

/// Unified import view that handles both SVG and image files
struct UnifiedImportView: View {
    @EnvironmentObject var svgImporter: SVGImporter
    @EnvironmentObject var imageImporter: ImageImporter
    @EnvironmentObject var rasterConverter: RasterConverter
    @EnvironmentObject var pathConverter: PathToGCodeConverter
    @EnvironmentObject var fileManager: GCodeFileManager
    
    @StateObject private var vectorSettings = VectorSettings()
    @State private var showingSettings = true
    @State private var convertedGCode: String?
    @State private var showingExportSheet = false
    @State private var conversionError: Error?
    
    // File type detection
    @State private var currentFileType: FileType = .none
    
    enum FileType {
        case none
        case svg
        case image
    }
    
    var body: some View {
        HSplitView {
            // Main content area
            VStack(spacing: 0) {
                // Toolbar
                toolbar
                
                Divider()
                
                // Preview or welcome
                previewContent
                
                // Status bar
                statusBar
            }
            
            // Settings sidebar
            if showingSettings {
                settingsPanel
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
            }
        }
        .navigationTitle("Import")
        .alert("Conversion Error", isPresented: .constant(conversionError != nil), presenting: conversionError) { _ in
            Button("OK") { conversionError = nil }
        } message: { error in
            Text(error.localizedDescription)
        }
        .sheet(isPresented: $showingExportSheet) {
            if let gcode = convertedGCode {
                ExportSheet(gcode: gcode, settings: vectorSettings)
            }
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            // Import buttons
            HStack(spacing: 8) {
                Button {
                    Task {
                        await importSVG()
                    }
                } label: {
                    Label("Import SVG", systemImage: "square.on.circle")
                }
                .keyboardShortcut("v", modifiers: .command)
                .disabled(svgImporter.isLoading)
                
                Button {
                    Task {
                        await importImage()
                    }
                } label: {
                    Label("Import Image", systemImage: "photo")
                }
                .keyboardShortcut("i", modifiers: .command)
                .disabled(imageImporter.isLoading)
            }
            
            Divider()
                .frame(height: 20)
            
            // Convert button
            Button {
                Task {
                    await convertToGCode()
                }
            } label: {
                Label("Convert to G-Code", systemImage: "arrow.right.circle")
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])
            .disabled(!canConvert)
            
            // Export button
            Button {
                showingExportSheet = true
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .keyboardShortcut("e", modifiers: .command)
            .disabled(convertedGCode == nil)
            
            Spacer()
            
            // Settings toggle
            Button {
                withAnimation {
                    showingSettings.toggle()
                }
            } label: {
                Label("Settings", systemImage: showingSettings ? "sidebar.right" : "sidebar.left")
            }
            .help(showingSettings ? "Hide Settings" : "Show Settings")
            
            // Progress indicator
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Preview Content
    
    private var previewContent: some View {
        Group {
            switch currentFileType {
            case .svg:
                if svgImporter.currentDocument != nil {
                    VectorPreviewCanvas()
                        .environmentObject(svgImporter)
                } else {
                    welcomeView
                }
            case .image:
                if imageImporter.currentImage != nil {
                    imagePreviewSection
                } else {
                    welcomeView
                }
            case .none:
                welcomeView
            }
        }
    }
    
    // MARK: - Welcome View
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.viewfinder")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Import Files")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Import SVG files for vector cutting or images for raster engraving")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "square.on.circle", text: "SVG vector cutting with arc commands")
                FeatureRow(icon: "photo", text: "Image raster engraving with dithering")
                FeatureRow(icon: "slider.horizontal.3", text: "Unified settings and preview")
                FeatureRow(icon: "arrow.right.circle", text: "Optimized G-code generation")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            HStack(spacing: 16) {
                Button {
                    Task {
                        await importSVG()
                    }
                } label: {
                    Label("Import SVG", systemImage: "square.on.circle")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button {
                    Task {
                        await importImage()
                    }
                } label: {
                    Label("Import Image", systemImage: "photo")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Image Preview Section
    
    private var imagePreviewSection: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Image preview with zoom/pan controls
                if let image = imageImporter.currentImage {
                    Image(nsImage: image.originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(NSColor.controlBackgroundColor))
                }
            }
        }
    }
    
    // MARK: - Settings Panel
    
    private var settingsPanel: some View {
        Group {
            switch currentFileType {
            case .svg:
                VectorSettingsView(settings: vectorSettings)
            case .image:
                RasterSettingsView(settings: imageImporter.rasterSettings, image: imageImporter.currentImage!)
            case .none:
                VStack {
                    Text("No file loaded")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    // MARK: - Status Bar
    
    private var statusBar: some View {
        HStack(spacing: 16) {
            switch currentFileType {
            case .svg:
                if let document = svgImporter.currentDocument {
                    statusBarForSVG(document: document)
                }
            case .image:
                if let image = imageImporter.currentImage {
                    statusBarForImage(image: image)
                }
            case .none:
                Text("No file loaded")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Conversion status
            if isConverting {
                HStack(spacing: 6) {
                    ProgressView(value: conversionProgress)
                        .frame(width: 100)
                    Text(currentOperation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if convertedGCode != nil {
                Label("G-Code Ready", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func statusBarForSVG(document: SVGDocument) -> some View {
        HStack(spacing: 16) {
            // File name
            if let url = document.url {
                Label(url.lastPathComponent, systemImage: "doc")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 12)
            
            // Path count
            Label("\(document.visiblePathCount) paths", systemImage: "square.on.square")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
                .frame(height: 12)
            
            // Dimensions
            let bounds = document.boundingBox
            Text(String(format: "%.1f × %.1f mm", bounds.width, bounds.height))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func statusBarForImage(image: RasterImage) -> some View {
        HStack(spacing: 16) {
            // File name
            Label(image.fileName, systemImage: "photo")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
                .frame(height: 12)
            
            // Image dimensions
            Text(String(format: "%d × %d px", image.pixelWidth, image.pixelHeight))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
                .frame(height: 12)
            
            // File size
            Text(formatBytes(Int(image.fileSize)))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Actions
    
    private func importSVG() async {
        await svgImporter.importSVG()
        if svgImporter.currentDocument != nil {
            currentFileType = .svg
        }
    }
    
    private func importImage() async {
        await imageImporter.importImage()
        if imageImporter.currentImage != nil {
            currentFileType = .image
        }
    }
    
    private func convertToGCode() async {
        switch currentFileType {
        case .svg:
            await convertSVGToGCode()
        case .image:
            await convertImageToGCode()
        case .none:
            break
        }
    }
    
    private func convertSVGToGCode() async {
        guard let document = svgImporter.currentDocument else { return }
        
        do {
            let gcode = try await pathConverter.convert(
                document: document,
                settings: vectorSettings
            )
            
            await MainActor.run {
                self.convertedGCode = gcode
            }
        } catch {
            await MainActor.run {
                self.conversionError = error
            }
        }
    }
    
    private func convertImageToGCode() async {
        guard let image = imageImporter.currentImage else { return }
        
        do {
            let gcodeFile = try await rasterConverter.convert(
                image: image,
                settings: imageImporter.rasterSettings
            )
            
            await MainActor.run {
                // Convert GCodeFile to string
                self.convertedGCode = gcodeFile.commands.map { $0.rawLine }.joined(separator: "\n")
            }
        } catch {
            await MainActor.run {
                self.conversionError = error
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canConvert: Bool {
        switch currentFileType {
        case .svg:
            return svgImporter.currentDocument != nil && !pathConverter.isConverting
        case .image:
            return imageImporter.currentImage != nil && !rasterConverter.isConverting
        case .none:
            return false
        }
    }
    
    private var isLoading: Bool {
        svgImporter.isLoading || imageImporter.isLoading
    }
    
    private var isConverting: Bool {
        pathConverter.isConverting || rasterConverter.isConverting
    }
    
    private var conversionProgress: Double {
        if pathConverter.isConverting {
            return pathConverter.progress
        } else if rasterConverter.isConverting {
            return rasterConverter.progress
        }
        return 0
    }
    
    private var currentOperation: String {
        if pathConverter.isConverting {
            return pathConverter.currentOperation
        } else if rasterConverter.isConverting {
            return "Converting image to G-code..."
        }
        return ""
    }
    
    // MARK: - Helper Functions
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Export Sheet

private struct ExportSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var fileManager: GCodeFileManager
    
    let gcode: String
    let settings: VectorSettings
    
    @State private var fileName = "unified_output"
    @State private var includeComments = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export G-Code")
                .font(.title2)
                .fontWeight(.semibold)
            
            Form {
                TextField("File Name:", text: $fileName)
                
                Toggle("Include Comments", isOn: $includeComments)
                
                HStack {
                    Text("Lines:")
                    Spacer()
                    Text("\(gcode.components(separatedBy: .newlines).count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Size:")
                    Spacer()
                    Text(formatBytes(gcode.utf8.count))
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save to File") {
                    saveToFile()
                }
                .keyboardShortcut(.defaultAction)
                
                Button("Load in Editor") {
                    loadInEditor()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400)
    }
    
    private func saveToFile() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = fileName + ".gcode"
        panel.allowedContentTypes = [.init(filenameExtension: "gcode")!]
        
        if panel.runModal() == .OK, let url = panel.url {
            try? gcode.write(to: url, atomically: true, encoding: .utf8)
            dismiss()
        }
    }
    
    private func loadInEditor() {
        Task {
            do {
                let file = GCodeFile()
                try await file.loadFromText(gcode)
                await MainActor.run {
                    fileManager.currentFile = file
                    dismiss()
                }
            } catch {
                print("Error loading G-code: \(error)")
            }
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Preview

#Preview {
    UnifiedImportView()
        .environmentObject(SVGImporter())
        .environmentObject(ImageImporter())
        .environmentObject(RasterConverter())
        .environmentObject(PathToGCodeConverter())
        .environmentObject(GCodeFileManager())
        .frame(width: 1000, height: 700)
}
