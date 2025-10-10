//
//  GCodeFileManager.swift
//  LaserGRBL for macOS
//
//  Manages file operations and current file state
//

import Foundation
import Combine
import SwiftUI
import AppKit
import UniformTypeIdentifiers

class GCodeFileManager: ObservableObject {
    @Published var currentFile: GCodeFile?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Supported file types
    static let supportedTypes: [UTType] = [
        UTType(filenameExtension: "gcode")!,
        UTType(filenameExtension: "nc")!,
        UTType(filenameExtension: "tap")!,
        UTType(filenameExtension: "txt")!
    ]
    
    // MARK: - File Operations
    
    /// Open a G-code file using file picker
    func openFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = Self.supportedTypes
        panel.message = "Select a G-code file to open"
        
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.loadFile(url: url)
        }
    }
    
    /// Load a G-code file from URL
    func loadFile(url: URL) {
        Task {
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            do {
                let file = GCodeFile(filePath: url)
                try await file.load(from: url)
                
                await MainActor.run {
                    self.currentFile = file
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load file: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Save the current file
    func saveFile() {
        guard let file = currentFile else { return }
        
        if let existingPath = file.filePath {
            // Save to existing location
            do {
                try file.save(to: existingPath)
            } catch {
                self.errorMessage = "Failed to save file: \(error.localizedDescription)"
            }
        } else {
            // Show save panel for new file
            saveFileAs()
        }
    }
    
    /// Save the current file to a new location
    func saveFileAs() {
        guard let file = currentFile else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "gcode")!]
        panel.nameFieldStringValue = file.fileName + ".gcode"
        panel.message = "Save G-code file"
        
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                try file.save(to: url)
            } catch {
                self?.errorMessage = "Failed to save file: \(error.localizedDescription)"
            }
        }
    }
    
    /// Create a new empty file
    func newFile() {
        let file = GCodeFile()
        file.fileName = "Untitled"
        self.currentFile = file
    }
    
    /// Close the current file
    func closeFile() {
        // TODO: Check for unsaved changes
        currentFile = nil
    }
}

