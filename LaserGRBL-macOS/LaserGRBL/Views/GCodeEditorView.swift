//
//  GCodeEditorView.swift
//  LaserGRBL for macOS
//
//  G-code list and text editor view
//

import SwiftUI

struct GCodeEditorView: View {
    @ObservedObject var file: GCodeFile
    @Binding var selectedCommandId: UUID?
    @State private var editMode: EditMode = .list
    @State private var editingText: String = ""

    enum EditMode {
        case list
        case text
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("G-Code")
                    .font(.headline)

                Spacer()

                Picker("View Mode", selection: $editMode) {
                    Label("List", systemImage: "list.bullet").tag(EditMode.list)
                    Label("Text", systemImage: "doc.text").tag(EditMode.text)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Content
            if editMode == .list {
                GCodeListView(
                    commands: file.commands,
                    selectedCommandId: $selectedCommandId
                )
            } else {
                GCodeTextEditor(
                    text: $editingText,
                    onSave: {
                        file.updateFromText(editingText)
                    }
                )
                .onAppear {
                    editingText = file.asText
                }
            }
        }
    }
}

// MARK: - List View

struct GCodeListView: View {
    let commands: [GCodeCommand]
    @Binding var selectedCommandId: UUID?

    var body: some View {
        List(commands, id: \.id, selection: $selectedCommandId) { command in
            GCodeCommandRow(command: command)
                .tag(command.id)
        }
        .listStyle(.bordered)
    }
}

struct GCodeCommandRow: View {
    let command: GCodeCommand

    var body: some View {
        HStack(spacing: 12) {
            // Line number
            if let lineNum = command.lineNumber {
                Text("\(lineNum)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }

            // Command icon
            Image(systemName: commandIcon)
                .foregroundColor(commandColor)
                .frame(width: 20)

            // Command description
            VStack(alignment: .leading, spacing: 2) {
                Text(command.displayDescription)
                    .font(.system(.body, design: .monospaced))

                if !command.parameters.isEmpty {
                    Text(command.parameters.map { $0.formatted }.joined(separator: " "))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var commandIcon: String {
        switch command.command {
        case .motion(.rapid):
            return "arrow.right"
        case .motion(.linear):
            return "arrow.forward"
        case .motion(.arcCW), .motion(.arcCCW):
            return "arrow.circlepath"
        case .laser(.on), .laser(.onDynamic):
            return "bolt.fill"
        case .laser(.off):
            return "bolt"
        case .coordinate:
            return "scope"
        case .units:
            return "ruler"
        case .feedRate:
            return "speedometer"
        case .dwell:
            return "clock"
        case .comment:
            return "text.bubble"
        default:
            return "command"
        }
    }

    private var commandColor: Color {
        switch command.command {
        case .motion:
            return .blue
        case .laser(.on), .laser(.onDynamic):
            return .red
        case .laser(.off):
            return .green
        case .comment:
            return .secondary
        default:
            return .primary
        }
    }
}

// MARK: - Text Editor

struct GCodeTextEditor: View {
    @Binding var text: String
    let onSave: () -> Void
    @State private var isModified = false

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .onChange(of: text) { _ in
                    isModified = true
                }

            if isModified {
                HStack {
                    Text("Modified")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Spacer()

                    Button("Apply Changes") {
                        onSave()
                        isModified = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
    }
}

#Preview {
    let file = GCodeFile()
    file.commands = [
        GCodeCommand(rawLine: "G21", lineNumber: 1),
        GCodeCommand(rawLine: "G90", lineNumber: 2),
        GCodeCommand(rawLine: "M5", lineNumber: 3),
        GCodeCommand(rawLine: "G0 X0 Y0", lineNumber: 4),
        GCodeCommand(rawLine: "M3 S500", lineNumber: 5),
        GCodeCommand(rawLine: "G1 X10 Y10 F1000", lineNumber: 6)
    ]

    return GCodeEditorView(file: file, selectedCommandId: .constant(nil))
        .frame(width: 400, height: 600)
}
