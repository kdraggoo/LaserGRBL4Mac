//
//  CustomButton.swift
//  LaserGRBL for macOS
//
//  Custom user-defined buttons for executing G-code commands
//  Ported from LaserGRBL/CustomButton.cs
//

import Foundation
import Combine
import SwiftUI

/// Custom button that executes user-defined G-code
struct CustomButton: Identifiable, Codable {
    let id: UUID
    var label: String
    var gcode: String           // Primary G-code
    var gcode2: String?         // Secondary G-code (for TwoState)
    var tooltip: String
    var icon: String            // SF Symbol name
    var buttonType: ButtonType
    var enableCondition: EnableCondition
    var order: Int              // Display order
    
    enum ButtonType: String, Codable, CaseIterable {
        case button = "Button"           // Single click executes once
        case twoState = "Toggle"         // Click to toggle on/off
        case push = "Hold"               // Hold to execute, release to stop
        
        var description: String {
            switch self {
            case .button:
                return "Single-click executes G-code once"
            case .twoState:
                return "Click to toggle between two states (on/off)"
            case .push:
                return "Hold button to execute, release to stop"
            }
        }
    }
    
    enum EnableCondition: String, Codable, CaseIterable {
        case always = "Always"
        case connected = "Connected"
        case idle = "Idle"
        case run = "Running"
        case idleOrRun = "Idle or Running"
        
        var description: String {
            switch self {
            case .always:
                return "Button always enabled"
            case .connected:
                return "Enabled when connected to controller"
            case .idle:
                return "Enabled only when machine is idle"
            case .run:
                return "Enabled only when running a job"
            case .idleOrRun:
                return "Enabled when idle or running"
            }
        }
        
        func isEnabled(isConnected: Bool, machineState: GrblState) -> Bool {
            switch self {
            case .always:
                return true
            case .connected:
                return isConnected
            case .idle:
                return isConnected && machineState == .idle
            case .run:
                return isConnected && (machineState == .run || machineState == .hold)
            case .idleOrRun:
                return isConnected && (machineState == .idle || machineState == .run || machineState == .hold)
            }
        }
    }
    
    init(id: UUID = UUID(), label: String, gcode: String, gcode2: String? = nil, tooltip: String = "", icon: String = "command.square", buttonType: ButtonType = .button, enableCondition: EnableCondition = .connected, order: Int = 0) {
        self.id = id
        self.label = label
        self.gcode = gcode
        self.gcode2 = gcode2
        self.tooltip = tooltip
        self.icon = icon
        self.buttonType = buttonType
        self.enableCondition = enableCondition
        self.order = order
    }
}

/// Manager for custom buttons
class CustomButtonManager: ObservableObject {
    @Published var buttons: [CustomButton] = []
    @Published var buttonStates: [UUID: Bool] = [:] // Track toggle state for TwoState buttons
    
    init() {
        loadDefaults()
    }
    
    /// Load default buttons
    func loadDefaults() {
        buttons = CustomButtonManager.defaultButtons
    }
    
    /// Add button
    func addButton(_ button: CustomButton) {
        var newButton = button
        newButton.order = buttons.count
        buttons.append(newButton)
    }
    
    /// Remove button
    func removeButton(_ button: CustomButton) {
        buttons.removeAll { $0.id == button.id }
        buttonStates.removeValue(forKey: button.id)
    }
    
    /// Update button
    func updateButton(_ button: CustomButton) {
        if let index = buttons.firstIndex(where: { $0.id == button.id }) {
            buttons[index] = button
        }
    }
    
    /// Reorder buttons
    func moveButton(from source: IndexSet, to destination: Int) {
        buttons.move(fromOffsets: source, toOffset: destination)
        // Update order
        for (index, _) in buttons.enumerated() {
            buttons[index].order = index
        }
    }
    
    /// Get button state
    func getState(for button: CustomButton) -> Bool {
        return buttonStates[button.id] ?? false
    }
    
    /// Toggle button state
    func toggleState(for button: CustomButton) {
        buttonStates[button.id] = !(buttonStates[button.id] ?? false)
    }
    
    /// Import from JSON
    func importFromFile(url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let imported = try decoder.decode([CustomButton].self, from: data)
            buttons.append(contentsOf: imported)
            return true
        } catch {
            print("Failed to import custom buttons: \(error)")
            return false
        }
    }
    
    /// Export to JSON
    func exportToFile(url: URL) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(buttons)
            try data.write(to: url)
            return true
        } catch {
            print("Failed to export custom buttons: \(error)")
            return false
        }
    }
    
    // MARK: - Default Buttons
    
    static let defaultButtons: [CustomButton] = [
        CustomButton(
            label: "Frame Job",
            gcode: """
            G90
            G0 X0 Y0
            M3 S10
            G0 X{MAX_X} Y0
            G0 X{MAX_X} Y{MAX_Y}
            G0 X0 Y{MAX_Y}
            G0 X0 Y0
            M5
            """,
            tooltip: "Trace job boundaries with low power",
            icon: "square.dashed",
            buttonType: .button,
            enableCondition: .idle,
            order: 0
        ),
        CustomButton(
            label: "Home XY",
            gcode: "$H",
            tooltip: "Home machine to limit switches",
            icon: "house",
            buttonType: .button,
            enableCondition: .idle,
            order: 1
        ),
        CustomButton(
            label: "Zero XY",
            gcode: "G10 L20 P0 X0 Y0",
            tooltip: "Set current position as work zero",
            icon: "scope",
            buttonType: .button,
            enableCondition: .idle,
            order: 2
        ),
        CustomButton(
            label: "Focus Pulse",
            gcode: "M3 S100\nG4 P0.5\nM5",
            tooltip: "Brief laser pulse for focusing (500ms)",
            icon: "laser.burst",
            buttonType: .button,
            enableCondition: .idle,
            order: 3
        ),
        CustomButton(
            label: "Air Assist",
            gcode: "M8",
            gcode2: "M9",
            tooltip: "Toggle air assist on/off",
            icon: "wind",
            buttonType: .twoState,
            enableCondition: .connected,
            order: 4
        ),
    ]
}

