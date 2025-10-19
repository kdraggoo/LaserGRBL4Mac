//
//  MaterialDatabase.swift
//  LaserGRBL for macOS
//
//  Material preset database for power/speed recommendations
//  Ported from LaserGRBL/PSHelper/MaterialDB.cs
//

import Foundation
import Combine

/// Material preset for laser operations
struct MaterialPreset: Identifiable, Codable {
    let id: UUID
    var laserModel: String      // "Ortur LM2 20W", "K40", "Generic", etc.
    var material: String        // "Wood", "Acrylic", etc.
    var thickness: Double       // mm
    var action: String          // "Cut", "Engrave", "Score"
    var power: Int              // 1-100%
    var speed: Int              // mm/min
    var passes: Int             // number of passes
    var remarks: String         // notes/tips
    var isCustom: Bool          // user-created vs built-in
    
    init(id: UUID = UUID(), laserModel: String, material: String, thickness: Double, action: String, power: Int, speed: Int, passes: Int = 1, remarks: String = "", isCustom: Bool = false) {
        self.id = id
        self.laserModel = laserModel
        self.material = material
        self.thickness = thickness
        self.action = action
        self.power = power
        self.speed = speed
        self.passes = passes
        self.remarks = remarks
        self.isCustom = isCustom
    }
    
    var displayName: String {
        return "\(material) \(String(format: "%.1fmm", thickness)) - \(action)"
    }
}

/// Material database manager
class MaterialDatabase: ObservableObject {
    @Published var presets: [MaterialPreset] = []
    
    init() {
        loadDefaults()
    }
    
    /// Load default material presets
    func loadDefaults() {
        presets = MaterialDatabase.defaultPresets
    }
    
    /// Add custom preset
    func addPreset(_ preset: MaterialPreset) {
        var newPreset = preset
        newPreset.isCustom = true
        presets.append(newPreset)
    }
    
    /// Remove preset
    func removePreset(_ preset: MaterialPreset) {
        presets.removeAll { $0.id == preset.id }
    }
    
    /// Update preset
    func updatePreset(_ preset: MaterialPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
        }
    }
    
    /// Filter presets by criteria
    func filterBy(model: String? = nil, material: String? = nil, thickness: Double? = nil, action: String? = nil) -> [MaterialPreset] {
        var filtered = presets
        
        if let model = model, !model.isEmpty {
            filtered = filtered.filter { $0.laserModel == model || $0.laserModel == "Generic" }
        }
        
        if let material = material, !material.isEmpty {
            filtered = filtered.filter { $0.material == material }
        }
        
        if let thickness = thickness {
            filtered = filtered.filter { abs($0.thickness - thickness) < 0.1 }
        }
        
        if let action = action, !action.isEmpty {
            filtered = filtered.filter { $0.action == action }
        }
        
        return filtered.sorted { $0.material < $1.material }
    }
    
    /// Get unique laser models
    var laserModels: [String] {
        Array(Set(presets.map { $0.laserModel })).sorted()
    }
    
    /// Get unique materials
    var materials: [String] {
        Array(Set(presets.map { $0.material })).sorted()
    }
    
    /// Get unique thicknesses for a material
    func thicknesses(for material: String) -> [Double] {
        Array(Set(presets.filter { $0.material == material }.map { $0.thickness })).sorted()
    }
    
    /// Get unique actions for material and thickness
    func actions(for material: String, thickness: Double) -> [String] {
        Array(Set(presets.filter { $0.material == material && abs($0.thickness - thickness) < 0.1 }.map { $0.action })).sorted()
    }
    
    /// Import from JSON file
    func importFromFile(url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let imported = try decoder.decode([MaterialPreset].self, from: data)
            
            // Add imported presets as custom
            for preset in imported {
                var customPreset = preset
                customPreset.isCustom = true
                presets.append(customPreset)
            }
            return true
        } catch {
            print("Failed to import material presets: \(error)")
            return false
        }
    }
    
    /// Export to JSON file
    func exportToFile(url: URL) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(presets)
            try data.write(to: url)
            return true
        } catch {
            print("Failed to export material presets: \(error)")
            return false
        }
    }
    
    // MARK: - Default Presets
    
    static let defaultPresets: [MaterialPreset] = [
        // MARK: - Wood (Generic)
        MaterialPreset(laserModel: "Generic", material: "Wood", thickness: 3.0, action: "Engrave", power: 20, speed: 2000, passes: 1, remarks: "Light engraving for hardwood"),
        MaterialPreset(laserModel: "Generic", material: "Wood", thickness: 3.0, action: "Cut", power: 80, speed: 500, passes: 2, remarks: "Multiple passes recommended"),
        MaterialPreset(laserModel: "Generic", material: "Wood", thickness: 6.0, action: "Engrave", power: 25, speed: 1800, passes: 1),
        MaterialPreset(laserModel: "Generic", material: "Wood", thickness: 6.0, action: "Cut", power: 100, speed: 300, passes: 3, remarks: "Slow, multiple passes"),
        
        // MARK: - Plywood
        MaterialPreset(laserModel: "Generic", material: "Plywood", thickness: 3.0, action: "Engrave", power: 15, speed: 2500, passes: 1),
        MaterialPreset(laserModel: "Generic", material: "Plywood", thickness: 3.0, action: "Cut", power: 70, speed: 600, passes: 2, remarks: "Watch for glue layers"),
        MaterialPreset(laserModel: "Generic", material: "Plywood", thickness: 6.0, action: "Cut", power: 90, speed: 400, passes: 3),
        
        // MARK: - MDF
        MaterialPreset(laserModel: "Generic", material: "MDF", thickness: 3.0, action: "Engrave", power: 25, speed: 1800, passes: 1, remarks: "Good contrast, needs ventilation"),
        MaterialPreset(laserModel: "Generic", material: "MDF", thickness: 3.0, action: "Cut", power: 85, speed: 400, passes: 2),
        MaterialPreset(laserModel: "Generic", material: "MDF", thickness: 6.0, action: "Cut", power: 100, speed: 300, passes: 3),
        
        // MARK: - Acrylic
        MaterialPreset(laserModel: "Generic", material: "Acrylic", thickness: 3.0, action: "Engrave", power: 10, speed: 3000, passes: 1, remarks: "Cast acrylic gives frosted white"),
        MaterialPreset(laserModel: "Generic", material: "Acrylic", thickness: 3.0, action: "Cut", power: 60, speed: 300, passes: 1, remarks: "Cast acrylic only"),
        MaterialPreset(laserModel: "Generic", material: "Acrylic", thickness: 6.0, action: "Engrave", power: 15, speed: 2500, passes: 1),
        MaterialPreset(laserModel: "Generic", material: "Acrylic", thickness: 6.0, action: "Cut", power: 80, speed: 200, passes: 2),
        
        // MARK: - Leather
        MaterialPreset(laserModel: "Generic", material: "Leather", thickness: 1.0, action: "Engrave", power: 8, speed: 2000, passes: 1, remarks: "Natural leather only - NO chrome-tanned"),
        MaterialPreset(laserModel: "Generic", material: "Leather", thickness: 1.0, action: "Cut", power: 40, speed: 800, passes: 1),
        MaterialPreset(laserModel: "Generic", material: "Leather", thickness: 2.0, action: "Engrave", power: 10, speed: 1800, passes: 1),
        MaterialPreset(laserModel: "Generic", material: "Leather", thickness: 2.0, action: "Cut", power: 50, speed: 600, passes: 1),
        
        // MARK: - Cardboard
        MaterialPreset(laserModel: "Generic", material: "Cardboard", thickness: 2.0, action: "Engrave", power: 8, speed: 3000, passes: 1, remarks: "Watch carefully - flammable"),
        MaterialPreset(laserModel: "Generic", material: "Cardboard", thickness: 2.0, action: "Cut", power: 30, speed: 1200, passes: 1),
        MaterialPreset(laserModel: "Generic", material: "Cardboard", thickness: 4.0, action: "Cut", power: 40, speed: 800, passes: 2),
        
        // MARK: - Cork
        MaterialPreset(laserModel: "Generic", material: "Cork", thickness: 3.0, action: "Engrave", power: 12, speed: 2200, passes: 1),
        MaterialPreset(laserModel: "Generic", material: "Cork", thickness: 3.0, action: "Cut", power: 35, speed: 900, passes: 1),
        
        // MARK: - Paper
        MaterialPreset(laserModel: "Generic", material: "Paper", thickness: 0.1, action: "Engrave", power: 5, speed: 3000, passes: 1, remarks: "Very low power - test first"),
        MaterialPreset(laserModel: "Generic", material: "Paper", thickness: 0.1, action: "Cut", power: 15, speed: 2000, passes: 1),
        MaterialPreset(laserModel: "Generic", material: "Paper", thickness: 0.3, action: "Cut", power: 20, speed: 1500, passes: 1),
        
        // MARK: - Felt
        MaterialPreset(laserModel: "Generic", material: "Felt", thickness: 3.0, action: "Cut", power: 25, speed: 1500, passes: 1, remarks: "Synthetic felt only"),
        
        // MARK: - Fabric (Cotton)
        MaterialPreset(laserModel: "Generic", material: "Fabric", thickness: 1.0, action: "Cut", power: 20, speed: 1800, passes: 1, remarks: "Cotton only - no synthetics"),
    ]
}

