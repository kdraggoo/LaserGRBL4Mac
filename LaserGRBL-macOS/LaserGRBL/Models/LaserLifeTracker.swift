//
//  LaserLifeTracker.swift
//  LaserGRBL for macOS
//
//  Laser usage tracking and life monitoring
//  Ported from LaserGRBL/LaserUsage.cs
//

import Foundation
import Combine

/// Laser module information and usage statistics
struct LaserModule: Identifiable, Codable {
    let id: UUID
    var name: String
    var brand: String
    var model: String
    var opticalPower: Double?      // Watts
    var purchaseDate: Date?
    var monitoringStartDate: Date
    var deathDate: Date?
    var lastUsed: Date?
    var runtime: TimeInterval       // Total time in Run state
    var normalizedTime: TimeInterval // Power-normalized usage
    var powerClasses: [TimeInterval]  // 10 buckets: 0-10%, 11-20%, ..., 91-100%
    
    init(id: UUID = UUID(), name: String, brand: String = "", model: String = "", opticalPower: Double? = nil, purchaseDate: Date? = nil) {
        self.id = id
        self.name = name
        self.brand = brand
        self.model = model
        self.opticalPower = opticalPower
        self.purchaseDate = purchaseDate
        self.monitoringStartDate = Date()
        self.deathDate = nil
        self.lastUsed = nil
        self.runtime = 0
        self.normalizedTime = 0
        self.powerClasses = Array(repeating: 0, count: 10)
    }
    
    /// Get active time (time with laser power > 3%)
    var activeTime: TimeInterval {
        return powerClasses.reduce(0, +)
    }
    
    /// Get average power factor (0-1)
    var averagePowerFactor: Double {
        guard activeTime > 0 else { return 0 }
        return normalizedTime / activeTime
    }
    
    /// Get stress time (time at 91-100% power)
    var stressTime: TimeInterval {
        return powerClasses[9] // Last bucket
    }
    
    /// Get power distribution percentages
    var powerDistributionPercent: [Double] {
        guard activeTime > 0 else { return Array(repeating: 0, count: 10) }
        return powerClasses.map { ($0 / activeTime) * 100 }
    }
}

/// Tracker for laser usage statistics
class LaserLifeTracker: ObservableObject {
    @Published var modules: [LaserModule] = []
    @Published var currentModuleId: UUID?
    
    private var lastRecordTime: Date?
    private var lastPower: Float = 0
    
    init() {
        loadFromUserDefaults()
    }
    
    var currentModule: LaserModule? {
        get {
            guard let id = currentModuleId else { return nil }
            return modules.first { $0.id == id }
        }
        set {
            currentModuleId = newValue?.id
        }
    }
    
    // MARK: - Module Management
    
    func addModule(_ module: LaserModule) {
        modules.append(module)
        if currentModuleId == nil {
            currentModuleId = module.id
        }
        saveToUserDefaults()
    }
    
    func removeModule(_ module: LaserModule) {
        modules.removeAll { $0.id == module.id }
        if currentModuleId == module.id {
            currentModuleId = modules.first?.id
        }
        saveToUserDefaults()
    }
    
    func updateModule(_ module: LaserModule) {
        if let index = modules.firstIndex(where: { $0.id == module.id }) {
            modules[index] = module
            saveToUserDefaults()
        }
    }
    
    // MARK: - Usage Recording
    
    /// Record laser usage
    /// - Parameters:
    ///   - power: Laser power (0-100%)
    ///   - duration: Time duration in seconds
    func recordUsage(power: Float, duration: TimeInterval) {
        guard var module = currentModule else { return }
        
        // Update last used time
        module.lastUsed = Date()
        
        // Record runtime
        module.runtime += duration
        
        // Only record if power > 3% (laser actually firing)
        guard power > 3 else {
            updateModule(module)
            return
        }
        
        // Determine power class (0-10%, 11-20%, ..., 91-100%)
        let powerClass = min(Int(power / 10), 9)
        
        // Add to appropriate power class
        module.powerClasses[powerClass] += duration
        
        // Calculate normalized time (power-weighted)
        let normalizedDuration = duration * Double(power / 100.0)
        module.normalizedTime += normalizedDuration
        
        updateModule(module)
    }
    
    /// Start recording session
    func startRecording(power: Float) {
        lastRecordTime = Date()
        lastPower = power
    }
    
    /// Update recording with new power
    func updateRecording(power: Float) {
        guard let lastTime = lastRecordTime else { return }
        
        let now = Date()
        let duration = now.timeIntervalSince(lastTime)
        
        // Record the previous power level for the elapsed duration
        if duration > 0 {
            recordUsage(power: lastPower, duration: duration)
        }
        
        lastRecordTime = now
        lastPower = power
    }
    
    /// End recording session
    func stopRecording() {
        if let lastTime = lastRecordTime {
            let duration = Date().timeIntervalSince(lastTime)
            if duration > 0 {
                recordUsage(power: lastPower, duration: duration)
            }
        }
        
        lastRecordTime = nil
        lastPower = 0
    }
    
    // MARK: - Statistics
    
    func getTotalRuntime() -> TimeInterval {
        return modules.reduce(0) { $0 + $1.runtime }
    }
    
    func getTotalActiveTime() -> TimeInterval {
        return modules.reduce(0) { $0 + $1.activeTime }
    }
    
    func getTotalNormalizedTime() -> TimeInterval {
        return modules.reduce(0) { $0 + $1.normalizedTime }
    }
    
    // MARK: - Persistence
    
    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(modules) {
            UserDefaults.standard.set(encoded, forKey: "LaserModules")
        }
        if let currentId = currentModuleId {
            UserDefaults.standard.set(currentId.uuidString, forKey: "CurrentLaserModuleId")
        }
    }
    
    private func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "LaserModules"),
           let decoded = try? JSONDecoder().decode([LaserModule].self, from: data) {
            modules = decoded
        }
        
        if let idString = UserDefaults.standard.string(forKey: "CurrentLaserModuleId"),
           let id = UUID(uuidString: idString) {
            currentModuleId = id
        } else if !modules.isEmpty {
            currentModuleId = modules.first?.id
        }
    }
    
    // MARK: - Export
    
    func exportToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(modules)
    }
    
    func importFromJSON(data: Data) -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let imported = try? decoder.decode([LaserModule].self, from: data) else {
            return false
        }
        
        modules.append(contentsOf: imported)
        if currentModuleId == nil, let first = modules.first {
            currentModuleId = first.id
        }
        
        saveToUserDefaults()
        return true
    }
}

// MARK: - Helper Extensions

extension TimeInterval {
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

