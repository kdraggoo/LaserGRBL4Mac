//
//  LaserLifeView.swift
//  LaserGRBL for macOS
//
//  Laser usage statistics and life tracking
//

import SwiftUI
import Charts

struct LaserLifeView: View {
    @ObservedObject var tracker: LaserLifeTracker
    @State private var showingAddModule = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with module selector
            HStack {
                Text("Laser Life Tracking")
                    .font(.headline)
                
                Spacer()
                
                if !tracker.modules.isEmpty {
                    Picker("Module", selection: $tracker.currentModuleId) {
                        ForEach(tracker.modules) { module in
                            Text(module.name).tag(module.id as UUID?)
                        }
                    }
                    .frame(width: 200)
                }
                
                Button(action: { showingAddModule = true }) {
                    Image(systemName: "plus.circle")
                }
                .help("Add laser module")
            }
            .padding()
            
            if let module = tracker.currentModule {
                // Statistics
                statisticsView(for: module)
                
                // Power distribution chart
                powerDistributionChart(for: module)
            } else {
                emptyStateView
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingAddModule) {
            AddModuleSheet(tracker: tracker)
        }
    }
    
    // MARK: - Statistics View
    
    private func statisticsView(for module: LaserModule) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatCard(title: "Runtime", value: module.runtime.formattedDuration, color: .blue)
                StatCard(title: "Active Time", value: module.activeTime.formattedDuration, color: .green)
                StatCard(title: "Normalized", value: module.normalizedTime.formattedDuration, color: .orange)
            }
            
            HStack {
                StatCard(title: "Avg Power", value: String(format: "%.1f%%", module.averagePowerFactor * 100), color: .purple)
                StatCard(title: "Stress Time", value: module.stressTime.formattedDuration, color: .red)
                StatCard(title: "Last Used", value: formatDate(module.lastUsed), color: .secondary)
            }
        }
        .padding()
    }
    
    // MARK: - Power Distribution Chart
    
    private func powerDistributionChart(for module: LaserModule) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Power Distribution")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Chart {
                ForEach(Array(module.powerDistributionPercent.enumerated()), id: \.offset) { index, percent in
                    BarMark(
                        x: .value("Power Range", "\(index*10+1)-\(index*10+10)%"),
                        y: .value("Percentage", percent)
                    )
                    .foregroundStyle(colorForPowerClass(index))
                }
            }
            .frame(height: 200)
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .padding()
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "laser.burst")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Laser Modules")
                .font(.title2)
            
            Text("Add your first laser module to start tracking usage")
                .foregroundColor(.secondary)
            
            Button(action: { showingAddModule = true }) {
                Label("Add Laser Module", systemImage: "plus.circle")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func colorForPowerClass(_ index: Int) -> Color {
        switch index {
        case 0...2: return .green
        case 3...6: return .yellow
        case 7...8: return .orange
        default: return .red
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .bold()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Add Module Sheet

struct AddModuleSheet: View {
    @ObservedObject var tracker: LaserLifeTracker
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var model: String = ""
    @State private var power: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add Laser Module")
                .font(.title2)
                .bold()
            
            Form {
                TextField("Name", text: $name)
                    .help("Friendly name for this laser module")
                
                TextField("Brand", text: $brand)
                TextField("Model", text: $model)
                TextField("Optical Power (Watts)", text: $power)
                    .help("Rated optical output power")
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add") {
                    let module = LaserModule(
                        name: name,
                        brand: brand,
                        model: model,
                        opticalPower: Double(power),
                        purchaseDate: Date()
                    )
                    tracker.addModule(module)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 400, height: 400)
    }
}

// MARK: - Preview

#Preview {
    let tracker = LaserLifeTracker()
    return LaserLifeView(tracker: tracker)
        .frame(width: 800, height: 600)
}

