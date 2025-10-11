//
//  GrblCommand.swift
//  LaserGRBL for macOS
//
//  Models for commands sent to GRBL controller
//  Ported from LaserGRBL/GrblCommand.cs
//

import Foundation
import Combine

/// Status of a command in the send/receive cycle
enum GrblCommandStatus {
    case queued             // Waiting to be sent
    case sent               // Sent, waiting for response
    case completed          // Received "ok" response
    case error              // Received "error" response
    case timeout            // No response received
}

/// Represents a command to send to GRBL
class GrblCommand: Identifiable, ObservableObject {
    let id = UUID()
    
    @Published var status: GrblCommandStatus = .queued
    @Published var response: GrblResponse?
    
    let command: String
    let sentAt: Date?
    let priority: Priority
    
    enum Priority: Int, Comparable {
        case realtime = 0    // Immediate commands like ?, !, ~
        case system = 1      // GRBL $ commands
        case normal = 2      // Regular G-code
        
        static func < (lhs: Priority, rhs: Priority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
    
    init(command: String, priority: Priority = .normal) {
        self.command = command.trimmingCharacters(in: .whitespacesAndNewlines)
        self.priority = priority
        self.sentAt = nil
    }
    
    /// Get the command string to send over serial (with newline)
    var serialData: String {
        // Realtime commands don't need newline
        if priority == .realtime {
            return command
        }
        return command + "\n"
    }
    
    /// Mark command as sent
    func markAsSent() {
        status = .sent
    }
    
    /// Set response and update status
    func setResponse(_ response: GrblResponse) {
        self.response = response
        
        if response.isSuccess {
            status = .completed
        } else if response.isError {
            status = .error
        }
    }
    
    /// Mark as timed out
    func markAsTimeout() {
        status = .timeout
    }
    
    /// Check if this is a realtime command (doesn't need response)
    var isRealtime: Bool {
        return priority == .realtime
    }
    
    /// Check if this is a GRBL system command
    var isSystemCommand: Bool {
        return command.starts(with: "$")
    }
    
    var displayDescription: String {
        return command
    }
}

// MARK: - Common GRBL Commands

extension GrblCommand {
    /// Status query (realtime command)
    static var statusQuery: GrblCommand {
        return GrblCommand(command: "?", priority: .realtime)
    }
    
    /// Feed hold (realtime command)
    static var feedHold: GrblCommand {
        return GrblCommand(command: "!", priority: .realtime)
    }
    
    /// Resume (realtime command)
    static var resume: GrblCommand {
        return GrblCommand(command: "~", priority: .realtime)
    }
    
    /// Soft reset (realtime command)
    static var softReset: GrblCommand {
        return GrblCommand(command: "\u{18}", priority: .realtime) // Ctrl-X
    }
    
    /// Unlock (clear alarm/lock state)
    static var unlock: GrblCommand {
        return GrblCommand(command: "$X", priority: .system)
    }
    
    /// Home machine
    static var home: GrblCommand {
        return GrblCommand(command: "$H", priority: .system)
    }
    
    /// View GRBL settings
    static var viewSettings: GrblCommand {
        return GrblCommand(command: "$$", priority: .system)
    }
    
    /// View GRBL parameters
    static var viewParameters: GrblCommand {
        return GrblCommand(command: "$#", priority: .system)
    }
    
    /// View parser state
    static var viewParserState: GrblCommand {
        return GrblCommand(command: "$G", priority: .system)
    }
    
    /// View build info
    static var viewBuildInfo: GrblCommand {
        return GrblCommand(command: "$I", priority: .system)
    }
    
    /// View startup blocks
    static var viewStartupBlocks: GrblCommand {
        return GrblCommand(command: "$N", priority: .system)
    }
    
    /// Jog command
    static func jog(x: Double? = nil, y: Double? = nil, z: Double? = nil, feedRate: Double) -> GrblCommand {
        var cmd = "$J=G91" // Relative positioning for jog
        
        if let x = x {
            cmd += String(format: " X%.3f", x)
        }
        if let y = y {
            cmd += String(format: " Y%.3f", y)
        }
        if let z = z {
            cmd += String(format: " Z%.3f", z)
        }
        
        cmd += String(format: " F%.0f", feedRate)
        
        return GrblCommand(command: cmd, priority: .system)
    }
    
    /// Set work position to zero
    static var zeroWorkPosition: GrblCommand {
        return GrblCommand(command: "G92 X0 Y0 Z0", priority: .normal)
    }
    
    /// Go to work zero
    static var goToWorkZero: GrblCommand {
        return GrblCommand(command: "G90 G0 X0 Y0", priority: .normal)
    }
    
    /// Laser off
    static var laserOff: GrblCommand {
        return GrblCommand(command: "M5", priority: .normal)
    }
}

// MARK: - Command Queue Item

/// Represents a queued command with metadata
struct QueuedCommand: Identifiable {
    let id = UUID()
    let command: GrblCommand
    let lineNumber: Int?
    let queuedAt: Date
    
    init(command: GrblCommand, lineNumber: Int? = nil) {
        self.command = command
        self.lineNumber = lineNumber
        self.queuedAt = Date()
    }
}

