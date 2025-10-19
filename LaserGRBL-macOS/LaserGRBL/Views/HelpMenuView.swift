//
//  HelpMenuView.swift
//  LaserGRBL for macOS
//
//  Help menu and documentation viewer
//

import SwiftUI

struct HelpMenuView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedSection: HelpSection = .quickStart
    
    enum HelpSection: String, CaseIterable {
        case quickStart = "Quick Start"
        case materials = "Material Guide"
        case errors = "Error Codes"
        case alarms = "Alarm Codes"
        case shortcuts = "Keyboard Shortcuts"
        
        var icon: String {
            switch self {
            case .quickStart: return "book"
            case .materials: return "hammer"
            case .errors: return "exclamationmark.triangle"
            case .alarms: return "bell"
            case .shortcuts: return "keyboard"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedSection) {
                ForEach(HelpSection.allCases, id: \.self) { section in
                    NavigationLink(value: section) {
                        Label(section.rawValue, systemImage: section.icon)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Help")
            .frame(minWidth: 200)
        } detail: {
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedSection {
                    case .quickStart:
                        quickStartView
                    case .materials:
                        materialsView
                    case .errors:
                        errorsView
                    case .alarms:
                        alarmsView
                    case .shortcuts:
                        shortcutsView
                    }
                }
                .padding()
            }
            .frame(minWidth: 600)
        }
        .frame(width: 900, height: 700)
    }
    
    // MARK: - Content Views
    
    private var quickStartView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Start Guide")
                .font(.largeTitle)
                .bold()
            
            Divider()
            
            Text("Getting Started with LaserGRBL for macOS")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 12) {
                HelpStepView(
                    number: 1,
                    title: "Connect Your Machine",
                    description: "1. Connect your GRBL controller via USB\n2. Select the correct port in Connection panel\n3. Set baud rate to 115200 (GRBL default)\n4. Click Connect"
                )
                
                HelpStepView(
                    number: 2,
                    title: "Configure GRBL Settings",
                    description: "1. Go to Settings tab\n2. Click 'Read from Controller'\n3. Verify work area size ($130-$132)\n4. Enable laser mode ($32=1) - CRITICAL!\n5. Set max spindle speed ($30) to match your laser"
                )
                
                HelpStepView(
                    number: 3,
                    title: "Home Your Machine",
                    description: "1. Enable homing if available ($22=1)\n2. Click Home button in Control panel\n3. Machine will move to limit switches\n4. Set work zero at desired starting position"
                )
                
                HelpStepView(
                    number: 4,
                    title: "Prepare Your Design",
                    description: "For Images:\n• Import tab → Import Image\n• Adjust DPI (254 typical for 0.1mm resolution)\n• Choose dithering algorithm\n• Set power and speed (start low!)\n\nFor Vectors:\n• Import tab → Import SVG\n• Set stroke speed and power\n• Configure fill if needed"
                )
                
                HelpStepView(
                    number: 5,
                    title: "Preview and Run",
                    description: "1. Preview G-code in G-Code tab\n2. Check dimensions and position\n3. Frame job (optional - low power trace)\n4. Click run in Control panel\n5. Monitor progress and adjust overrides if needed"
                )
            }
            
            Text("⚠️ Safety First!")
                .font(.headline)
                .foregroundColor(.red)
            
            Text("• Always test on scrap material first\n• Never leave laser unattended\n• Use proper eye protection\n• Ensure adequate ventilation\n• Keep fire extinguisher nearby")
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private var materialsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Material Recommendations")
                .font(.largeTitle)
                .bold()
            
            Divider()
            
            Text(HelpResources.materialGuide)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
        }
    }
    
    private var errorsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GRBL Error Codes")
                .font(.largeTitle)
                .bold()
            
            Divider()
            
            Text("When GRBL encounters an error, it returns 'error:N' where N is the error code.")
                .foregroundColor(.secondary)
            
            ForEach(HelpSystem.shared.allErrors(), id: \.code) { error in
                ErrorHelpRow(error: error)
            }
        }
    }
    
    private var alarmsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GRBL Alarm Codes")
                .font(.largeTitle)
                .bold()
            
            Divider()
            
            Text("Alarms halt all motion and require clearing with $X before resuming.")
                .foregroundColor(.secondary)
            
            ForEach(HelpSystem.shared.allAlarms(), id: \.code) { alarm in
                AlarmHelpRow(alarm: alarm)
            }
        }
    }
    
    private var shortcutsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keyboard Shortcuts")
                .font(.largeTitle)
                .bold()
            
            Divider()
            
            Text(HelpResources.keyboardShortcuts)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
        }
    }
}

// MARK: - Help Step View

struct HelpStepView: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .foregroundColor(.white)
                    .bold()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - Error Help Row

struct ErrorHelpRow: View {
    let error: ErrorHelp
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                    
                    Text("Error \(error.code):")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.red)
                    
                    Text(error.name)
                        .font(.headline)
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.description)
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Solution:")
                            .font(.subheadline)
                            .bold()
                        Text(error.solution)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prevention:")
                            .font(.subheadline)
                            .bold()
                        Text(error.prevention)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 24)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Alarm Help Row

struct AlarmHelpRow: View {
    let alarm: AlarmHelp
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                    
                    Text("ALARM:\(alarm.code)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.orange)
                    
                    Text(alarm.name)
                        .font(.headline)
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(alarm.description)
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Solution:")
                            .font(.subheadline)
                            .bold()
                        Text(alarm.solution)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prevention:")
                            .font(.subheadline)
                            .bold()
                        Text(alarm.prevention)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 24)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    HelpMenuView()
}

