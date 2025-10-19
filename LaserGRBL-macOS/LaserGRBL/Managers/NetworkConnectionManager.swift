//
//  NetworkConnectionManager.swift
//  LaserGRBL for macOS
//
//  Network connectivity for ESP8266/WiFi GRBL controllers
//  Ported from LaserGRBL/ComWrapper/LaserWebESP8266.cs
//

import Foundation
import Combine
import Network

/// Network device discovered on the network
struct NetworkDevice: Identifiable {
    let id = UUID()
    let name: String
    let ipAddress: String
    let port: Int
    let type: ConnectionType
}

/// Connection type
enum ConnectionType: String, CaseIterable {
    case usb = "USB Serial"
    case websocket = "WebSocket"
    case telnet = "Telnet"
    
    var icon: String {
        switch self {
        case .usb: return "cable.connector"
        case .websocket: return "network"
        case .telnet: return "terminal"
        }
    }
}

/// Manager for network connections to GRBL controllers
class NetworkConnectionManager: ObservableObject {
    @Published var connectionType: ConnectionType = .usb
    @Published var networkAddress: String = ""
    @Published var port: Int = 23
    @Published var isConnected: Bool = false
    @Published var discoveredDevices: [NetworkDevice] = []
    @Published var errorMessage: String?
    
    private var connection: NWConnection?
    private var listener: NWListener?
    
    var onConnectionStatusChanged: ((Bool) -> Void)?
    var onLineReceived: ((String) -> Void)?
    
    // MARK: - Connection Management
    
    /// Connect to network device
    func connect(address: String, port: Int, type: ConnectionType) {
        disconnect()
        
        self.networkAddress = address
        self.port = port
        self.connectionType = type
        
        switch type {
        case .websocket:
            connectWebSocket(address: address, port: port)
        case .telnet:
            connectTelnet(address: address, port: port)
        case .usb:
            // USB handled by SerialPortManager
            break
        }
    }
    
    /// Disconnect from current connection
    func disconnect() {
        connection?.cancel()
        connection = nil
        
        isConnected = false
        onConnectionStatusChanged?(false)
    }
    
    // MARK: - WebSocket Connection
    
    private func connectWebSocket(address: String, port: Int) {
        // WebSocket connection to ESP8266 (e.g., ws://192.168.1.100:81/)
        guard let url = URL(string: "ws://\(address):\(port)/") else {
            errorMessage = "Invalid WebSocket URL"
            return
        }
        
        // Create WebSocket connection
        let parameters = NWParameters.tls
        let options = NWProtocolWebSocket.Options()
        parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)
        
        let endpoint = NWEndpoint.url(url)
        
        connection = NWConnection(to: endpoint, using: parameters)
        setupConnectionHandlers()
        connection?.start(queue: .main)
    }
    
    // MARK: - Telnet Connection
    
    private func connectTelnet(address: String, port: Int) {
        let host = NWEndpoint.Host(address)
        let portEndpoint = NWEndpoint.Port(integerLiteral: UInt16(port))
        
        connection = NWConnection(host: host, port: portEndpoint, using: .tcp)
        setupConnectionHandlers()
        connection?.start(queue: .main)
    }
    
    // MARK: - Connection Handlers
    
    private func setupConnectionHandlers() {
        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.isConnected = true
                self?.onConnectionStatusChanged?(true)
                self?.receiveData()
                
            case .failed(let error):
                self?.errorMessage = "Connection failed: \(error.localizedDescription)"
                self?.isConnected = false
                self?.onConnectionStatusChanged?(false)
                
            case .cancelled:
                self?.isConnected = false
                self?.onConnectionStatusChanged?(false)
                
            default:
                break
            }
        }
    }
    
    // MARK: - Data Transfer
    
    /// Send data over network connection
    func send(_ data: String) {
        guard isConnected, let connection = connection else {
            return
        }
        
        let content = data.data(using: .utf8)!
        connection.send(content: content, completion: .contentProcessed({ error in
            if let error = error {
                print("Send error: \(error)")
            }
        }))
    }
    
    /// Send raw bytes
    func send(_ bytes: [UInt8]) {
        guard isConnected, let connection = connection else {
            return
        }
        
        let data = Data(bytes)
        connection.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                print("Send error: \(error)")
            }
        }))
    }
    
    private func receiveData() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            if let data = content, !data.isEmpty {
                if let string = String(data: data, encoding: .utf8) {
                    // Split by newlines and send each line
                    let lines = string.components(separatedBy: .newlines)
                    for line in lines where !line.isEmpty {
                        self?.onLineReceived?(line)
                    }
                }
            }
            
            if let error = error {
                print("Receive error: \(error)")
                self?.disconnect()
                return
            }
            
            if !isComplete {
                self?.receiveData()
            }
        }
    }
    
    // MARK: - Device Discovery
    
    /// Discover network devices (simplified)
    func discoverDevices() {
        // In a real implementation, this would use mDNS/Bonjour discovery
        // For now, we'll provide a manual entry method
        
        // In production, implement proper mDNS discovery here
        // Example devices would be:
        // - NetworkDevice(name: "ESP8266-GRBL", ipAddress: "192.168.1.100", port: 81, type: .websocket)
        // - NetworkDevice(name: "ESP32-Telnet", ipAddress: "192.168.1.101", port: 23, type: .telnet)
        
        discoveredDevices = [] // Leave empty for manual entry
    }
}

