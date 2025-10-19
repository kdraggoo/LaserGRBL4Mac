//
//  VectorSettingsView.swift
//  LaserGRBL
//
//  Phase 4: SVG Vector Import
//  Created on October 19, 2025
//

import SwiftUI

/// Settings panel for vector conversion
struct VectorSettingsView: View {
    @ObservedObject var settings: VectorSettings
    
    @State private var selectedPreset: VectorPreset?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("Vector Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 4)
                
                // Presets
                presetsSection
                
                Divider()
                
                // Conversion settings
                conversionSection
                
                Divider()
                
                // Laser settings
                laserSection
                
                Divider()
                
                // Path optimization
                optimizationSection
                
                Divider()
                
                // Advanced settings
                advancedSection
                
                // Extra bottom padding to ensure last items are fully visible
                Color.clear.frame(height: 20)
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Presets Section
    
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Presets", systemImage: "slider.horizontal.3")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(VectorPreset.presets) { preset in
                    PresetButton(
                        preset: preset,
                        isSelected: selectedPreset?.id == preset.id
                    ) {
                        selectPreset(preset)
                    }
                }
            }
        }
    }
    
    // MARK: - Conversion Section
    
    private var conversionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Conversion", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Tolerance
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Tolerance")
                        Spacer()
                        Text(String(format: "%.2f mm", settings.tolerance))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                    
                    Slider(value: $settings.tolerance, in: 0.01...1.0, step: 0.01)
                    
                    Text("Lower = more accurate, more points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Units
                Picker("Units", selection: $settings.units) {
                    ForEach(VectorSettings.Units.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    // MARK: - Laser Section
    
    private var laserSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Laser Settings", systemImage: "laser.burst")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Feed Rate
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Feed Rate")
                        Spacer()
                        Text("\(settings.feedRate) mm/min")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                    
                    Slider(value: Binding(
                        get: { Double(settings.feedRate) },
                        set: { settings.feedRate = Int($0) }
                    ), in: 100...5000, step: 50)
                }
                
                // Laser Power
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Laser Power")
                        Spacer()
                        Text("S\(settings.laserPower)")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                    
                    Slider(value: Binding(
                        get: { Double(settings.laserPower) },
                        set: { settings.laserPower = Int($0) }
                    ), in: 0...1000, step: 10)
                }
                
                // Passes
                Stepper("Passes: \(settings.passes)", value: $settings.passes, in: 1...10)
                
                if settings.passes > 1 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Pass Depth")
                            Spacer()
                            Text(String(format: "%.2f mm", settings.passDepth))
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                        
                        Slider(value: $settings.passDepth, in: 0.1...2.0, step: 0.1)
                    }
                }
            }
        }
    }
    
    // MARK: - Optimization Section
    
    private var optimizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Optimization", systemImage: "speedometer")
                .font(.headline)
            
            VStack(spacing: 8) {
                Toggle("Optimize Path Order", isOn: $settings.optimizeOrder)
                    .help("Minimize travel distance between paths")
                
                Toggle("Minimize Travel Moves", isOn: $settings.minimizeTravel)
                    .help("Reduce rapid movements")
                
                Toggle("Start from Origin", isOn: $settings.startFromOrigin)
                    .help("Begin cutting from (0,0)")
            }
        }
    }
    
    // MARK: - Advanced Section
    
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Advanced", systemImage: "gearshape.2")
                .font(.headline)
            
            VStack(spacing: 8) {
                Toggle("Use Arc Commands (G2/G3)", isOn: $settings.useArcCommands)
                    .help("Generate arc commands for smoother curves")
                
                if settings.useArcCommands {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Arc Tolerance")
                            Spacer()
                            Text(String(format: "%.3f mm", settings.arcTolerance))
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                        
                        Slider(value: $settings.arcTolerance, in: 0.01...0.5, step: 0.01)
                    }
                }
                
                Toggle("Enable Z-Axis", isOn: $settings.enableZAxis)
                    .help("Add Z-axis movements for 3D work")
                
                if settings.enableZAxis {
                    VStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Safe Height")
                                Spacer()
                                Text(String(format: "%.1f mm", settings.zSafeHeight))
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                            .font(.subheadline)
                            
                            Slider(value: $settings.zSafeHeight, in: 0...20, step: 0.5)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Cut Height")
                                Spacer()
                                Text(String(format: "%.1f mm", settings.zCutHeight))
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                            .font(.subheadline)
                            
                            Slider(value: $settings.zCutHeight, in: -10...10, step: 0.5)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func selectPreset(_ preset: VectorPreset) {
        withAnimation {
            selectedPreset = preset
            settings.applyPreset(preset)
        }
    }
}

// MARK: - Preset Button

private struct PresetButton: View {
    let preset: VectorPreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                    
                    Text(preset.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(10)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VectorSettingsView(settings: VectorSettings())
        .frame(width: 320, height: 700)
}

