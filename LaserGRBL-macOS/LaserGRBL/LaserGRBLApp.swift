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
    @State private var showingHelp = false
    @State private var showingMaterialDatabase = false
    @StateObject private var fileManager = GCodeFileManager()
    @StateObject private var serialManager = SerialPortManager()
    @StateObject private var grblController: GrblController
    @StateObject private var imageImporter = ImageImporter()
    @StateObject private var rasterConverter = RasterConverter()
    @StateObject private var svgImporter = SVGImporter()
    @StateObject private var pathConverter = PathToGCodeConverter()
    @StateObject private var settingsManager = GrblSettingsManager()
    @StateObject private var materialDatabase = MaterialDatabase()
    @StateObject private var customButtonManager = CustomButtonManager()
    
    init() {
        // Initialize serial manager first
        let serial = SerialPortManager()
        _serialManager = StateObject(wrappedValue: serial)
        
        // Initialize settings manager
        let settings = GrblSettingsManager()
        _settingsManager = StateObject(wrappedValue: settings)
        
        // Initialize GRBL controller with serial manager and settings
        let controller = GrblController(serialManager: serial)
        controller.settingsManager = settings
        _grblController = StateObject(wrappedValue: controller)
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
                .environmentObject(settingsManager)
                .environmentObject(customButtonManager)
                .frame(minWidth: 1200, minHeight: 700)
                .sheet(isPresented: $showingHelp) {
                    HelpMenuView()
                }
                .sheet(isPresented: $showingMaterialDatabase) {
                    MaterialDatabaseView(database: materialDatabase)
                }
        }
        .commands {
            // Tools menu
            CommandMenu("Tools") {
                Button("Material Database...") {
                    showingMaterialDatabase = true
                }
                .keyboardShortcut("m", modifiers: .command)
            }
            
            // Help menu
            CommandGroup(replacing: .help) {
                Button("LaserGRBL Help") {
                    showingHelp = true
                }
                .keyboardShortcut("?", modifiers: .command)
                
                Divider()
                
                Button("Material Guide") {
                    showingHelp = true
                }
                
                Button("Error & Alarm Codes") {
                    showingHelp = true
                }
                
                Button("Keyboard Shortcuts") {
                    showingHelp = true
                }
            }
            
            // File menu
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
