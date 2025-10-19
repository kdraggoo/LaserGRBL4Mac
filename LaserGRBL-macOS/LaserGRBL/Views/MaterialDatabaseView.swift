//
//  MaterialDatabaseView.swift
//  LaserGRBL for macOS
//
//  Material database and power-speed helper
//

import SwiftUI
import UniformTypeIdentifiers

struct MaterialDatabaseView: View {
    @ObservedObject var database: MaterialDatabase
    
    @State private var selectedModel: String = "Generic"
    @State private var selectedMaterial: String = ""
    @State private var selectedThickness: Double = 3.0
    @State private var selectedAction: String = ""
    @State private var searchText: String = ""
    @State private var showingAddPreset = false
    @State private var showingImport = false
    @State private var showingExport = false
    @State private var selectedPreset: MaterialPreset?
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - Filters
            sidebarView
                .frame(minWidth: 250, idealWidth: 280)
        } detail: {
            // Main content - Preset list
            VStack(spacing: 0) {
                // Toolbar
                toolbarView
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Preset list
                presetListView
            }
        }
        .sheet(isPresented: $showingAddPreset) {
            AddPresetSheet(database: database)
        }
        .fileImporter(
            isPresented: $showingImport,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .fileExporter(
            isPresented: $showingExport,
            document: MaterialPresetsDocument(presets: database.presets),
            contentType: .json,
            defaultFilename: "material-presets.json"
        ) { result in
            // Handle export result
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebarView: some View {
        List {
            Section("Laser Model") {
                Picker("Model", selection: $selectedModel) {
                    ForEach(database.laserModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            
            Section("Material") {
                ForEach(database.materials, id: \.self) { material in
                    Button(action: {
                        selectedMaterial = material
                        // Auto-select first thickness
                        if let firstThickness = database.thicknesses(for: material).first {
                            selectedThickness = firstThickness
                            // Auto-select first action
                            if let firstAction = database.actions(for: material, thickness: firstThickness).first {
                                selectedAction = firstAction
                            }
                        }
                    }) {
                        HStack {
                            Text(material)
                            Spacer()
                            if selectedMaterial == material {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                }
            }
            
            if !selectedMaterial.isEmpty {
                Section("Thickness") {
                    ForEach(database.thicknesses(for: selectedMaterial), id: \.self) { thickness in
                        Button(action: {
                            selectedThickness = thickness
                            // Auto-select first action
                            if let firstAction = database.actions(for: selectedMaterial, thickness: thickness).first {
                                selectedAction = firstAction
                            }
                        }) {
                            HStack {
                                Text(String(format: "%.1f mm", thickness))
                                Spacer()
                                if abs(selectedThickness - thickness) < 0.1 {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Action") {
                    ForEach(database.actions(for: selectedMaterial, thickness: selectedThickness), id: \.self) { action in
                        Button(action: {
                            selectedAction = action
                        }) {
                            HStack {
                                Text(action)
                                Spacer()
                                if selectedAction == action {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Material Database")
    }
    
    // MARK: - Toolbar
    
    private var toolbarView: some View {
        HStack(spacing: 12) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search materials...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(6)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            
            Spacer()
            
            Button(action: { showingAddPreset = true }) {
                Label("Add Preset", systemImage: "plus.circle")
            }
            .buttonStyle(.bordered)
            .help("Add custom material preset")
            
            Menu {
                Button(action: { showingImport = true }) {
                    Label("Import Presets...", systemImage: "square.and.arrow.down")
                }
                
                Button(action: { showingExport = true }) {
                    Label("Export Presets...", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .help("Import/Export presets")
        }
    }
    
    // MARK: - Preset List
    
    private var presetListView: some View {
        ScrollView {
            LazyVStack(spacing: 12, pinnedViews: []) {
                if filteredPresets.isEmpty {
                    Text("No presets found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else {
                    ForEach(filteredPresets) { preset in
                        PresetCard(
                            preset: preset,
                            onApply: {
                                applyPreset(preset)
                            },
                            onDelete: preset.isCustom ? {
                                database.removePreset(preset)
                            } : nil
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredPresets: [MaterialPreset] {
        var filtered = database.filterBy(
            model: selectedModel,
            material: selectedMaterial.isEmpty ? nil : selectedMaterial,
            thickness: selectedMaterial.isEmpty ? nil : selectedThickness,
            action: selectedAction.isEmpty ? nil : selectedAction
        )
        
        if !searchText.isEmpty {
            let lowercaseSearch = searchText.lowercased()
            filtered = filtered.filter {
                $0.material.lowercased().contains(lowercaseSearch) ||
                $0.action.lowercased().contains(lowercaseSearch) ||
                $0.remarks.lowercased().contains(lowercaseSearch)
            }
        }
        
        return filtered
    }
    
    // MARK: - Helper Methods
    
    private func applyPreset(_ preset: MaterialPreset) {
        // This would apply settings to current raster/vector settings
        // For now, just show a notification
        print("Applied preset: \(preset.displayName)")
        print("Power: \(preset.power)%, Speed: \(preset.speed) mm/min, Passes: \(preset.passes)")
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            _ = database.importFromFile(url: url)
        case .failure(let error):
            print("Import failed: \(error)")
        }
    }
}

// MARK: - Preset Card

struct PresetCard: View {
    let preset: MaterialPreset
    let onApply: () -> Void
    let onDelete: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Material info
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.material)
                        .font(.headline)
                    Text("\(String(format: "%.1fmm", preset.thickness)) - \(preset.action)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if !preset.laserModel.isEmpty && preset.laserModel != "Generic" {
                        Text(preset.laserModel)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Settings display
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Power")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(preset.power)%")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Speed")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(preset.speed)")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Passes")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(preset.passes)")
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                }
            }
            
            if !preset.remarks.isEmpty {
                Text(preset.remarks)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Actions
            HStack {
                if preset.isCustom {
                    Label("Custom", systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                
                Spacer()
                
                Button(action: onApply) {
                    Label("Apply to Job", systemImage: "checkmark.circle")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                if let onDelete = onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - Add Preset Sheet

struct AddPresetSheet: View {
    @ObservedObject var database: MaterialDatabase
    @Environment(\.dismiss) var dismiss
    
    @State private var laserModel: String = "Generic"
    @State private var material: String = ""
    @State private var thickness: Double = 3.0
    @State private var action: String = "Cut"
    @State private var power: Int = 50
    @State private var speed: Int = 1000
    @State private var passes: Int = 1
    @State private var remarks: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add Custom Preset")
                .font(.title2)
                .bold()
            
            Form {
                TextField("Material", text: $material)
                    .help("Material name (e.g., Wood, Acrylic)")
                
                TextField("Thickness (mm)", value: $thickness, format: .number)
                
                Picker("Action", selection: $action) {
                    Text("Cut").tag("Cut")
                    Text("Engrave").tag("Engrave")
                    Text("Score").tag("Score")
                }
                
                TextField("Laser Model", text: $laserModel)
                    .help("Your laser model or 'Generic'")
                
                TextField("Power (%)", value: $power, format: .number)
                TextField("Speed (mm/min)", value: $speed, format: .number)
                TextField("Passes", value: $passes, format: .number)
                
                TextField("Remarks (optional)", text: $remarks)
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add") {
                    let preset = MaterialPreset(
                        laserModel: laserModel,
                        material: material,
                        thickness: thickness,
                        action: action,
                        power: power,
                        speed: speed,
                        passes: passes,
                        remarks: remarks,
                        isCustom: true
                    )
                    database.addPreset(preset)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(material.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 500, height: 600)
    }
}

// MARK: - Document for Export

struct MaterialPresetsDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    let presets: [MaterialPreset]
    
    init(presets: [MaterialPreset]) {
        self.presets = presets
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        presets = try decoder.decode([MaterialPreset].self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(presets)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Preview

#Preview {
    let database = MaterialDatabase()
    return MaterialDatabaseView(database: database)
        .frame(width: 1000, height: 700)
}

