//
//  GrblController.swift
//  LaserGRBL for macOS
//
//  GRBL protocol controller - manages streaming and state
//  Ported from LaserGRBL/Core/GrblCore.cs
//

import Foundation
import Combine

/// Main controller for GRBL communication protocol
class GrblController: ObservableObject {
    // MARK: - Published Properties
    
    @Published var machineStatus: GrblStatus?
    @Published var machineState: GrblState = .unknown
    @Published var isConnected: Bool = false
    @Published var isPaused: Bool = false
    @Published var isRunning: Bool = false
    @Published var errorMessage: String?
    
    @Published var queuedCommands: [QueuedCommand] = []
    @Published var pendingCommands: [GrblCommand] = []
    @Published var consoleLog: [ConsoleEntry] = []
    
    // MARK: - Private Properties
    
    private let serialManager: SerialPortManager
    private var statusTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private let commandQueue = DispatchQueue(label: "com.lasergrbl.commands", qos: .userInitiated)
    private let maxPendingCommands = 15 // GRBL buffer size
    private let statusQueryInterval: TimeInterval = 0.2 // Query status 5 times per second
    
    // MARK: - Console Entry
    
    struct ConsoleEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let type: EntryType
        
        enum EntryType {
            case sent       // Command sent to GRBL
            case received   // Response from GRBL
            case status     // Status update
            case error      // Error message
            case info       // Info message
        }
        
        var displayText: String {
            let timeStr = timestamp.formatted(date: .omitted, time: .standard)
            return "[\(timeStr)] \(message)"
        }
    }
    
    // MARK: - Initialization
    
    init(serialManager: SerialPortManager) {
        self.serialManager = serialManager
        
        // Observe serial connection status
        serialManager.onConnectionStatusChanged = { [weak self] connected in
            self?.handleConnectionChange(connected)
        }
        
        // Observe received lines
        serialManager.onLineReceived = { [weak self] line in
            self?.handleReceivedLine(line)
        }
    }
    
    deinit {
        stopStatusQuery()
    }
    
    // MARK: - Connection Management
    
    private func handleConnectionChange(_ connected: Bool) {
        DispatchQueue.main.async {
            self.isConnected = connected
            
            if connected {
                self.log("Connected to GRBL", type: .info)
                self.startStatusQuery()
                
                // Send initial query commands
                self.sendSystemCommand(.viewBuildInfo)
                self.sendSystemCommand(.viewSettings)
            } else {
                self.log("Disconnected from GRBL", type: .info)
                self.stopStatusQuery()
                self.clearQueues()
            }
        }
    }
    
    private func startStatusQuery() {
        stopStatusQuery()
        
        statusTimer = Timer.scheduledTimer(withTimeInterval: statusQueryInterval, repeats: true) { [weak self] _ in
            self?.queryStatus()
        }
    }
    
    private func stopStatusQuery() {
        statusTimer?.invalidate()
        statusTimer = nil
    }
    
    private func queryStatus() {
        guard isConnected else { return }
        
        // Send status query (realtime command, doesn't go into queue)
        serialManager.send("?")
    }
    
    // MARK: - Command Sending
    
    /// Send a single command
    func sendCommand(_ command: GrblCommand) {
        guard isConnected else {
            log("Cannot send command: not connected", type: .error)
            return
        }
        
        commandQueue.async { [weak self] in
            self?.queueCommand(command)
            self?.processCommandQueue()
        }
    }
    
    /// Send a system command (high priority)
    func sendSystemCommand(_ command: GrblCommand) {
        guard isConnected else {
            log("Cannot send system command: not connected", type: .error)
            return
        }
        
        // System commands are sent immediately
        serialManager.send(command.serialData)
        command.markAsSent()
        
        DispatchQueue.main.async {
            self.pendingCommands.append(command)
            self.log("TX: \(command.command)", type: .sent)
        }
    }
    
    /// Queue a batch of commands (for streaming G-code)
    func queueCommands(_ commands: [GrblCommand]) {
        guard isConnected else {
            log("Cannot queue commands: not connected", type: .error)
            return
        }
        
        commandQueue.async { [weak self] in
            for command in commands {
                self?.queueCommand(command)
            }
            self?.processCommandQueue()
        }
    }
    
    /// Queue commands from a G-code file
    func queueGCodeFile(_ file: GCodeFile) {
        let commands = file.commands.map { gcodeCommand in
            GrblCommand(command: gcodeCommand.rawLine, priority: .normal)
        }
        queueCommands(commands)
    }
    
    private func queueCommand(_ command: GrblCommand) {
        let queuedCmd = QueuedCommand(command: command)
        
        DispatchQueue.main.async {
            self.queuedCommands.append(queuedCmd)
        }
    }
    
    private func processCommandQueue() {
        guard isConnected else { return }
        
        // Send commands up to the buffer limit
        while pendingCommands.count < maxPendingCommands, !queuedCommands.isEmpty {
            guard let queuedCmd = queuedCommands.first else { break }
            
            let command = queuedCmd.command
            
            // Send command
            serialManager.send(command.serialData)
            command.markAsSent()
            
            DispatchQueue.main.async {
                self.queuedCommands.removeFirst()
                self.pendingCommands.append(command)
                self.log("TX: \(command.command)", type: .sent)
            }
        }
        
        // Update running state
        DispatchQueue.main.async {
            self.isRunning = !self.queuedCommands.isEmpty || !self.pendingCommands.isEmpty
        }
    }
    
    // MARK: - Response Handling
    
    private func handleReceivedLine(_ line: String) {
        let response = GrblResponse(rawMessage: line)
        
        DispatchQueue.main.async {
            self.log("RX: \(line)", type: .received)
            
            // Handle different response types
            switch response.type {
            case .ok, .error:
                self.handleCommandResponse(response)
                
            case .position:
                self.handleStatusResponse(line)
                
            case .alarm:
                self.handleAlarm(line)
                
            case .startup:
                self.handleStartup(line)
                
            case .feedback:
                self.handleFeedback(line)
                
            default:
                self.log("Unknown response: \(line)", type: .info)
            }
        }
    }
    
    private func handleCommandResponse(_ response: GrblResponse) {
        guard !pendingCommands.isEmpty else {
            log("Received response with no pending commands", type: .error)
            return
        }
        
        // Match response to oldest pending command
        let command = pendingCommands.removeFirst()
        command.setResponse(response)
        
        if response.isError {
            log("Command error: \(response.rawMessage)", type: .error)
            errorMessage = response.rawMessage
        }
        
        // Process next commands in queue
        commandQueue.async { [weak self] in
            self?.processCommandQueue()
        }
    }
    
    private func handleStatusResponse(_ line: String) {
        guard let status = GrblStatus(rawMessage: line) else {
            log("Failed to parse status: \(line)", type: .error)
            return
        }
        
        machineStatus = status
        machineState = status.state
    }
    
    private func handleAlarm(_ line: String) {
        log("ALARM: \(line)", type: .error)
        errorMessage = line
        machineState = .alarm
    }
    
    private func handleStartup(_ line: String) {
        log("GRBL Startup: \(line)", type: .info)
    }
    
    private func handleFeedback(_ line: String) {
        log("Feedback: \(line)", type: .info)
    }
    
    // MARK: - Control Commands
    
    /// Pause execution (feed hold)
    func pause() {
        guard isConnected, !isPaused else { return }
        
        serialManager.send("!")
        isPaused = true
        log("Feed hold sent", type: .info)
    }
    
    /// Resume execution
    func resume() {
        guard isConnected, isPaused else { return }
        
        serialManager.send("~")
        isPaused = false
        log("Resume sent", type: .info)
    }
    
    /// Stop execution (soft reset)
    func stop() {
        guard isConnected else { return }
        
        serialManager.send("\u{18}") // Ctrl-X
        clearQueues()
        isPaused = false
        log("Soft reset sent", type: .info)
    }
    
    /// Clear alarm state
    func clearAlarm() {
        sendSystemCommand(.unlock)
    }
    
    /// Home the machine
    func home() {
        sendSystemCommand(.home)
    }
    
    /// Zero work position
    func zeroWorkPosition() {
        sendCommand(.zeroWorkPosition)
    }
    
    /// Go to work zero
    func goToWorkZero() {
        sendCommand(.goToWorkZero)
    }
    
    /// Jog the machine
    func jog(x: Double? = nil, y: Double? = nil, z: Double? = nil, feedRate: Double = 1000) {
        guard isConnected else { return }
        let jogCommand = GrblCommand.jog(x: x, y: y, z: z, feedRate: feedRate)
        sendSystemCommand(jogCommand)
    }
    
    // MARK: - Queue Management
    
    private func clearQueues() {
        DispatchQueue.main.async {
            self.queuedCommands.removeAll()
            self.pendingCommands.removeAll()
            self.isRunning = false
        }
    }
    
    func clearConsole() {
        DispatchQueue.main.async {
            self.consoleLog.removeAll()
        }
    }
    
    // MARK: - Logging
    
    private func log(_ message: String, type: ConsoleEntry.EntryType) {
        let entry = ConsoleEntry(timestamp: Date(), message: message, type: type)
        
        DispatchQueue.main.async {
            self.consoleLog.append(entry)
            
            // Limit console log size
            if self.consoleLog.count > 1000 {
                self.consoleLog.removeFirst(100)
            }
        }
    }
}

