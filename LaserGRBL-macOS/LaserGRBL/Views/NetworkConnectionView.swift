//
//  NetworkConnectionView.swift
//  LaserGRBL for macOS
//
//  UI for WiFi/Network connection setup
//

import SwiftUI

struct NetworkConnectionView: View {
    @ObservedObject var networkManager: NetworkConnectionManager
    
    @State private var selectedType: ConnectionType = .websocket
    @State private var ipAddress: String = "192.168.1.100"
    @State private var port: String = "81"
    @State private var showingDiscovery = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Network Connection")
                .font(.headline)
            
            // Connection type picker
            Picker("Connection Type", selection: $selectedType) {
                ForEach(ConnectionType.allCases.filter { $0 != .usb }, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .help("Choose connection protocol: WebSocket for ESP8266 or Telnet for network controllers")
            .onChange(of: selectedType) { _, newValue in
                // Update default port based on type
                port = newValue == .websocket ? "81" : "23"
            }
            
            // IP Address
            HStack {
                Text("IP Address:")
                    .frame(width: 80, alignment: .leading)
                    .font(.caption)
                
                TextField("192.168.1.100", text: $ipAddress)
                    .textFieldStyle(.roundedBorder)
                    .help("IP address of your WiFi-enabled GRBL controller")
            }
            
            // Port
            HStack {
                Text("Port:")
                    .frame(width: 80, alignment: .leading)
                    .font(.caption)
                
                TextField("81", text: $port)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .help("Network port (WebSocket: 81, Telnet: 23)")
                
                Spacer()
            }
            
            // Quick presets
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Presets:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Button("ESP8266") {
                        selectedType = .websocket
                        port = "81"
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("ESP8266 WebSocket (default port 81)")
                    
                    Button("Telnet") {
                        selectedType = .telnet
                        port = "23"
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Standard Telnet (port 23)")
                }
            }
            
            Divider()
            
            // Connection buttons
            HStack {
                if networkManager.isConnected {
                    Button(action: {
                        networkManager.disconnect()
                    }) {
                        Label("Disconnect", systemImage: "network.slash")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    Button(action: {
                        connectToNetwork()
                    }) {
                        Label("Connect", systemImage: "network")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(ipAddress.isEmpty || port.isEmpty)
                }
                
                Button(action: { showingDiscovery = true }) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                }
                .buttonStyle(.bordered)
                .help("Discover network devices")
                .disabled(true) // Discovery not fully implemented
            }
            
            // Connection status
            if networkManager.isConnected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Connected to \(networkManager.networkAddress):\(networkManager.port)")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
            
            // Error message
            if let error = networkManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.vertical, 4)
            }
            
            // Help text
            VStack(alignment: .leading, spacing: 4) {
                Text("💡 Network Connection Guide")
                    .font(.caption)
                    .bold()
                
                Text("• WebSocket: For ESP8266-based controllers (LaserWeb, GRBL-ESP)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("• Telnet: For ESP32 or other network-enabled controllers")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("• Ensure your computer and controller are on the same network")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
            .padding(8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
        }
        .padding()
    }
    
    private func connectToNetwork() {
        guard let portNum = Int(port) else { return }
        networkManager.connect(address: ipAddress, port: portNum, type: selectedType)
    }
}

#Preview {
    let manager = NetworkConnectionManager()
    return NetworkConnectionView(networkManager: manager)
        .frame(width: 400, height: 500)
}

