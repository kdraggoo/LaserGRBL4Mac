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
    
    // Override controls (GRBL v1.1)
    @Published var feedOverride: Int = 100
    @Published var spindleOverride: Int = 100
    @Published var rapidOverride: Int = 100
    
    // Settings management
    var settingsManager: GrblSettingsManager?
    private var settingsResponseBuffer: [String] = []
    private var isReadingSettings = false
    
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
                
            case .config:
                self.handleSettingResponse(line)
                
            default:
                self.log("Unknown response: \(line)", type: .info)
            }
        }
    }
    
    private func handleCommandResponse(_ response: GrblResponse) {
        guard !pendingCommands.isEmpty else {
            // If reading settings and get OK, finalize
            if isReadingSettings && response.isSuccess {
                finalizeSettingsRead()
            } else {
                log("Received response with no pending commands", type: .error)
            }
            return
        }
        
        // Match response to oldest pending command
        let command = pendingCommands.removeFirst()
        command.setResponse(response)
        
        // If reading settings and got OK for $$ command, finalize
        if isReadingSettings && response.isSuccess && command.command.contains("$$") {
            finalizeSettingsRead()
        }
        
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
        
        // Update override values from status
        if let feedOv = status.feedOverride {
            feedOverride = feedOv
        }
        if let spindleOv = status.spindleOverride {
            spindleOverride = spindleOv
        }
        if let rapidOv = status.rapidOverride {
            rapidOverride = rapidOv
        }
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
    
    private func handleSettingResponse(_ line: String) {
        // Setting format: $0=10
        guard isReadingSettings else { return }
        
        settingsResponseBuffer.append(line)
        
        // Check if we received "ok" which signals end of settings dump
        // Note: The "ok" comes as a separate response, so we check pending commands
    }
    
    private func finalizeSettingsRead() {
        guard isReadingSettings, let settingsManager = settingsManager else { return }
        
        // Parse all buffered settings
        settingsManager.parseSettings(from: settingsResponseBuffer)
        
        settingsResponseBuffer.removeAll()
        isReadingSettings = false
        
        DispatchQueue.main.async {
            settingsManager.isLoading = false
        }
        
        log("Settings read complete: \(settingsManager.settings.count) settings loaded", type: .info)
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
    
    // MARK: - Override Commands
    
    /// GRBL v1.1 realtime override command bytes
    enum OverrideCommand: UInt8 {
        // Feed rate overrides
        case feedReset = 0x90       // 144 - Reset to 100%
        case feedPlus10 = 0x91      // 145 - Increase 10%
        case feedMinus10 = 0x92     // 146 - Decrease 10%
        case feedPlus1 = 0x93       // 147 - Increase 1%
        case feedMinus1 = 0x94      // 148 - Decrease 1%
        
        // Rapid rate overrides
        case rapidReset = 0x95      // 149 - Reset to 100%
        case rapid50 = 0x96         // 150 - Set to 50%
        case rapid25 = 0x97         // 151 - Set to 25%
        
        // Spindle/laser overrides
        case spindleReset = 0x99    // 153 - Reset to 100%
        case spindlePlus10 = 0x9A   // 154 - Increase 10%
        case spindleMinus10 = 0x9B  // 155 - Decrease 10%
        case spindlePlus1 = 0x9C    // 156 - Increase 1%
        case spindleMinus1 = 0x9D   // 157 - Decrease 1%
    }
    
    /// Set feed rate override (10-200%)
    func setFeedOverride(_ percent: Int) {
        guard isConnected else { return }
        let clamped = min(max(percent, 10), 200)
        
        // Send appropriate override commands to reach target
        sendOverrideCommands(current: feedOverride, target: clamped, type: .feed)
    }
    
    /// Set spindle/laser power override (10-200%)
    func setSpindleOverride(_ percent: Int) {
        guard isConnected else { return }
        let clamped = min(max(percent, 10), 200)
        
        sendOverrideCommands(current: spindleOverride, target: clamped, type: .spindle)
    }
    
    /// Set rapid rate override (25%, 50%, or 100%)
    func setRapidOverride(_ percent: Int) {
        guard isConnected else { return }
        
        let command: OverrideCommand
        if percent <= 25 {
            command = .rapid25
        } else if percent <= 50 {
            command = .rapid50
        } else {
            command = .rapidReset
        }
        
        sendOverrideByte(command)
        log("Rapid override: \(percent)%", type: .info)
    }
    
    /// Send override commands to reach target percentage
    private func sendOverrideCommands(current: Int, target: Int, type: OverrideType) {
        var currentValue = current
        
        // Reset to 100% first if it's more efficient
        let diff = target - currentValue
        if abs(diff) > 20 {
            let resetCommand: OverrideCommand = type == .feed ? .feedReset : .spindleReset
            sendOverrideByte(resetCommand)
            currentValue = 100
        }
        
        // Apply coarse adjustments (±10%)
        let (plus10, minus10) = type == .feed ? 
            (OverrideCommand.feedPlus10, OverrideCommand.feedMinus10) :
            (OverrideCommand.spindlePlus10, OverrideCommand.spindleMinus10)
        
        while currentValue + 10 <= target {
            sendOverrideByte(plus10)
            currentValue += 10
        }
        
        while currentValue - 10 >= target {
            sendOverrideByte(minus10)
            currentValue -= 10
        }
        
        // Apply fine adjustments (±1%)
        let (plus1, minus1) = type == .feed ?
            (OverrideCommand.feedPlus1, OverrideCommand.feedMinus1) :
            (OverrideCommand.spindlePlus1, OverrideCommand.spindleMinus1)
        
        while currentValue < target {
            sendOverrideByte(plus1)
            currentValue += 1
        }
        
        while currentValue > target {
            sendOverrideByte(minus1)
            currentValue -= 1
        }
        
        let typeName = type == .feed ? "Feed" : "Spindle"
        log("\(typeName) override: \(target)%", type: .info)
    }
    
    /// Send a single override command byte
    private func sendOverrideByte(_ command: OverrideCommand) {
        serialManager.send([command.rawValue])
    }
    
    private enum OverrideType {
        case feed, spindle
    }
    
    // MARK: - Resume & Run from Position
    
    /// Resume job from a specific line number
    func resumeFromLine(_ lineNumber: Int) {
        guard isConnected else {
            log("Cannot resume: not connected", type: .error)
            return
        }
        
        guard lineNumber >= 0 && lineNumber < queuedCommands.count else {
            log("Invalid line number for resume", type: .error)
            return
        }
        
        // Remove commands before the resume point
        let commandsToRemove = lineNumber
        if commandsToRemove > 0 {
            queuedCommands.removeFirst(commandsToRemove)
        }
        
        log("Resuming from line \(lineNumber)", type: .info)
        
        // Resume if paused
        if isPaused {
            resume()
        }
    }
    
    /// Run from a specific position in the G-code
    func runFromPosition(_ lineNumber: Int, syncPosition: Bool = false) {
        guard isConnected else {
            log("Cannot run from position: not connected", type: .error)
            return
        }
        
        // If sync position requested, send current position as work zero
        if syncPosition {
            sendSystemCommand(.zeroWorkPosition)
            log("Synced position before resume", type: .info)
        }
        
        // Resume from the specified line
        resumeFromLine(lineNumber)
    }
    
    /// Verify machine position matches expected
    func verifyPosition() -> Bool {
        guard let status = machineStatus else { return false }
        
        // In a full implementation, this would compare current position
        // with the expected position for the resume point
        // For now, just check that we have valid position data
        return status.workPosition != nil || status.machinePosition != nil
    }
    
    // MARK: - Settings Management
    
    /// Read all settings from GRBL controller
    func readSettings() {
        guard isConnected, let settingsManager = settingsManager else {
            log("Cannot read settings: not connected or no settings manager", type: .error)
            return
        }
        
        settingsResponseBuffer.removeAll()
        isReadingSettings = true
        
        DispatchQueue.main.async {
            settingsManager.isLoading = true
        }
        
        // Send $$ command to request all settings
        sendSystemCommand(.viewSettings)
        log("Reading settings from controller...", type: .info)
    }
    
    /// Write a single setting to GRBL controller
    func writeSetting(id: Int, value: Double) {
        guard isConnected else {
            log("Cannot write setting: not connected", type: .error)
            return
        }
        
        let command = GrblCommand(command: "$\(id)=\(value)", priority: .system)
        sendSystemCommand(command)
        log("Writing setting $\(id)=\(value)", type: .info)
    }
    
    /// Write all settings to GRBL controller
    func writeAllSettings(_ settings: [GrblSetting]) {
        guard isConnected else {
            log("Cannot write settings: not connected", type: .error)
            return
        }
        
        log("Writing \(settings.count) settings to controller...", type: .info)
        
        for setting in settings {
            writeSetting(id: setting.id, value: setting.value)
            // Small delay between commands to prevent buffer overflow
            Thread.sleep(forTimeInterval: 0.05)
        }
        
        log("All settings written", type: .info)
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

