//
//  GCodeCommand.swift
//  LaserGRBL for macOS
//
//  Core G-code command model
//  Ported from LaserGRBL/GrblCommand.cs
//

import Foundation

/// Represents a single G-code command with its parameters
struct GCodeCommand: Identifiable, Equatable {
    let id = UUID()
    let rawLine: String
    let lineNumber: Int?
    let command: CommandType
    let parameters: [Parameter]

    /// Types of G-code commands
    enum CommandType: Equatable {
        case motion(MotionType)  // G0, G1, G2, G3
        case laser(LaserCommand)  // M3, M4, M5
        case coordinate(CoordinateType)  // G90, G91, G92
        case units(UnitType)  // G20, G21
        case feedRate  // F
        case dwell(Double)  // G4
        case comment
        case other(String)
        case empty
    }

    enum MotionType: String, Equatable {
        case rapid = "G0"
        case linear = "G1"
        case arcCW = "G2"
        case arcCCW = "G3"
    }

    enum LaserCommand: String, Equatable {
        case on = "M3"  // Spindle/Laser on
        case onDynamic = "M4"  // Dynamic power mode
        case off = "M5"  // Spindle/Laser off
    }

    enum CoordinateType: String, Equatable {
        case absolute = "G90"
        case relative = "G91"
        case setPosition = "G92"
    }

    enum UnitType: String, Equatable {
        case inches = "G20"
        case millimeters = "G21"
    }

    /// Individual parameter (X, Y, Z, F, S, etc.)
    struct Parameter: Equatable {
        let letter: Character
        let value: Double

        var formatted: String {
            "\(letter)\(value)"
        }
    }

    // MARK: - Initialization

    init(rawLine: String, lineNumber: Int? = nil) {
        self.rawLine = rawLine.trimmingCharacters(in: .whitespaces)
        self.lineNumber = lineNumber

        // Parse the command
        let trimmed = self.rawLine.uppercased()

        // Handle comments
        if trimmed.isEmpty {
            self.command = .empty
            self.parameters = []
            return
        }

        if trimmed.hasPrefix(";") || trimmed.hasPrefix("(") {
            self.command = .comment
            self.parameters = []
            return
        }

        // Remove inline comments
        let cleanLine = trimmed.components(separatedBy: CharacterSet(charactersIn: ";("))[0]
            .trimmingCharacters(in: .whitespaces)

        // Parse parameters
        self.parameters = Self.parseParameters(from: cleanLine)

        // Determine command type
        self.command = Self.determineCommandType(from: cleanLine, parameters: self.parameters)
    }

    // MARK: - Parsing

    private static func parseParameters(from line: String) -> [Parameter] {
        var params: [Parameter] = []
        var currentLetter: Character?
        var currentValue = ""

        for char in line {
            if char.isLetter {
                // Save previous parameter if exists
                if let letter = currentLetter, !currentValue.isEmpty {
                    if let value = Double(currentValue) {
                        params.append(Parameter(letter: letter, value: value))
                    }
                }
                currentLetter = char
                currentValue = ""
            } else if char.isNumber || char == "." || char == "-" {
                currentValue.append(char)
            } else if char.isWhitespace && !currentValue.isEmpty {
                // Whitespace after a number - save and reset
                if let letter = currentLetter, !currentValue.isEmpty {
                    if let value = Double(currentValue) {
                        params.append(Parameter(letter: letter, value: value))
                    }
                }
                currentLetter = nil
                currentValue = ""
            }
        }

        // Save last parameter
        if let letter = currentLetter, !currentValue.isEmpty {
            if let value = Double(currentValue) {
                params.append(Parameter(letter: letter, value: value))
            }
        }

        return params
    }

    private static func determineCommandType(from line: String, parameters: [Parameter]) -> CommandType {
        let upperLine = line.uppercased()

        // Motion commands
        if upperLine.contains("G0") || upperLine.starts(with: "G0 ") {
            return .motion(.rapid)
        } else if upperLine.contains("G1") || upperLine.starts(with: "G1 ") {
            return .motion(.linear)
        } else if upperLine.contains("G2") || upperLine.starts(with: "G2 ") {
            return .motion(.arcCW)
        } else if upperLine.contains("G3") || upperLine.starts(with: "G3 ") {
            return .motion(.arcCCW)
        }

        // Laser commands
        else if upperLine.contains("M3") {
            return .laser(.on)
        } else if upperLine.contains("M4") {
            return .laser(.onDynamic)
        } else if upperLine.contains("M5") {
            return .laser(.off)
        }

        // Coordinate systems
        else if upperLine.contains("G90") {
            return .coordinate(.absolute)
        } else if upperLine.contains("G91") {
            return .coordinate(.relative)
        } else if upperLine.contains("G92") {
            return .coordinate(.setPosition)
        }

        // Units
        else if upperLine.contains("G20") {
            return .units(.inches)
        } else if upperLine.contains("G21") {
            return .units(.millimeters)
        }

        // Dwell
        else if upperLine.contains("G4") {
            if let pParam = parameters.first(where: { $0.letter == "P" }) {
                return .dwell(pParam.value)
            }
            return .other("G4")
        }

        // Feed rate only
        else if parameters.contains(where: { $0.letter == "F" }) && parameters.count == 1 {
            return .feedRate
        }

        // Generic/other
        else {
            let gCode = upperLine.components(separatedBy: .whitespaces).first ?? ""
            return .other(gCode)
        }
    }

    // MARK: - Helpers

    /// Get X coordinate if present
    var x: Double? {
        parameters.first(where: { $0.letter == "X" })?.value
    }

    /// Get Y coordinate if present
    var y: Double? {
        parameters.first(where: { $0.letter == "Y" })?.value
    }

    /// Get Z coordinate if present
    var z: Double? {
        parameters.first(where: { $0.letter == "Z" })?.value
    }

    /// Get feed rate if present
    var feedRate: Double? {
        parameters.first(where: { $0.letter == "F" })?.value
    }

    /// Get spindle/laser power if present
    var power: Double? {
        parameters.first(where: { $0.letter == "S" })?.value
    }

    /// Get I parameter (arc center offset X) if present
    var i: Double? {
        parameters.first(where: { $0.letter == "I" })?.value
    }

    /// Get J parameter (arc center offset Y) if present
    var j: Double? {
        parameters.first(where: { $0.letter == "J" })?.value
    }

    /// Get K parameter (arc center offset Z) if present
    var k: Double? {
        parameters.first(where: { $0.letter == "K" })?.value
    }

    /// Check if this is a motion command
    var isMotion: Bool {
        if case .motion = command {
            return true
        }
        return false
    }

    /// Check if command is empty or comment
    var isEmpty: Bool {
        command == .empty || command == .comment
    }

    /// Get a display-friendly description
    var displayDescription: String {
        switch command {
        case .motion(let type):
            return "\(type.rawValue) - Motion"
        case .laser(let cmd):
            return "\(cmd.rawValue) - Laser \(cmd == .off ? "Off" : "On")"
        case .coordinate(let type):
            return "\(type.rawValue) - Coordinates"
        case .units(let type):
            return "\(type.rawValue) - \(type == .inches ? "Inches" : "Millimeters")"
        case .feedRate:
            return "F - Feed Rate"
        case .dwell(let time):
            return "G4 - Dwell (\(time)s)"
        case .comment:
            return "Comment"
        case .other(let code):
            return code
        case .empty:
            return "Empty"
        }
    }
}
