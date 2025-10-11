//
//  ControlPanelView.swift
//  LaserGRBL for macOS
//
//  Machine control interface (jog, home, zero, etc.)
//

import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var grblController: GrblController
    
    @State private var jogDistance: Double = 10.0
    @State private var jogFeedRate: Double = 1000.0
    
    let jogDistances: [Double] = [0.1, 1.0, 10.0, 100.0]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "gamecontroller")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("Control Panel")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            // Jog controls
            jogControlsView
            
            Divider()
            
            // System controls
            systemControlsView
            
            Divider()
            
            // Execution controls
            executionControlsView
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 300, idealWidth: 350)
        .disabled(!grblController.isConnected)
    }
    
    // MARK: - Jog Controls
    
    private var jogControlsView: some View {
        VStack(spacing: 12) {
            Text("Jog Controls")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Distance selector
            Picker("Jog Distance", selection: $jogDistance) {
                ForEach(jogDistances, id: \.self) { distance in
                    Text(formatJogDistance(distance)).tag(distance)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            
            // XY Jog pad
            VStack(spacing: 8) {
                // Y+
                Button(action: { jog(y: jogDistance) }) {
                    Image(systemName: "arrow.up")
                        .frame(width: 60, height: 40)
                }
                .buttonStyle(.bordered)
                
                HStack(spacing: 8) {
                    // X-
                    Button(action: { jog(x: -jogDistance) }) {
                        Image(systemName: "arrow.left")
                            .frame(width: 60, height: 40)
                    }
                    .buttonStyle(.bordered)
                    
                    // Home
                    Button(action: { goHome() }) {
                        Image(systemName: "house")
                            .frame(width: 60, height: 40)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // X+
                    Button(action: { jog(x: jogDistance) }) {
                        Image(systemName: "arrow.right")
                            .frame(width: 60, height: 40)
                    }
                    .buttonStyle(.bordered)
                }
                
                // Y-
                Button(action: { jog(y: -jogDistance) }) {
                    Image(systemName: "arrow.down")
                        .frame(width: 60, height: 40)
                }
                .buttonStyle(.bordered)
            }
            
            // Z controls
            HStack(spacing: 8) {
                Button(action: { jog(z: jogDistance) }) {
                    Label("Z+", systemImage: "arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: { jog(z: -jogDistance) }) {
                    Label("Z-", systemImage: "arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            // Feed rate
            VStack(alignment: .leading, spacing: 4) {
                Text("Feed Rate: \(Int(jogFeedRate)) mm/min")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(value: $jogFeedRate, in: 100...3000, step: 100)
            }
        }
    }
    
    // MARK: - System Controls
    
    private var systemControlsView: some View {
        VStack(spacing: 8) {
            Text("System")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Button(action: {
                    grblController.home()
                }) {
                    Label("Home", systemImage: "house.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    grblController.zeroWorkPosition()
                }) {
                    Label("Zero XY", systemImage: "scope")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            HStack(spacing: 8) {
                Button(action: {
                    grblController.goToWorkZero()
                }) {
                    Label("Go to Zero", systemImage: "target")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    grblController.clearAlarm()
                }) {
                    Label("Clear Alarm", systemImage: "exclamationmark.triangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
    }
    
    // MARK: - Execution Controls
    
    private var executionControlsView: some View {
        VStack(spacing: 12) {
            Text("Execution")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Queue status
            if grblController.isRunning {
                VStack(spacing: 4) {
                    ProgressView(value: progressValue) {
                        HStack {
                            Text("Running")
                                .font(.caption)
                            Spacer()
                            Text("\(completedCommands) / \(totalCommands)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if grblController.isPaused {
                        Label("Paused", systemImage: "pause.circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Control buttons
            HStack(spacing: 8) {
                if grblController.isPaused {
                    Button(action: {
                        grblController.resume()
                    }) {
                        Label("Resume", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    Button(action: {
                        grblController.pause()
                    }) {
                        Label("Pause", systemImage: "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!grblController.isRunning)
                }
                
                Button(action: {
                    grblController.stop()
                }) {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!grblController.isRunning)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var totalCommands: Int {
        return grblController.queuedCommands.count + grblController.pendingCommands.count
    }
    
    private var completedCommands: Int {
        // Calculate based on initial total (would need to track this)
        return grblController.pendingCommands.count
    }
    
    private var progressValue: Double {
        guard totalCommands > 0 else { return 0 }
        return Double(completedCommands) / Double(totalCommands)
    }
    
    // MARK: - Helper Methods
    
    private func formatJogDistance(_ distance: Double) -> String {
        if distance < 1 {
            return String(format: "%.1f mm", distance)
        } else {
            return String(format: "%.0f mm", distance)
        }
    }
    
    private func jog(x: Double? = nil, y: Double? = nil, z: Double? = nil) {
        grblController.jog(x: x, y: y, z: z, feedRate: jogFeedRate)
    }
    
    private func goHome() {
        grblController.goToWorkZero()
    }
}

#Preview {
    let serialManager = SerialPortManager()
    let grblController = GrblController(serialManager: serialManager)
    
    return ControlPanelView(grblController: grblController)
        .frame(width: 350, height: 600)
}

