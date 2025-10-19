//
//  ControlPanelView.swift
//  LaserGRBL for macOS
//
//  Machine control interface (jog, home, zero, etc.)
//

import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var grblController: GrblController
    @ObservedObject var buttonManager: CustomButtonManager
    
    @State private var jogDistance: Double = 10.0
    @State private var jogFeedRate: Double = 1000.0
    @State private var showingButtonEditor = false
    @State private var showingResumeSheet = false
    @State private var resumeLineNumber: String = "0"
    @State private var syncPositionOnResume: Bool = false
    
    let jogDistances: [Double] = [0.1, 1.0, 10.0, 100.0]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "gamecontroller")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("Control Panel")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            // Jog controls
            jogControlsView
            
            Divider()
            
            // System controls
            systemControlsView
            
            Divider()
            
            // Custom buttons
            customButtonsView
            
            Divider()
            
            // Override controls
            overrideControlsView
            
            Divider()
            
            // Execution controls
            executionControlsView
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 300, idealWidth: 350)
        .disabled(!grblController.isConnected)
        .sheet(isPresented: $showingButtonEditor) {
            CustomButtonEditorView(buttonManager: buttonManager, grblController: grblController)
        }
        .sheet(isPresented: $showingResumeSheet) {
            ResumeJobSheet(
                grblController: grblController,
                lineNumber: $resumeLineNumber,
                syncPosition: $syncPositionOnResume,
                onResume: {
                    if let line = Int(resumeLineNumber) {
                        grblController.runFromPosition(line, syncPosition: syncPositionOnResume)
                    }
                }
            )
        }
    }
    
    // MARK: - Jog Controls
    
    private var jogControlsView: some View {
        VStack(spacing: 12) {
            Text("Jog Controls")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Distance selector
            Picker("Jog Distance", selection: $jogDistance) {
                ForEach(jogDistances, id: \.self) { distance in
                    Text(formatJogDistance(distance)).tag(distance)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            
            // XY Jog pad
            VStack(spacing: 8) {
                // Y+
                Button(action: { jog(y: jogDistance) }) {
                    Image(systemName: "arrow.up")
                        .frame(width: 60, height: 40)
                }
                .buttonStyle(.bordered)
                
                HStack(spacing: 8) {
                    // X-
                    Button(action: { jog(x: -jogDistance) }) {
                        Image(systemName: "arrow.left")
                            .frame(width: 60, height: 40)
                    }
                    .buttonStyle(.bordered)
                    
                    // Home
                    Button(action: { goHome() }) {
                        Image(systemName: "house")
                            .frame(width: 60, height: 40)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // X+
                    Button(action: { jog(x: jogDistance) }) {
                        Image(systemName: "arrow.right")
                            .frame(width: 60, height: 40)
                    }
                    .buttonStyle(.bordered)
                }
                
                // Y-
                Button(action: { jog(y: -jogDistance) }) {
                    Image(systemName: "arrow.down")
                        .frame(width: 60, height: 40)
                }
                .buttonStyle(.bordered)
            }
            
            // Z controls
            HStack(spacing: 8) {
                Button(action: { jog(z: jogDistance) }) {
                    Label("Z+", systemImage: "arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: { jog(z: -jogDistance) }) {
                    Label("Z-", systemImage: "arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            // Feed rate
            VStack(alignment: .leading, spacing: 4) {
                Text("Feed Rate: \(Int(jogFeedRate)) mm/min")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(value: $jogFeedRate, in: 100...3000, step: 100)
            }
        }
    }
    
    // MARK: - System Controls
    
    private var systemControlsView: some View {
        VStack(spacing: 8) {
            Text("System")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Button(action: {
                    grblController.home()
                }) {
                    Label("Home", systemImage: "house.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    grblController.zeroWorkPosition()
                }) {
                    Label("Zero XY", systemImage: "scope")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            HStack(spacing: 8) {
                Button(action: {
                    grblController.goToWorkZero()
                }) {
                    Label("Go to Zero", systemImage: "target")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    grblController.clearAlarm()
                }) {
                    Label("Clear Alarm", systemImage: "exclamationmark.triangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
    }
    
    // MARK: - Custom Buttons
    
    private var customButtonsView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Custom Buttons")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { showingButtonEditor = true }) {
                    Image(systemName: "gearshape")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Manage custom buttons")
            }
            
            if buttonManager.buttons.isEmpty {
                Text("No custom buttons")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(buttonManager.buttons.sorted { $0.order < $1.order }) { button in
                            CustomButtonControl(
                                button: button,
                                grblController: grblController,
                                buttonManager: buttonManager
                            )
                        }
                    }
                }
                .frame(height: 44)
            }
        }
    }
    
    // MARK: - Override Controls
    
    private var overrideControlsView: some View {
        VStack(spacing: 12) {
            Text("Real-time Overrides")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Feed rate override
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Feed Rate:")
                        .font(.caption)
                    Spacer()
                    Text("\(grblController.feedOverride)%")
                        .font(.caption)
                        .foregroundColor(overrideColor(grblController.feedOverride))
                        .bold()
                    Button(action: {
                        grblController.setFeedOverride(100)
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("Reset feed rate to 100%")
                }
                
                Slider(value: Binding(
                    get: { Double(grblController.feedOverride) },
                    set: { grblController.setFeedOverride(Int($0)) }
                ), in: 10...200, step: 1)
                .help("Adjust feed rate speed (10% - 200%)")
            }
            
            // Spindle/Laser override
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Laser Power:")
                        .font(.caption)
                    Spacer()
                    Text("\(grblController.spindleOverride)%")
                        .font(.caption)
                        .foregroundColor(overrideColor(grblController.spindleOverride))
                        .bold()
                    Button(action: {
                        grblController.setSpindleOverride(100)
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("Reset laser power to 100%")
                }
                
                Slider(value: Binding(
                    get: { Double(grblController.spindleOverride) },
                    set: { grblController.setSpindleOverride(Int($0)) }
                ), in: 10...200, step: 1)
                .help("Adjust laser/spindle power (10% - 200%)")
            }
            
            // Rapid rate override
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Rapid Rate:")
                        .font(.caption)
                    Spacer()
                    Text("\(grblController.rapidOverride)%")
                        .font(.caption)
                        .foregroundColor(overrideColor(grblController.rapidOverride))
                        .bold()
                    Button(action: {
                        grblController.setRapidOverride(100)
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("Reset rapid rate to 100%")
                }
                
                Picker("Rapid", selection: Binding(
                    get: { grblController.rapidOverride },
                    set: { grblController.setRapidOverride($0) }
                )) {
                    Text("25%").tag(25)
                    Text("50%").tag(50)
                    Text("100%").tag(100)
                }
                .pickerStyle(.segmented)
                .help("Rapid movement speed (25%, 50%, or 100%)")
            }
        }
    }
    
    // MARK: - Execution Controls
    
    private var executionControlsView: some View {
        VStack(spacing: 12) {
            Text("Execution")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Queue status
            if grblController.isRunning {
                VStack(spacing: 4) {
                    ProgressView(value: progressValue) {
                        HStack {
                            Text("Running")
                                .font(.caption)
                            Spacer()
                            Text("\(completedCommands) / \(totalCommands)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if grblController.isPaused {
                        Label("Paused", systemImage: "pause.circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Control buttons
            HStack(spacing: 8) {
                if grblController.isPaused {
                    Button(action: {
                        grblController.resume()
                    }) {
                        Label("Resume", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    Button(action: {
                        grblController.pause()
                    }) {
                        Label("Pause", systemImage: "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!grblController.isRunning)
                }
                
                Button(action: {
                    grblController.stop()
                }) {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!grblController.isRunning)
            }
            
            // Resume from line button
            Button(action: {
                showingResumeSheet = true
            }) {
                Label("Resume from Line...", systemImage: "arrow.uturn.forward")
            }
            .buttonStyle(.bordered)
            .help("Resume job from specific line number")
        }
    }
    
    // MARK: - Helper Properties
    
    private var totalCommands: Int {
        return grblController.queuedCommands.count + grblController.pendingCommands.count
    }
    
    private var completedCommands: Int {
        // Calculate based on initial total (would need to track this)
        return grblController.pendingCommands.count
    }
    
    private var progressValue: Double {
        guard totalCommands > 0 else { return 0 }
        return Double(completedCommands) / Double(totalCommands)
    }
    
    // MARK: - Helper Methods
    
    private func formatJogDistance(_ distance: Double) -> String {
        if distance < 1 {
            return String(format: "%.1f mm", distance)
        } else {
            return String(format: "%.0f mm", distance)
        }
    }
    
    private func jog(x: Double? = nil, y: Double? = nil, z: Double? = nil) {
        grblController.jog(x: x, y: y, z: z, feedRate: jogFeedRate)
    }
    
    private func goHome() {
        grblController.goToWorkZero()
    }
    
    private func overrideColor(_ percent: Int) -> Color {
        if percent < 100 {
            return .blue  // Slower than normal
        } else if percent > 100 {
            return .red   // Faster than normal
        } else {
            return .primary  // Normal speed
        }
    }
}

// MARK: - Custom Button Control

struct CustomButtonControl: View {
    let button: CustomButton
    @ObservedObject var grblController: GrblController
    @ObservedObject var buttonManager: CustomButtonManager
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: handleButtonPress) {
            Label(button.label, systemImage: button.icon)
                .font(.caption)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .tint(isToggled ? .green : .accentColor)
        .disabled(!isEnabled)
        .help(button.tooltip.isEmpty ? button.label : button.tooltip)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if button.buttonType == .push && !isPressed {
                        isPressed = true
                        executeGCode(button.gcode)
                    }
                }
                .onEnded { _ in
                    if button.buttonType == .push && isPressed {
                        isPressed = false
                        if let gcode2 = button.gcode2 {
                            executeGCode(gcode2)
                        }
                    }
                }
        )
    }
    
    private var isEnabled: Bool {
        button.enableCondition.isEnabled(
            isConnected: grblController.isConnected,
            machineState: grblController.machineState
        )
    }
    
    private var isToggled: Bool {
        button.buttonType == .twoState && buttonManager.getState(for: button)
    }
    
    private func handleButtonPress() {
        switch button.buttonType {
        case .button:
            executeGCode(button.gcode)
            
        case .twoState:
            buttonManager.toggleState(for: button)
            let isOn = buttonManager.getState(for: button)
            let gcode = isOn ? button.gcode : (button.gcode2 ?? "")
            executeGCode(gcode)
            
        case .push:
            // Handled by gesture
            break
        }
    }
    
    private func executeGCode(_ gcode: String) {
        let lines = gcode.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }
        for line in lines where !line.isEmpty && !line.hasPrefix(";") {
            let command = GrblCommand(command: line, priority: .system)
            grblController.sendCommand(command)
        }
    }
}

// MARK: - Resume Job Sheet

struct ResumeJobSheet: View {
    @ObservedObject var grblController: GrblController
    @Binding var lineNumber: String
    @Binding var syncPosition: Bool
    let onResume: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Resume Job")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Resume execution from a specific line number")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Line Number:")
                        .frame(width: 100, alignment: .leading)
                    
                    TextField("0", text: $lineNumber)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .help("Line number to resume from (0-based)")
                }
                
                Toggle("Sync Position First", isOn: $syncPosition)
                    .help("Set current position as work zero before resuming")
                
                // Position verification
                if grblController.verifyPosition() {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Position verified")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Unable to verify position")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Text("⚠️ Warning: Resuming from an incorrect position may damage your workpiece or machine.")
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Resume") {
                    onResume()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(!grblController.isConnected)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 450, height: 400)
    }
}

#Preview {
    let serialManager = SerialPortManager()
    let grblController = GrblController(serialManager: serialManager)
    let buttonManager = CustomButtonManager()
    
    return ControlPanelView(grblController: grblController, buttonManager: buttonManager)
        .frame(width: 350, height: 600)
}

