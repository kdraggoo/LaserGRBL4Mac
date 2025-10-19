//
//  CustomButtonEditorView.swift
//  LaserGRBL for macOS
//
//  Editor for creating and managing custom buttons
//

import SwiftUI
import UniformTypeIdentifiers

struct CustomButtonEditorView: View {
    @ObservedObject var buttonManager: CustomButtonManager
    @ObservedObject var grblController: GrblController
    
    @State private var showingAddButton = false
    @State private var showingImport = false
    @State private var showingExport = false
    @State private var editingButton: CustomButton?
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbarView
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Button list
            if buttonManager.buttons.isEmpty {
                emptyStateView
            } else {
                buttonListView
            }
        }
        .sheet(item: $editingButton) { button in
            ButtonEditSheet(button: button, buttonManager: buttonManager)
        }
        .sheet(isPresented: $showingAddButton) {
            ButtonEditSheet(button: nil, buttonManager: buttonManager)
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
            document: CustomButtonsDocument(buttons: buttonManager.buttons),
            contentType: .json,
            defaultFilename: "custom-buttons.json"
        ) { _ in }
    }
    
    // MARK: - Toolbar
    
    private var toolbarView: some View {
        HStack {
            Text("Custom Buttons")
                .font(.headline)
            
            Spacer()
            
            Button(action: { showingAddButton = true }) {
                Label("Add Button", systemImage: "plus.circle")
            }
            .buttonStyle(.bordered)
            
            Menu {
                Button(action: { showingImport = true }) {
                    Label("Import...", systemImage: "square.and.arrow.down")
                }
                
                Button(action: { showingExport = true }) {
                    Label("Export...", systemImage: "square.and.arrow.up")
                }
                
                Divider()
                
                Button(action: { buttonManager.loadDefaults() }) {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Custom Buttons")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Add custom buttons to execute your own G-code commands")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingAddButton = true }) {
                Label("Add Your First Button", systemImage: "plus.circle")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Button List
    
    private var buttonListView: some View {
        List {
            ForEach(buttonManager.buttons.sorted { $0.order < $1.order }) { button in
                ButtonRow(button: button, onEdit: {
                    editingButton = button
                }, onDelete: {
                    buttonManager.removeButton(button)
                })
            }
            .onMove { source, destination in
                buttonManager.moveButton(from: source, to: destination)
            }
        }
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            _ = buttonManager.importFromFile(url: url)
        case .failure(let error):
            print("Import failed: \(error)")
        }
    }
}

// MARK: - Button Row

struct ButtonRow: View {
    let button: CustomButton
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: button.icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(button.label)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label(button.buttonType.rawValue, systemImage: typeIcon(for: button.buttonType))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(button.enableCondition.rawValue, systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 8)
    }
    
    private func typeIcon(for type: CustomButton.ButtonType) -> String {
        switch type {
        case .button: return "hand.tap"
        case .twoState: return "switch.2"
        case .push: return "hand.point.down"
        }
    }
}

// MARK: - Button Edit Sheet

struct ButtonEditSheet: View {
    let button: CustomButton?
    @ObservedObject var buttonManager: CustomButtonManager
    @Environment(\.dismiss) var dismiss
    
    @State private var label: String = ""
    @State private var gcode: String = ""
    @State private var gcode2: String = ""
    @State private var tooltip: String = ""
    @State private var icon: String = "command.square"
    @State private var buttonType: CustomButton.ButtonType = .button
    @State private var enableCondition: CustomButton.EnableCondition = .connected
    
    var body: some View {
        VStack(spacing: 16) {
            Text(button == nil ? "Add Custom Button" : "Edit Custom Button")
                .font(.title2)
                .bold()
            
            Form {
                TextField("Label", text: $label)
                    .help("Button label text")
                
                TextField("Tooltip", text: $tooltip)
                    .help("Help text shown on hover")
                
                Picker("Icon", selection: $icon) {
                    ForEach(iconOptions, id: \.self) { iconName in
                        Label(iconName, systemImage: iconName)
                            .tag(iconName)
                    }
                }
                .help("SF Symbol icon name")
                
                Picker("Button Type", selection: $buttonType) {
                    ForEach(CustomButton.ButtonType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .help(buttonType.description)
                
                Picker("Enable When", selection: $enableCondition) {
                    ForEach(CustomButton.EnableCondition.allCases, id: \.self) { condition in
                        Text(condition.rawValue).tag(condition)
                    }
                }
                .help(enableCondition.description)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("G-Code")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $gcode)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 100)
                        .border(Color.secondary.opacity(0.3))
                        .help("G-code to execute when button is clicked")
                }
                
                if buttonType == .twoState {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("G-Code (Off State)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $gcode2)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 100)
                            .border(Color.secondary.opacity(0.3))
                            .help("G-code to execute when toggling off")
                    }
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(button == nil ? "Add" : "Save") {
                    saveButton()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(label.isEmpty || gcode.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 600, height: 700)
        .onAppear {
            if let button = button {
                label = button.label
                gcode = button.gcode
                gcode2 = button.gcode2 ?? ""
                tooltip = button.tooltip
                icon = button.icon
                buttonType = button.buttonType
                enableCondition = button.enableCondition
            }
        }
    }
    
    private func saveButton() {
        let newButton = CustomButton(
            id: button?.id ?? UUID(),
            label: label,
            gcode: gcode,
            gcode2: buttonType == .twoState ? gcode2 : nil,
            tooltip: tooltip,
            icon: icon,
            buttonType: buttonType,
            enableCondition: enableCondition,
            order: button?.order ?? 0
        )
        
        if button == nil {
            buttonManager.addButton(newButton)
        } else {
            buttonManager.updateButton(newButton)
        }
    }
    
    private let iconOptions = [
        "command.square", "laser.burst", "house", "scope", "arrow.up", "arrow.down",
        "wind", "square.dashed", "flame", "snowflake", "bolt", "wrench", "hammer",
        "hand.tap", "target", "location", "paperplane", "cube", "circle.grid.cross"
    ]
}

// MARK: - Custom Buttons Document

struct CustomButtonsDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    let buttons: [CustomButton]
    
    init(buttons: [CustomButton]) {
        self.buttons = buttons
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        buttons = try decoder.decode([CustomButton].self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(buttons)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Preview

#Preview {
    let buttonManager = CustomButtonManager()
    let serialManager = SerialPortManager()
    let grblController = GrblController(serialManager: serialManager)
    
    return CustomButtonEditorView(buttonManager: buttonManager, grblController: grblController)
        .frame(width: 800, height: 600)
}

