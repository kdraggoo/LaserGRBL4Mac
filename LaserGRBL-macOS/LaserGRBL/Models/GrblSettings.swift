//
//  GrblSettings.swift
//  LaserGRBL for macOS
//
//  GRBL configuration settings model
//  Ported from LaserGRBL/GrblConfig.cs
//

import Foundation
import Combine

/// Category grouping for GRBL settings
enum SettingCategory: String, CaseIterable, Codable {
    case stepper = "Stepper Settings"
    case motion = "Motion Control"
    case limits = "Limits & Homing"
    case interface = "Interface & Reports"
    case speedsFeeds = "Speeds & Feeds"
    case spindle = "Spindle/Laser"
}

/// Individual GRBL setting definition
struct GrblSetting: Identifiable, Codable {
    let id: Int                    // $0, $1, etc.
    let name: String               // "Step pulse time"
    let description: String        // Full explanation
    let tooltip: String            // How it affects behavior
    var value: Double              // Current value
    let unit: String               // "µs", "mm/min", etc.
    let minValue: Double?          // Minimum valid value
    let maxValue: Double?          // Maximum valid value
    let category: SettingCategory
    let grblVersion: String        // "1.1", "1.1f", etc.
    
    var range: ClosedRange<Double>? {
        guard let min = minValue, let max = maxValue else { return nil }
        return min...max
    }
    
    var displayValue: String {
        if unit.isEmpty {
            return String(format: "%.3f", value)
        } else {
            return String(format: "%.3f %@", value, unit)
        }
    }
    
    var settingString: String {
        return "$\(id)=\(value)"
    }
}

/// Manager for GRBL settings database
class GrblSettingsDatabase {
    static let shared = GrblSettingsDatabase()
    
    private init() {}
    
    /// Get all setting definitions with default values
    func getAllSettings() -> [GrblSetting] {
        return [
            // MARK: - Stepper Settings ($0-$2)
            GrblSetting(
                id: 0,
                name: "Step pulse time",
                description: "Minimum pulse width for step signals to stepper drivers",
                tooltip: "Sets the pulse duration in microseconds. Must be greater than 3µs. Too low may cause missed steps.",
                value: 10.0,
                unit: "µs",
                minValue: 3,
                maxValue: 50,
                category: .stepper,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 1,
                name: "Step idle delay",
                description: "Time delay before disabling steppers after motion completes",
                tooltip: "Sets delay in milliseconds. 255 = motors stay enabled indefinitely. 0 = disabled immediately.",
                value: 25.0,
                unit: "ms",
                minValue: 0,
                maxValue: 255,
                category: .stepper,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 2,
                name: "Step port invert",
                description: "Inverts the step pulse signal for stepper drivers",
                tooltip: "Bit mask to invert step signals. Set bits for axes that need inverted signals. Rarely needed.",
                value: 0.0,
                unit: "mask",
                minValue: 0,
                maxValue: 7,
                category: .stepper,
                grblVersion: "1.1"
            ),
            
            // MARK: - Motion Control ($3-$5)
            GrblSetting(
                id: 3,
                name: "Direction port invert",
                description: "Inverts direction signal for stepper motors",
                tooltip: "Bit mask: X=1, Y=2, Z=4. Add values to invert multiple axes. Use if motors move in wrong direction.",
                value: 0.0,
                unit: "mask",
                minValue: 0,
                maxValue: 7,
                category: .motion,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 4,
                name: "Step enable invert",
                description: "Inverts the stepper driver enable signal",
                tooltip: "Set to 1 if your stepper drivers need inverted enable signal. 0 = normal, 1 = inverted.",
                value: 0.0,
                unit: "boolean",
                minValue: 0,
                maxValue: 1,
                category: .motion,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 5,
                name: "Limit pins invert",
                description: "Inverts limit switch input signals",
                tooltip: "Set to 1 to invert limit switch signals. Use if limit switches are normally-closed instead of normally-open.",
                value: 0.0,
                unit: "boolean",
                minValue: 0,
                maxValue: 1,
                category: .motion,
                grblVersion: "1.1"
            ),
            
            // MARK: - Interface ($10-$13)
            GrblSetting(
                id: 10,
                name: "Status report mask",
                description: "Bitmask for status report content options",
                tooltip: "Bit 0: Machine position, Bit 1: Work position. Default 1 = machine position only.",
                value: 1.0,
                unit: "mask",
                minValue: 0,
                maxValue: 3,
                category: .interface,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 11,
                name: "Junction deviation",
                description: "Cornering tolerance for trajectory planning",
                tooltip: "Lower = slower, more accurate corners. Higher = faster, rounder corners. Typical: 0.01-0.02mm.",
                value: 0.01,
                unit: "mm",
                minValue: 0.001,
                maxValue: 0.1,
                category: .interface,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 12,
                name: "Arc tolerance",
                description: "Precision for arc approximation with line segments",
                tooltip: "Smaller = more line segments, smoother arcs, slower. Typical: 0.002mm.",
                value: 0.002,
                unit: "mm",
                minValue: 0.001,
                maxValue: 0.01,
                category: .interface,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 13,
                name: "Report in inches",
                description: "Units for status reports",
                tooltip: "0 = millimeters, 1 = inches. Affects display units only, not G-code interpretation.",
                value: 0.0,
                unit: "boolean",
                minValue: 0,
                maxValue: 1,
                category: .interface,
                grblVersion: "1.1"
            ),
            
            // MARK: - Limits & Homing ($20-$27)
            GrblSetting(
                id: 20,
                name: "Soft limits enable",
                description: "Enable software limits to prevent travel outside work area",
                tooltip: "0 = disabled, 1 = enabled. Requires homing to be enabled. Prevents moves beyond $130-$132.",
                value: 0.0,
                unit: "boolean",
                minValue: 0,
                maxValue: 1,
                category: .limits,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 21,
                name: "Hard limits enable",
                description: "Enable hardware limit switches",
                tooltip: "0 = disabled, 1 = enabled. Triggers alarm when limit switch hit. Requires proper wiring.",
                value: 0.0,
                unit: "boolean",
                minValue: 0,
                maxValue: 1,
                category: .limits,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 22,
                name: "Homing cycle enable",
                description: "Enable homing cycle on startup",
                tooltip: "0 = disabled, 1 = enabled. Required for soft limits. Moves to limit switches to establish position.",
                value: 0.0,
                unit: "boolean",
                minValue: 0,
                maxValue: 1,
                category: .limits,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 23,
                name: "Homing direction invert",
                description: "Reverses homing seek direction",
                tooltip: "Bit mask: X=1, Y=2, Z=4. Set bits for axes that should home in positive direction.",
                value: 0.0,
                unit: "mask",
                minValue: 0,
                maxValue: 7,
                category: .limits,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 24,
                name: "Homing locate feed rate",
                description: "Slow precision feed rate for homing location",
                tooltip: "Speed in mm/min for final homing approach. Slower = more accurate. Typical: 25mm/min.",
                value: 25.0,
                unit: "mm/min",
                minValue: 1,
                maxValue: 500,
                category: .limits,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 25,
                name: "Homing search seek rate",
                description: "Fast seek rate for initial homing approach",
                tooltip: "Speed in mm/min for initial homing search. Faster = quicker homing. Typical: 500mm/min.",
                value: 500.0,
                unit: "mm/min",
                minValue: 10,
                maxValue: 2000,
                category: .limits,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 26,
                name: "Homing switch debounce",
                description: "Debounce delay for homing switches",
                tooltip: "Delay in milliseconds to filter switch noise. Increase if false triggers occur. Typical: 250ms.",
                value: 250.0,
                unit: "ms",
                minValue: 0,
                maxValue: 1000,
                category: .limits,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 27,
                name: "Homing pull-off distance",
                description: "Distance to back off from limit switch after homing",
                tooltip: "Distance in mm to pull away from switch. Prevents constant trigger. Typical: 1-5mm.",
                value: 1.0,
                unit: "mm",
                minValue: 0,
                maxValue: 10,
                category: .limits,
                grblVersion: "1.1"
            ),
            
            // MARK: - Spindle/Laser ($30-$32)
            GrblSetting(
                id: 30,
                name: "Maximum spindle speed",
                description: "Maximum spindle/laser speed value",
                tooltip: "Maximum RPM or power units for S word. S1000 at $30=1000 means 100% power. Critical for scaling.",
                value: 1000.0,
                unit: "RPM",
                minValue: 1,
                maxValue: 100000,
                category: .spindle,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 31,
                name: "Minimum spindle speed",
                description: "Minimum spindle/laser speed value",
                tooltip: "Minimum RPM or power units. S values below this are clamped to this value. Usually 0 for lasers.",
                value: 0.0,
                unit: "RPM",
                minValue: 0,
                maxValue: 10000,
                category: .spindle,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 32,
                name: "Laser mode enable",
                description: "Enable laser-specific motion control",
                tooltip: "0 = spindle mode, 1 = laser mode. CRITICAL: Laser mode keeps power constant through curves. Always use 1 for lasers!",
                value: 0.0,
                unit: "boolean",
                minValue: 0,
                maxValue: 1,
                category: .spindle,
                grblVersion: "1.1"
            ),
            
            // MARK: - Speeds & Feeds - X Axis ($110, $120, $130)
            GrblSetting(
                id: 110,
                name: "X-axis max rate",
                description: "Maximum travel speed for X axis",
                tooltip: "Maximum speed in mm/min. Exceeding causes errors. Set based on mechanical limits. Typical: 1000-5000mm/min.",
                value: 1000.0,
                unit: "mm/min",
                minValue: 1,
                maxValue: 50000,
                category: .speedsFeeds,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 120,
                name: "X-axis acceleration",
                description: "Acceleration rate for X axis",
                tooltip: "How quickly axis changes speed in mm/sec². Higher = faster direction changes but more vibration. Typical: 100-500.",
                value: 100.0,
                unit: "mm/sec²",
                minValue: 1,
                maxValue: 5000,
                category: .speedsFeeds,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 130,
                name: "X-axis max travel",
                description: "Maximum travel distance for X axis",
                tooltip: "Work area size in mm. Used for soft limits and homing. Measure your machine's actual travel.",
                value: 200.0,
                unit: "mm",
                minValue: 0,
                maxValue: 10000,
                category: .speedsFeeds,
                grblVersion: "1.1"
            ),
            
            // MARK: - Speeds & Feeds - Y Axis ($111, $121, $131)
            GrblSetting(
                id: 111,
                name: "Y-axis max rate",
                description: "Maximum travel speed for Y axis",
                tooltip: "Maximum speed in mm/min. Exceeding causes errors. Set based on mechanical limits. Typical: 1000-5000mm/min.",
                value: 1000.0,
                unit: "mm/min",
                minValue: 1,
                maxValue: 50000,
                category: .speedsFeeds,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 121,
                name: "Y-axis acceleration",
                description: "Acceleration rate for Y axis",
                tooltip: "How quickly axis changes speed in mm/sec². Higher = faster direction changes but more vibration. Typical: 100-500.",
                value: 100.0,
                unit: "mm/sec²",
                minValue: 1,
                maxValue: 5000,
                category: .speedsFeeds,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 131,
                name: "Y-axis max travel",
                description: "Maximum travel distance for Y axis",
                tooltip: "Work area size in mm. Used for soft limits and homing. Measure your machine's actual travel.",
                value: 200.0,
                unit: "mm",
                minValue: 0,
                maxValue: 10000,
                category: .speedsFeeds,
                grblVersion: "1.1"
            ),
            
            // MARK: - Speeds & Feeds - Z Axis ($112, $122, $132)
            GrblSetting(
                id: 112,
                name: "Z-axis max rate",
                description: "Maximum travel speed for Z axis",
                tooltip: "Maximum speed in mm/min. Exceeding causes errors. Set based on mechanical limits. Typical: 500-2000mm/min.",
                value: 500.0,
                unit: "mm/min",
                minValue: 1,
                maxValue: 50000,
                category: .speedsFeeds,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 122,
                name: "Z-axis acceleration",
                description: "Acceleration rate for Z axis",
                tooltip: "How quickly axis changes speed in mm/sec². Higher = faster direction changes but more vibration. Typical: 50-200.",
                value: 50.0,
                unit: "mm/sec²",
                minValue: 1,
                maxValue: 5000,
                category: .speedsFeeds,
                grblVersion: "1.1"
            ),
            GrblSetting(
                id: 132,
                name: "Z-axis max travel",
                description: "Maximum travel distance for Z axis",
                tooltip: "Work area size in mm. Used for soft limits and homing. Measure your machine's actual travel.",
                value: 200.0,
                unit: "mm",
                minValue: 0,
                maxValue: 10000,
                category: .speedsFeeds,
                grblVersion: "1.1"
            ),
        ]
    }
    
    /// Get setting by ID
    func getSetting(id: Int) -> GrblSetting? {
        return getAllSettings().first { $0.id == id }
    }
    
    /// Get settings grouped by category
    func getSettingsByCategory() -> [SettingCategory: [GrblSetting]] {
        Dictionary(grouping: getAllSettings(), by: { $0.category })
    }
}

/// Manager for current GRBL settings state
class GrblSettingsManager: ObservableObject {
    @Published var settings: [GrblSetting] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let database = GrblSettingsDatabase.shared
    
    init() {
        // Initialize with default values
        self.settings = database.getAllSettings()
    }
    
    /// Update a setting value
    func updateSetting(id: Int, value: Double) {
        if let index = settings.firstIndex(where: { $0.id == id }) {
            settings[index].value = value
        }
    }
    
    /// Get setting by ID
    func getSetting(id: Int) -> GrblSetting? {
        return settings.first { $0.id == id }
    }
    
    /// Get settings grouped by category
    func getSettingsByCategory() -> [SettingCategory: [GrblSetting]] {
        Dictionary(grouping: settings, by: { $0.category })
    }
    
    /// Parse settings from GRBL $$ response
    func parseSettings(from lines: [String]) {
        for line in lines {
            // Format: $0=10
            guard line.hasPrefix("$"), let equalsIndex = line.firstIndex(of: "=") else {
                continue
            }
            
            let idString = String(line[line.index(after: line.startIndex)..<equalsIndex])
            let valueString = String(line[line.index(after: equalsIndex)...])
            
            guard let id = Int(idString), let value = Double(valueString) else {
                continue
            }
            
            updateSetting(id: id, value: value)
        }
    }
    
    /// Export settings to JSON
    func exportToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(settings)
    }
    
    /// Import settings from JSON
    func importFromJSON(data: Data) -> Bool {
        let decoder = JSONDecoder()
        guard let imported = try? decoder.decode([GrblSetting].self, from: data) else {
            return false
        }
        
        // Update only the values, keep our definitions
        for importedSetting in imported {
            updateSetting(id: importedSetting.id, value: importedSetting.value)
        }
        return true
    }
    
    /// Reset all settings to defaults
    func resetToDefaults() {
        settings = database.getAllSettings()
    }
}

