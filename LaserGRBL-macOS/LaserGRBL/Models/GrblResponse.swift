//
//  GrblResponse.swift
//  LaserGRBL for macOS
//
//  Models for GRBL controller responses
//  Ported from LaserGRBL/GrblCommand.cs
//

import Foundation

/// Represents different types of messages received from GRBL
enum GrblMessageType {
    case startup        // "Grbl X.Xx ['$' for help]"
    case config         // "$NUM=VAL"
    case alarm          // "ALARM:NUM"
    case feedback       // "[MSG:...]"
    case position       // "<Idle|MPos:0.000,0.000,0.000|...>"
    case ok             // "ok"
    case error          // "error:NUM"
    case unknown
}

/// Represents a response from the GRBL controller
struct GrblResponse {
    let rawMessage: String
    let type: GrblMessageType
    let timestamp: Date
    
    init(rawMessage: String) {
        self.rawMessage = rawMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        self.timestamp = Date()
        self.type = Self.parseMessageType(self.rawMessage)
    }
    
    private static func parseMessageType(_ message: String) -> GrblMessageType {
        let lower = message.lowercased()
        
        if lower.starts(with: "ok") {
            return .ok
        } else if lower.starts(with: "error") {
            return .error
        } else if lower.starts(with: "grbl") {
            return .startup
        } else if lower.starts(with: "alarm") {
            return .alarm
        } else if message.starts(with: "<") && message.hasSuffix(">") {
            return .position
        } else if message.starts(with: "[") && message.hasSuffix("]") {
            return .feedback
        } else if lower.starts(with: "$") && message.contains("=") {
            return .config
        } else {
            return .unknown
        }
    }
    
    /// Parse error code from error response
    var errorCode: Int? {
        guard type == .error else { return nil }
        
        // Error format: "error:NUM" or "ERROR:NUM"
        let parts = rawMessage.split(separator: ":")
        if parts.count == 2, let code = Int(parts[1]) {
            return code
        }
        return nil
    }
    
    /// Check if response indicates success
    var isSuccess: Bool {
        return type == .ok
    }
    
    /// Check if response indicates an error
    var isError: Bool {
        return type == .error
    }
}

/// GRBL machine state
enum GrblState: String {
    case idle = "Idle"
    case run = "Run"
    case hold = "Hold"
    case jog = "Jog"
    case alarm = "Alarm"
    case door = "Door"
    case check = "Check"
    case home = "Home"
    case sleep = "Sleep"
    case unknown = "Unknown"
    
    init(from string: String) {
        self = GrblState(rawValue: string) ?? .unknown
    }
}

/// Real-time status report from GRBL
struct GrblStatus {
    let state: GrblState
    let machinePosition: Position?
    let workPosition: Position?
    let feedRate: Double?
    let spindleSpeed: Double?
    let rawMessage: String
    let timestamp: Date
    
    struct Position {
        let x: Double
        let y: Double
        let z: Double
        
        var description: String {
            return String(format: "X:%.3f Y:%.3f Z:%.3f", x, y, z)
        }
    }
    
    init?(rawMessage: String) {
        self.rawMessage = rawMessage
        self.timestamp = Date()
        
        // Status format: <Idle|MPos:0.000,0.000,0.000|WPos:0.000,0.000,0.000|FS:0,0>
        guard rawMessage.starts(with: "<") && rawMessage.hasSuffix(">") else {
            return nil
        }
        
        let content = String(rawMessage.dropFirst().dropLast())
        let parts = content.split(separator: "|")
        
        guard parts.count > 0 else { return nil }
        
        // Parse state (first part)
        self.state = GrblState(from: String(parts[0]))
        
        var mPos: Position?
        var wPos: Position?
        var feed: Double?
        var spindle: Double?
        
        // Parse remaining parts
        for part in parts.dropFirst() {
            let keyValue = part.split(separator: ":", maxSplits: 1)
            guard keyValue.count == 2 else { continue }
            
            let key = String(keyValue[0])
            let value = String(keyValue[1])
            
            switch key {
            case "MPos":
                mPos = Self.parsePosition(value)
            case "WPos":
                wPos = Self.parsePosition(value)
            case "FS":
                let fsValues = value.split(separator: ",")
                if fsValues.count >= 1 {
                    feed = Double(fsValues[0])
                }
                if fsValues.count >= 2 {
                    spindle = Double(fsValues[1])
                }
            default:
                break
            }
        }
        
        self.machinePosition = mPos
        self.workPosition = wPos
        self.feedRate = feed
        self.spindleSpeed = spindle
    }
    
    private static func parsePosition(_ value: String) -> Position? {
        let coords = value.split(separator: ",").compactMap { Double($0) }
        guard coords.count >= 3 else { return nil }
        return Position(x: coords[0], y: coords[1], z: coords[2])
    }
}

/// GRBL alarm codes
enum GrblAlarm: Int {
    case hardLimit = 1
    case softLimit = 2
    case abortCycle = 3
    case probeFailInitial = 4
    case probeFailContact = 5
    case homingFailReset = 6
    case homingFailDoor = 7
    case homingFailPulloff = 8
    case homingFailApproach = 9
    
    var description: String {
        switch self {
        case .hardLimit:
            return "Hard limit triggered"
        case .softLimit:
            return "Soft limit triggered"
        case .abortCycle:
            return "Reset while in motion"
        case .probeFailInitial:
            return "Probe fail: Initial"
        case .probeFailContact:
            return "Probe fail: Contact"
        case .homingFailReset:
            return "Homing fail: Reset"
        case .homingFailDoor:
            return "Homing fail: Door"
        case .homingFailPulloff:
            return "Homing fail: Pull-off"
        case .homingFailApproach:
            return "Homing fail: Approach"
        }
    }
}

/// GRBL error codes
enum GrblError: Int {
    case expectedCommand = 1
    case badNumberFormat = 2
    case invalidStatement = 3
    case negativeValue = 4
    case settingDisabled = 5
    case settingStepPulse = 6
    case settingReadFail = 7
    case idleError = 8
    case systemGCLock = 9
    case softLimitError = 10
    case overflow = 11
    case maxStepRate = 12
    case checkDoor = 13
    case lineLengthExceeded = 14
    case travelExceeded = 15
    case invalidJogCommand = 16
    case settingDisabledLaser = 17
    case homingNoCycles = 18
    case gcodeLockout = 19
    case softLimitHomingRequired = 20
    case maxCharactersPerLine = 21
    case maxCharactersExceeded = 22
    case grblNotIdle = 23
    case gcodeModalGroupViolation = 24
    case gcodeUnsupportedCommand = 25
    case gcodeModalGroup = 26
    case gcodeUndefinedFeedRate = 27
    case gcodeCommandValueInvalid = 28
    case gcodeArcRadiusError = 29
    case gcodeNoOffsetsInPlane = 30
    case gcodeUnusedWords = 31
    case gcodeG53InvalidMotionMode = 32
    case gcodeAxisWordsExist = 33
    case gcodeNoAxisWords = 34
    case gcodeInvalidLineNumber = 35
    case gcodeValueWordMissing = 36
    case gcodeTooManyAxisWords = 37
    case gcodeInvalidTargetG59 = 38
    
    var description: String {
        switch self {
        case .expectedCommand:
            return "G-code words consist of a letter and a value. Letter was not found."
        case .badNumberFormat:
            return "Numeric value format is not valid or missing an expected value."
        case .invalidStatement:
            return "Grbl '$' system command was not recognized or supported."
        case .negativeValue:
            return "Negative value received for an expected positive value."
        case .settingDisabled:
            return "Homing cycle is not enabled via settings."
        case .settingStepPulse:
            return "Minimum step pulse time must be greater than 3 microseconds."
        case .settingReadFail:
            return "EEPROM read failed. Reset and restored to default values."
        case .idleError:
            return "Grbl '$' command cannot be used unless Grbl is IDLE."
        case .systemGCLock:
            return "G-code lock is engaged. '$X' to unlock."
        case .softLimitError:
            return "Soft limits cannot be enabled without homing also enabled."
        case .overflow:
            return "Max characters per line exceeded. Line was not processed."
        case .maxStepRate:
            return "Max step rate exceeded, reduce feed rate."
        default:
            return "Error code \(rawValue)"
        }
    }
}

