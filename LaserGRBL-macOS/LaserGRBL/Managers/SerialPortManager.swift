//
//  SerialPortManager.swift
//  LaserGRBL for macOS
//
//  Manages USB serial port communication
//  Uses ORSSerialPort for serial communication
//  Ported from LaserGRBL/ComWrapper
//

import Foundation
import Combine
import ORSSerial

/// Manages serial port discovery and communication
class SerialPortManager: NSObject, ObservableObject {
    @Published var availablePorts: [ORSSerialPort] = []
    @Published var isConnected: Bool = false
    @Published var errorMessage: String?
    
    private var serialPort: ORSSerialPort?
    private var receiveBuffer: String = ""
    private let serialQueue = DispatchQueue(label: "com.lasergrbl.serial", qos: .userInitiated)
    
    // Callbacks for received data
    var onLineReceived: ((String) -> Void)?
    var onConnectionStatusChanged: ((Bool) -> Void)?
    
    // Default serial configuration
    private let defaultBaudRate = 115200
    private let dataBits = 8
    private let parity: ORSSerialPortParity = .none
    private let stopBits: UInt = 1
    
    override init() {
        super.init()
        refreshPortList()
        
        // Monitor for port changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(serialPortsWereConnected(_:)),
            name: NSNotification.Name.ORSSerialPortsWereConnected,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(serialPortsWereDisconnected(_:)),
            name: NSNotification.Name.ORSSerialPortsWereDisconnected,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        disconnect()
    }
    
    // MARK: - Port Discovery
    
    /// Refresh the list of available serial ports
    func refreshPortList() {
        DispatchQueue.main.async {
            self.availablePorts = ORSSerialPortManager.shared().availablePorts
            print("📟 Found \(self.availablePorts.count) serial ports")
            for port in self.availablePorts {
                print("  - \(port.path)")
            }
        }
    }
    
    @objc private func serialPortsWereConnected(_ notification: Notification) {
        print("📟 Serial port connected")
        refreshPortList()
    }
    
    @objc private func serialPortsWereDisconnected(_ notification: Notification) {
        print("📟 Serial port disconnected")
        refreshPortList()
        
        // Check if our current port was disconnected
        if let port = serialPort, !port.isOpen {
            DispatchQueue.main.async {
                self.isConnected = false
                self.serialPort = nil
                self.onConnectionStatusChanged?(false)
            }
        }
    }
    
    // MARK: - Connection Management
    
    /// Connect to a serial port
    func connect(to port: ORSSerialPort, baudRate: Int = 115200) {
        // Close existing connection
        disconnect()
        
        // Configure port
        serialPort = port
        port.baudRate = NSNumber(value: baudRate)
        port.numberOfDataBits = UInt(dataBits)
        port.parity = parity
        port.numberOfStopBits = stopBits
        port.usesRTSCTSFlowControl = false
        port.usesDTRDSRFlowControl = false
        port.delegate = self
        
        // Open port
        port.open()
        
        if port.isOpen {
            print("📟 Connected to \(port.path) at \(baudRate) baud")
            DispatchQueue.main.async {
                self.isConnected = true
                self.errorMessage = nil
                self.onConnectionStatusChanged?(true)
            }
        } else {
            print("📟 Failed to open \(port.path)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to open serial port"
                self.onConnectionStatusChanged?(false)
            }
        }
    }
    
    /// Disconnect from current serial port
    func disconnect() {
        guard let port = serialPort else { return }
        
        print("📟 Disconnecting from \(port.path)")
        port.close()
        port.delegate = nil
        serialPort = nil
        receiveBuffer = ""
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.onConnectionStatusChanged?(false)
        }
    }
    
    // MARK: - Data Transmission
    
    /// Send data to the serial port
    func send(_ data: String) {
        guard let port = serialPort, port.isOpen else {
            print("📟 Cannot send: port not open")
            return
        }
        
        guard let data = data.data(using: .utf8) else {
            print("📟 Cannot send: invalid UTF-8")
            return
        }
        
        port.send(data)
        print("📤 TX: \(data.count) bytes")
    }
    
    /// Send a line (adds newline if needed)
    func sendLine(_ line: String) {
        let lineToSend = line.hasSuffix("\n") ? line : line + "\n"
        send(lineToSend)
    }
    
    /// Send raw bytes
    func send(_ bytes: [UInt8]) {
        guard let port = serialPort, port.isOpen else {
            print("📟 Cannot send: port not open")
            return
        }
        
        let data = Data(bytes)
        port.send(data)
        print("📤 TX: \(bytes.count) bytes")
    }
}

// MARK: - ORSSerialPortDelegate

extension SerialPortManager: ORSSerialPortDelegate {
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        print("📟 Port opened: \(serialPort.path)")
    }
    
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        print("📟 Port closed: \(serialPort.path)")
        DispatchQueue.main.async {
            self.isConnected = false
            self.onConnectionStatusChanged?(false)
        }
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        guard let string = String(data: data, encoding: .utf8) else {
            print("📟 Received invalid UTF-8 data")
            return
        }
        
        // Add to buffer
        receiveBuffer += string
        
        // Process complete lines
        while let newlineRange = receiveBuffer.range(of: "\n") {
            let line = String(receiveBuffer[..<newlineRange.lowerBound])
            receiveBuffer.removeSubrange(...newlineRange.lowerBound)
            
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty {
                print("📥 RX: \(trimmedLine)")
                
                // Notify on main thread
                DispatchQueue.main.async {
                    self.onLineReceived?(trimmedLine)
                }
            }
        }
    }
    
    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        print("📟 Port removed from system: \(serialPort.path)")
        DispatchQueue.main.async {
            self.isConnected = false
            self.serialPort = nil
            self.errorMessage = "Serial port was disconnected"
            self.onConnectionStatusChanged?(false)
        }
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        print("📟 Serial port error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Helper Extensions

extension ORSSerialPort {
    var id: String {
        return path
    }
    
    var displayName: String {
        // name property may or may not be optional depending on ORSSerialPort version
        let portName = self.name ?? ""
        if !portName.isEmpty {
            return "\(portName) (\(path))"
        }
        return path
    }
}

