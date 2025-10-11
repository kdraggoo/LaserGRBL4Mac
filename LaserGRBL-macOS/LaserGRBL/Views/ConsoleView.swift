//
//  ConsoleView.swift
//  LaserGRBL for macOS
//
//  Console log for GRBL communication
//

import SwiftUI

struct ConsoleView: View {
    @ObservedObject var grblController: GrblController
    
    @State private var filterType: FilterType = .all
    @State private var autoScroll: Bool = true
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case sent = "Sent"
        case received = "Received"
        case errors = "Errors"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .sent: return "arrow.up.circle"
            case .received: return "arrow.down.circle"
            case .errors: return "exclamationmark.triangle"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Image(systemName: "terminal")
                    .foregroundColor(.accentColor)
                
                Text("Console")
                    .font(.headline)
                
                Spacer()
                
                // Filter
                Picker("Filter", selection: $filterType) {
                    ForEach(FilterType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
                
                // Auto-scroll toggle
                Toggle(isOn: $autoScroll) {
                    Image(systemName: "arrow.down.to.line")
                }
                .toggleStyle(.button)
                .help("Auto-scroll")
                
                // Clear button
                Button(action: {
                    grblController.clearConsole()
                }) {
                    Image(systemName: "trash")
                }
                .help("Clear console")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Console log
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredEntries) { entry in
                            ConsoleEntryRow(entry: entry)
                                .id(entry.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: grblController.consoleLog.count) { _ in
                    if autoScroll, let lastEntry = filteredEntries.last {
                        withAnimation {
                            proxy.scrollTo(lastEntry.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Status bar
            HStack {
                Text("\(filteredEntries.count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if grblController.isConnected {
                    Label("Connected", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Label("Disconnected", systemImage: "circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
    
    private var filteredEntries: [GrblController.ConsoleEntry] {
        switch filterType {
        case .all:
            return grblController.consoleLog
        case .sent:
            return grblController.consoleLog.filter { $0.type == .sent }
        case .received:
            return grblController.consoleLog.filter { $0.type == .received }
        case .errors:
            return grblController.consoleLog.filter { $0.type == .error }
        }
    }
}

// MARK: - Console Entry Row

struct ConsoleEntryRow: View {
    let entry: GrblController.ConsoleEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Icon
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: 16)
                .font(.caption)
            
            // Timestamp
            Text(timeString)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            // Message
            Text(entry.message)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(messageColor)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
    
    private var iconName: String {
        switch entry.type {
        case .sent:
            return "arrow.up.circle.fill"
        case .received:
            return "arrow.down.circle.fill"
        case .status:
            return "info.circle"
        case .error:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle"
        }
    }
    
    private var iconColor: Color {
        switch entry.type {
        case .sent:
            return .blue
        case .received:
            return .green
        case .status:
            return .purple
        case .error:
            return .red
        case .info:
            return .secondary
        }
    }
    
    private var messageColor: Color {
        switch entry.type {
        case .error:
            return .red
        default:
            return .primary
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: entry.timestamp)
    }
}

#Preview {
    let serialManager = SerialPortManager()
    let grblController = GrblController(serialManager: serialManager)
    
    // Add some sample entries
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        grblController.consoleLog.append(contentsOf: [
            GrblController.ConsoleEntry(timestamp: Date(), message: "G21", type: .sent),
            GrblController.ConsoleEntry(timestamp: Date(), message: "ok", type: .received),
            GrblController.ConsoleEntry(timestamp: Date(), message: "G90", type: .sent),
            GrblController.ConsoleEntry(timestamp: Date(), message: "ok", type: .received),
            GrblController.ConsoleEntry(timestamp: Date(), message: "error:1", type: .error),
            GrblController.ConsoleEntry(timestamp: Date(), message: "<Idle|MPos:0.000,0.000,0.000|WPos:0.000,0.000,0.000>", type: .received),
        ])
    }
    
    return ConsoleView(grblController: grblController)
        .frame(width: 700, height: 400)
}

