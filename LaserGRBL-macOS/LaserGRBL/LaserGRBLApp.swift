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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fileManager)
                .frame(minWidth: 900, minHeight: 600)
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
