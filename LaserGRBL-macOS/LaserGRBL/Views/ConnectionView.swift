//
//  ConnectionView.swift
//  LaserGRBL for macOS
//
//  Serial port connection interface
//

import SwiftUI
import ORSSerial

struct ConnectionView: View {
    @ObservedObject var serialManager: SerialPortManager
    @ObservedObject var grblController: GrblController
    
    @State private var selectedPort: ORSSerialPort?
    @State private var baudRate: Int = 115200
    @State private var showingPortSelection = false
    
    let commonBaudRates = [9600, 19200, 38400, 57600, 115200, 230400, 250000]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "cable.connector")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("Connection")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            // Connection status
            if serialManager.isConnected {
                connectedView
            } else {
                disconnectedView
            }
            
            // Machine status
            if grblController.isConnected {
                machineStatusView
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 300, idealWidth: 350)
        .onAppear {
            serialManager.refreshPortList()
        }
    }
    
    // MARK: - Connected View
    
    private var connectedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Connected", systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.headline)
            
            if let port = serialManager.availablePorts.first(where: { $0.isOpen }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Port: \(port.path)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Baud Rate: \(baudRate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                serialManager.disconnect()
            }) {
                Label("Disconnect", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
        )
    }
    
    // MARK: - Disconnected View
    
    private var disconnectedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Not Connected", systemImage: "xmark.circle")
                .foregroundColor(.secondary)
                .font(.headline)
            
            // Port selection
            Picker("Serial Port", selection: $selectedPort) {
                Text("Select Port...").tag(nil as ORSSerialPort?)
                ForEach(serialManager.availablePorts, id: \.path) { port in
                    Text(port.displayName).tag(port as ORSSerialPort?)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            
            // Baud rate selection
            Picker("Baud Rate", selection: $baudRate) {
                ForEach(commonBaudRates, id: \.self) { rate in
                    Text("\(rate)").tag(rate)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            
            // Refresh button
            Button(action: {
                serialManager.refreshPortList()
            }) {
                Label("Refresh Ports", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            // Connect button
            Button(action: {
                connect()
            }) {
                Label("Connect", systemImage: "cable.connector")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedPort == nil)
            
            if let error = serialManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
    }
    
    // MARK: - Machine Status View
    
    private var machineStatusView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "laptopcomputer")
                Text("Machine Status")
                    .font(.headline)
            }
            
            Divider()
            
            // State
            HStack {
                Text("State:")
                    .foregroundColor(.secondary)
                Spacer()
                stateIndicator
            }
            
            // Position
            if let status = grblController.machineStatus {
                VStack(spacing: 8) {
                    if let mPos = status.machinePosition {
                        positionRow(label: "Machine Pos", position: mPos)
                    }
                    
                    if let wPos = status.workPosition {
                        positionRow(label: "Work Pos", position: wPos)
                    }
                    
                    if let feed = status.feedRate {
                        HStack {
                            Text("Feed Rate:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f mm/min", feed))
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    
                    if let spindle = status.spindleSpeed {
                        HStack {
                            Text("Spindle:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f RPM", spindle))
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    private func positionRow(label: String, position: GrblStatus.Position) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(position.description)
                .font(.system(.caption, design: .monospaced))
        }
    }
    
    private var stateIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(stateColor)
                .frame(width: 8, height: 8)
            
            Text(grblController.machineState.rawValue)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(stateColor)
        }
    }
    
    private var stateColor: Color {
        switch grblController.machineState {
        case .idle:
            return .green
        case .run:
            return .blue
        case .hold:
            return .orange
        case .alarm:
            return .red
        case .door:
            return .yellow
        case .check, .home:
            return .purple
        default:
            return .secondary
        }
    }
    
    // MARK: - Actions
    
    private func connect() {
        guard let port = selectedPort else { return }
        serialManager.connect(to: port, baudRate: baudRate)
    }
}

#Preview {
    let serialManager = SerialPortManager()
    let grblController = GrblController(serialManager: serialManager)
    
    return ConnectionView(
        serialManager: serialManager,
        grblController: grblController
    )
    .frame(width: 350, height: 600)
}

