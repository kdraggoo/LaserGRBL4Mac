//
//  LaserGRBLApp.swift
//  LaserGRBL for macOS
//
//  Created as a native macOS port of LaserGRBL
//  Original Windows version: https://github.com/arkypita/LaserGRBL
//

import SwiftUI

@main
struct LaserGRBLApp: App {
    @StateObject private var fileManager = GCodeFileManager()
    @StateObject private var serialManager = SerialPortManager()
    @StateObject private var grblController: GrblController
    
    init() {
        // Initialize serial manager first
        let serial = SerialPortManager()
        _serialManager = StateObject(wrappedValue: serial)
        
        // Initialize GRBL controller with serial manager
        _grblController = StateObject(wrappedValue: GrblController(serialManager: serial))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fileManager)
                .environmentObject(serialManager)
                .environmentObject(grblController)
                .frame(minWidth: 1200, minHeight: 700)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open G-Code...") {
                    fileManager.openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Save") {
                    fileManager.saveFile()
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(fileManager.currentFile == nil)

                Button("Save As...") {
                    fileManager.saveFileAs()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(fileManager.currentFile == nil)
            }
        }
    }
}
