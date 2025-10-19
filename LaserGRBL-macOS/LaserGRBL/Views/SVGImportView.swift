//
//  SVGImportView.swift
//  LaserGRBL
//
//  Phase 4: SVG Vector Import
//  Created on October 19, 2025
//

import SwiftUI
import UniformTypeIdentifiers

/// Main view for SVG import and conversion
struct SVGImportView: View {
    @EnvironmentObject var svgImporter: SVGImporter
    @EnvironmentObject var converter: PathToGCodeConverter
    @EnvironmentObject var fileManager: GCodeFileManager
    
    @StateObject private var settings = VectorSettings()
    @State private var showingSettings = true
    @State private var convertedGCode: String?
    @State private var showingExportSheet = false
    @State private var conversionError: Error?
    
    var body: some View {
        HSplitView {
            // Main content area
            VStack(spacing: 0) {
                // Toolbar
                toolbar
                
                Divider()
                
                // Preview or welcome
                if svgImporter.currentDocument != nil {
                    VectorPreviewCanvas()
                        .environmentObject(svgImporter)
                } else {
                    welcomeView
                }
                
                // Status bar
                if let document = svgImporter.currentDocument {
                    statusBar(for: document)
                }
            }
            
            // Settings sidebar
            if showingSettings {
                VectorSettingsView(settings: settings)
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
            }
        }
        .navigationTitle("Vector Import")
        .alert("Conversion Error", isPresented: .constant(conversionError != nil), presenting: conversionError) { _ in
            Button("OK") { conversionError = nil }
        } message: { error in
            Text(error.localizedDescription)
        }
        .sheet(isPresented: $showingExportSheet) {
            if let gcode = convertedGCode {
                ExportSheet(gcode: gcode, settings: settings)
            }
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            // Import button
            Button {
                Task {
                    await svgImporter.importSVG()
                }
            } label: {
                Label("Import SVG", systemImage: "doc.badge.plus")
            }
            .keyboardShortcut("i", modifiers: .command)
            .disabled(svgImporter.isLoading)
            
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
            .disabled(svgImporter.currentDocument == nil || converter.isConverting)
            
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
            if svgImporter.isLoading || converter.isConverting {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Welcome View
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.viewfinder")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Import SVG File")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Import vector graphics from Illustrator, Inkscape, or Figma")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "checkmark.circle", text: "All standard SVG shapes")
                FeatureRow(icon: "checkmark.circle", text: "Bézier curve conversion")
                FeatureRow(icon: "checkmark.circle", text: "Path optimization")
                FeatureRow(icon: "checkmark.circle", text: "Multi-pass support")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Button {
                Task {
                    await svgImporter.importSVG()
                }
            } label: {
                Label("Import SVG File", systemImage: "doc.badge.plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Status Bar
    
    private func statusBar(for document: SVGDocument) -> some View {
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
            
            Spacer()
            
            // Conversion status
            if converter.isConverting {
                HStack(spacing: 6) {
                    ProgressView(value: converter.progress)
                        .frame(width: 100)
                    Text(converter.currentOperation)
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
    
    // MARK: - Conversion
    
    private func convertToGCode() async {
        guard let document = svgImporter.currentDocument else { return }
        
        do {
            let gcode = try await converter.convert(
                document: document,
                settings: settings
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
    
    @State private var fileName = "vector_output"
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
    SVGImportView()
        .environmentObject(SVGImporter())
        .environmentObject(PathToGCodeConverter())
        .environmentObject(GCodeFileManager())
        .frame(width: 1000, height: 700)
}

