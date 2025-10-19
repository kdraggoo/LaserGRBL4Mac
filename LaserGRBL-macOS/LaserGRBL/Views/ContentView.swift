//
//  ContentView.swift
//  LaserGRBL for macOS
//
//  Main application view
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var fileManager: GCodeFileManager
    @EnvironmentObject var serialManager: SerialPortManager
    @EnvironmentObject var grblController: GrblController
    @EnvironmentObject var imageImporter: ImageImporter
    @EnvironmentObject var rasterConverter: RasterConverter
    @EnvironmentObject var svgImporter: SVGImporter
    @EnvironmentObject var pathConverter: PathToGCodeConverter
    @EnvironmentObject var settingsManager: GrblSettingsManager
    @EnvironmentObject var customButtonManager: CustomButtonManager
    
    @State private var selectedCommandId: UUID?
    @State private var showFileInfo = false
    @State private var selectedTab: MainTab = .gcode

    enum MainTab: String, CaseIterable {
        case gcode = "G-Code"
        case importTab = "Image"
        case control = "Control"
        case settings = "Settings"
        case console = "Console"
        
        var icon: String {
            switch self {
            case .gcode: return "doc.text"
            case .importTab: return "photo"
            case .control: return "gamecontroller"
            case .settings: return "gearshape"
            case .console: return "terminal"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar - Connection and file controls
            VStack(spacing: 0) {
                // Connection panel
                ConnectionView(
                    serialManager: serialManager,
                    grblController: grblController
                )
                
                Divider()
                
                // File controls
                SidebarView(showFileInfo: $showFileInfo, selectedTab: $selectedTab)
            }
            .frame(minWidth: 300, maxWidth: 350)
        } detail: {
            // Main content area with tabs
            VStack(spacing: 0) {
                // Tab bar
                Picker("View", selection: $selectedTab) {
                    ForEach(MainTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Tab content
                switch selectedTab {
                case .gcode:
                    gcodeTabView
                case .importTab:
                    importTabView
                case .control:
                    controlTabView
                case .settings:
                    settingsTabView
                case .console:
                    consoleTabView
                }
            }
        }
        .sheet(isPresented: $showFileInfo) {
            if let file = fileManager.currentFile {
                FileInfoView(file: file)
            }
        }
        .overlay {
            if fileManager.isLoading {
                LoadingOverlay()
            }
        }
        .alert("Error", isPresented: .constant(fileManager.errorMessage != nil)) {
            Button("OK") {
                fileManager.errorMessage = nil
            }
        } message: {
            Text(fileManager.errorMessage ?? "")
        }
    }
    
    // MARK: - Tab Views
    
    private var gcodeTabView: some View {
        Group {
            if let file = fileManager.currentFile {
                HSplitView {
                    // Left: Command list and editor
                    GCodeEditorView(file: file, selectedCommandId: $selectedCommandId)
                        .frame(minWidth: 300, idealWidth: 400)
                        .id(file.id) // Force recreation when file changes

                    // Right: Preview
                    GCodePreviewView(file: file, selectedCommandId: $selectedCommandId)
                        .frame(minWidth: 300, idealWidth: 400)
                        .id(file.id) // Force recreation when file changes
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Welcome screen
                WelcomeView(selectedTab: $selectedTab)
            }
        }
    }
    
    private var importTabView: some View {
        UnifiedImportView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var controlTabView: some View {
        ControlPanelView(grblController: grblController, buttonManager: customButtonManager)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var settingsTabView: some View {
        GrblSettingsView(grblController: grblController, settingsManager: settingsManager)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var consoleTabView: some View {
        ConsoleView(grblController: grblController)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @EnvironmentObject var fileManager: GCodeFileManager
    @EnvironmentObject var imageImporter: ImageImporter
    @EnvironmentObject var svgImporter: SVGImporter
    @Binding var showFileInfo: Bool
    @Binding var selectedTab: ContentView.MainTab

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LaserGRBL")
                .font(.title2)
                .bold()
                .padding(.top)

            Divider()

            // File operations
            VStack(alignment: .leading, spacing: 8) {
                Button(action: { fileManager.openFile() }) {
                    Label("Open G-Code", systemImage: "folder")
                }
                .buttonStyle(.bordered)

                Button(action: { fileManager.newFile() }) {
                    Label("New File", systemImage: "doc")
                }
                .buttonStyle(.bordered)
                
                Button(action: { 
                    selectedTab = .importTab
                }) {
                    Label("Import Image", systemImage: "photo")
                }
                .buttonStyle(.bordered)
            }

            if let file = fileManager.currentFile {
                Divider()

                // File info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current File")
                        .font(.headline)

                    Text(file.fileName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("\(file.commands.count) commands")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let bbox = file.boundingBox {
                        Text(String(format: "%.1f × %.1f mm", bbox.width, bbox.height))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if file.estimatedTime > 0 {
                        Text("~\(formatTime(file.estimatedTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button("More Info...") {
                        showFileInfo = true
                    }
                    .font(.caption)
                }
            }

            Spacer()

            // Status
            VStack(alignment: .leading, spacing: 4) {
                Divider()
                Text("Phase 4: In Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("SVG Vector Import")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 250, maxWidth: 300)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, secs)
        } else {
            return String(format: "%ds", secs)
        }
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    @EnvironmentObject var fileManager: GCodeFileManager
    @EnvironmentObject var svgImporter: SVGImporter
    @EnvironmentObject var imageImporter: ImageImporter
    @Binding var selectedTab: ContentView.MainTab

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "laser.burst")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            Text("LaserGRBL for macOS")
                .font(.largeTitle)
                .bold()

            Text("Native macOS port for Apple Silicon")
                .font(.title3)
                .foregroundColor(.secondary)

            Divider()
                .padding(.horizontal, 100)

            VStack(spacing: 12) {
                Button(action: { fileManager.openFile() }) {
                    Label("Open G-Code File", systemImage: "folder.badge.plus")
                        .frame(width: 220)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: { fileManager.newFile() }) {
                    Label("Create New File", systemImage: "doc.badge.plus")
                        .frame(width: 220)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button(action: { 
                    selectedTab = .importTab
                }) {
                    Label("Import Image", systemImage: "photo")
                        .frame(width: 220)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Spacer()
                .frame(height: 40)

            VStack(spacing: 8) {
                Text("✅ Development Status")
                    .font(.headline)

                ProgressView(value: 0.85) {
                    Text("Phase 4: Unified Import Complete")
                        .font(.caption)
                }
                .frame(width: 350)
                
                Text("Import SVG files and images with unified workflow")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(.circular)

                Text("Loading G-Code...")
                    .font(.headline)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .shadow(radius: 20)
            )
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GCodeFileManager())
}
