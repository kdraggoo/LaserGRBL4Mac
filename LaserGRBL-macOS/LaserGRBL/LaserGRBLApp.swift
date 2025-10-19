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
    @StateObject private var imageImporter = ImageImporter()
    @StateObject private var rasterConverter = RasterConverter()
    @StateObject private var svgImporter = SVGImporter()
    @StateObject private var pathConverter = PathToGCodeConverter()
    
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
                .environmentObject(imageImporter)
                .environmentObject(rasterConverter)
                .environmentObject(svgImporter)
                .environmentObject(pathConverter)
                .frame(minWidth: 1200, minHeight: 700)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open G-Code...") {
                    fileManager.openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Import SVG...") {
                    Task {
                        await svgImporter.importSVG()
                    }
                }
                .keyboardShortcut("v", modifiers: .command)
                
                Button("Import Image...") {
                    Task {
                        await imageImporter.importImage()
                    }
                }
                .keyboardShortcut("i", modifiers: .command)
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
