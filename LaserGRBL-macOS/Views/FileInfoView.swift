//
//  FileInfoView.swift
//  LaserGRBL for macOS
//
//  Detailed file information sheet
//

import SwiftUI

struct FileInfoView: View {
    @ObservedObject var file: GCodeFile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "doc.text")
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading) {
                    Text(file.fileName)
                        .font(.title2)
                        .bold()
                    
                    if let path = file.filePath {
                        Text(path.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Statistics
            VStack(alignment: .leading, spacing: 16) {
                Text("File Statistics")
                    .font(.headline)
                
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                    GridRow {
                        Text("Total Commands:")
                            .foregroundColor(.secondary)
                        Text("\(file.commands.count)")
                            .bold()
                    }
                    
                    GridRow {
                        Text("Motion Commands:")
                            .foregroundColor(.secondary)
                        Text("\(file.commands.filter { $0.isMotion }.count)")
                            .bold()
                    }
                    
                    if let bbox = file.boundingBox {
                        GridRow {
                            Text("Width:")
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f mm", bbox.width))
                                .bold()
                        }
                        
                        GridRow {
                            Text("Height:")
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f mm", bbox.height))
                                .bold()
                        }
                        
                        GridRow {
                            Text("Bounds:")
                                .foregroundColor(.secondary)
                            Text(String(format: "X: %.2f to %.2f, Y: %.2f to %.2f",
                                      bbox.minX, bbox.maxX, bbox.minY, bbox.maxY))
                                .bold()
                        }
                        
                        if let depth = bbox.depth {
                            GridRow {
                                Text("Depth:")
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.2f mm", depth))
                                    .bold()
                            }
                        }
                    }
                    
                    if file.estimatedTime > 0 {
                        GridRow {
                            Text("Estimated Time:")
                                .foregroundColor(.secondary)
                            Text(formatDuration(file.estimatedTime))
                                .bold()
                        }
                    }
                }
            }
            
            Divider()
            
            // Command breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Command Breakdown")
                    .font(.headline)
                
                let breakdown = getCommandBreakdown()
                ForEach(Array(breakdown.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(breakdown[key] ?? 0)")
                            .bold()
                    }
                }
            }
            
            Spacer()
            
            // Close button
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 500, height: 600)
    }
    
    private func getCommandBreakdown() -> [String: Int] {
        var breakdown: [String: Int] = [:]
        
        for command in file.commands {
            let key: String
            switch command.command {
            case .motion(let type):
                key = type.rawValue
            case .laser(let cmd):
                key = cmd.rawValue
            case .coordinate(let type):
                key = type.rawValue
            case .units(let type):
                key = type.rawValue
            case .feedRate:
                key = "F (Feed Rate)"
            case .dwell:
                key = "G4 (Dwell)"
            case .comment:
                key = "Comments"
            case .other(let code):
                key = code
            case .empty:
                continue
            }
            
            breakdown[key, default: 0] += 1
        }
        
        return breakdown
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        var parts: [String] = []
        if hours > 0 { parts.append("\(hours)h") }
        if minutes > 0 { parts.append("\(minutes)m") }
        if secs > 0 || parts.isEmpty { parts.append("\(secs)s") }
        
        return parts.joined(separator: " ")
    }
}

#Preview {
    let file = GCodeFile()
    file.fileName = "test_square.gcode"
    file.commands = [
        GCodeCommand(rawLine: "G21", lineNumber: 1),
        GCodeCommand(rawLine: "G90", lineNumber: 2),
        GCodeCommand(rawLine: "G0 X0 Y0", lineNumber: 3),
        GCodeCommand(rawLine: "M3 S500", lineNumber: 4),
        GCodeCommand(rawLine: "G1 X50 Y0 F1000", lineNumber: 5),
        GCodeCommand(rawLine: "G1 X50 Y50", lineNumber: 6),
        GCodeCommand(rawLine: "G1 X0 Y50", lineNumber: 7),
        GCodeCommand(rawLine: "G1 X0 Y0", lineNumber: 8),
        GCodeCommand(rawLine: "M5", lineNumber: 9),
    ]
    file.analyze()
    
    return FileInfoView(file: file)
}

