//
//  HelpSystem.swift
//  LaserGRBL for macOS
//
//  Centralized help and tooltip system
//

import Foundation

/// Centralized help system for tooltips and documentation
class HelpSystem {
    static let shared = HelpSystem()
    
    private init() {}
    
    /// Get tooltip for a control by key
    func tooltip(for key: String) -> String {
        return HelpResources.tooltips[key] ?? "No help available"
    }
    
    /// Get error description
    func errorDescription(code: Int) -> ErrorHelp? {
        return HelpResources.errors[code]
    }
    
    /// Get alarm description
    func alarmDescription(code: Int) -> AlarmHelp? {
        return HelpResources.alarms[code]
    }
    
    /// Get all error codes
    func allErrors() -> [ErrorHelp] {
        return HelpResources.errors.values.sorted { $0.code < $1.code }
    }
    
    /// Get all alarm codes
    func allAlarms() -> [AlarmHelp] {
        return HelpResources.alarms.values.sorted { $0.code < $1.code }
    }
}

/// Error help information
struct ErrorHelp {
    let code: Int
    let name: String
    let description: String
    let solution: String
    let prevention: String
}

/// Alarm help information
struct AlarmHelp {
    let code: Int
    let name: String
    let description: String
    let solution: String
    let prevention: String
}

