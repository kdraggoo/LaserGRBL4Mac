//
//  GrblSettingsView.swift
//  LaserGRBL for macOS
//
//  GRBL configuration settings editor
//

import SwiftUI
import UniformTypeIdentifiers

struct GrblSettingsView: View {
    @ObservedObject var grblController: GrblController
    @ObservedObject var settingsManager: GrblSettingsManager
    
    @State private var searchText: String = ""
    @State private var selectedCategory: SettingCategory? = .stepper
    @State private var showingImportPicker = false
    @State private var showingExportPicker = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationSplitView {
            // Category sidebar
            categorySidebarView
                .frame(minWidth: 200, idealWidth: 220)
        } detail: {
            // Settings detail view
            VStack(spacing: 0) {
                // Toolbar
                toolbarView
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Settings list
                if settingsManager.isLoading {
                    ProgressView("Reading settings from controller...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    settingsListView
                }
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .fileExporter(
            isPresented: $showingExportPicker,
            document: SettingsDocument(settings: settingsManager.settings),
            contentType: .json,
            defaultFilename: "grbl-settings.json"
        ) { result in
            if case .failure(let error) = result {
                settingsManager.errorMessage = error.localizedDescription
            }
        }
        .alert("Reset to Defaults?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                settingsManager.resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values. You will need to write them to the controller.")
        }
        .alert("Error", isPresented: .constant(settingsManager.errorMessage != nil)) {
            Button("OK") {
                settingsManager.errorMessage = nil
            }
        } message: {
            Text(settingsManager.errorMessage ?? "")
        }
    }
    
    // MARK: - Category Sidebar
    
    private var categorySidebarView: some View {
        List(selection: $selectedCategory) {
            Section("Categories") {
                ForEach(SettingCategory.allCases, id: \.self) { category in
                    NavigationLink(value: category) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.rawValue)
                                .font(.headline)
                            Text("\(settingCount(for: category)) settings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("GRBL Settings")
    }
    
    // MARK: - Toolbar
    
    private var toolbarView: some View {
        HStack(spacing: 12) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search settings...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            
            Spacer()
            
            // Action buttons
            Button(action: {
                grblController.readSettings()
            }) {
                Label("Read from Controller", systemImage: "arrow.down.circle")
            }
            .buttonStyle(.bordered)
            .disabled(!grblController.isConnected)
            .help("Read all settings from GRBL controller")
            
            Button(action: {
                grblController.writeAllSettings(settingsManager.settings)
            }) {
                Label("Write All", systemImage: "arrow.up.circle")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!grblController.isConnected)
            .help("Write all settings to GRBL controller")
            
            Menu {
                Button(action: { showingImportPicker = true }) {
                    Label("Import from File...", systemImage: "square.and.arrow.down")
                }
                
                Button(action: { showingExportPicker = true }) {
                    Label("Export to File...", systemImage: "square.and.arrow.up")
                }
                
                Divider()
                
                Button(role: .destructive, action: { showingResetAlert = true }) {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .help("More options")
        }
    }
    
    // MARK: - Settings List
    
    private var settingsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                if let category = selectedCategory {
                    let settings = filteredSettings(for: category)
                    
                    if settings.isEmpty {
                        Text("No settings found")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                    } else {
                        ForEach(settings) { setting in
                            SettingRow(
                                setting: setting,
                                onValueChanged: { newValue in
                                    settingsManager.updateSetting(id: setting.id, value: newValue)
                                },
                                onWrite: {
                                    grblController.writeSetting(id: setting.id, value: setting.value)
                                },
                                isConnected: grblController.isConnected
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func settingCount(for category: SettingCategory) -> Int {
        settingsManager.settings.filter { $0.category == category }.count
    }
    
    private func filteredSettings(for category: SettingCategory) -> [GrblSetting] {
        let categorySettings = settingsManager.settings.filter { $0.category == category }
        
        if searchText.isEmpty {
            return categorySettings.sorted { $0.id < $1.id }
        }
        
        let lowercaseSearch = searchText.lowercased()
        return categorySettings.filter {
            $0.name.lowercased().contains(lowercaseSearch) ||
            $0.description.lowercased().contains(lowercaseSearch) ||
            "\($0.id)".contains(lowercaseSearch)
        }.sorted { $0.id < $1.id }
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let data = try Data(contentsOf: url)
                if settingsManager.importFromJSON(data: data) {
                    // Success
                } else {
                    settingsManager.errorMessage = "Invalid settings file format"
                }
            } catch {
                settingsManager.errorMessage = error.localizedDescription
            }
        case .failure(let error):
            settingsManager.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Setting Row

struct SettingRow: View {
    let setting: GrblSetting
    let onValueChanged: (Double) -> Void
    let onWrite: () -> Void
    let isConnected: Bool
    
    @State private var editedValue: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Setting name and ID
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("$\(setting.id)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Text(setting.name)
                            .font(.headline)
                    }
                    
                    Text(setting.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Value editor
                HStack(spacing: 8) {
                    if isEditing {
                        TextField("Value", text: $editedValue)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .onSubmit {
                                saveEdit()
                            }
                        
                        Button("Save") {
                            saveEdit()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Cancel") {
                            isEditing = false
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Text(setting.displayValue)
                            .font(.system(.body, design: .monospaced))
                            .frame(minWidth: 100, alignment: .trailing)
                        
                        Button(action: {
                            editedValue = String(format: "%.3f", setting.value)
                            isEditing = true
                        }) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)
                        .help("Edit value")
                        
                        Button(action: onWrite) {
                            Image(systemName: "arrow.up.circle")
                        }
                        .buttonStyle(.borderless)
                        .disabled(!isConnected)
                        .help("Write this setting to controller")
                    }
                }
            }
            
            // Tooltip
            Text(setting.tooltip)
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            
            // Range indicator
            if let range = setting.range {
                HStack {
                    Text("Range:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", range.lowerBound)) - \(String(format: "%.1f", range.upperBound))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func saveEdit() {
        if let newValue = Double(editedValue) {
            onValueChanged(newValue)
        }
        isEditing = false
    }
}

// MARK: - Settings Document for Export

struct SettingsDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    let settings: [GrblSetting]
    
    init(settings: [GrblSetting]) {
        self.settings = settings
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        settings = try decoder.decode([GrblSetting].self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(settings)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Preview

#Preview {
    let serialManager = SerialPortManager()
    let grblController = GrblController(serialManager: serialManager)
    let settingsManager = GrblSettingsManager()
    
    return GrblSettingsView(grblController: grblController, settingsManager: settingsManager)
        .frame(width: 900, height: 600)
}

