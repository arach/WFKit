import SwiftUI
import AppKit
import WFKit

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Make app appear in Dock and Cmd+Tab
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Main App

@main
struct WorkflowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var canvasState = CanvasState.sampleState()
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView(state: canvasState)
                .environment(themeManager)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Edit commands
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    canvasState.undo()
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!canvasState.canUndo)

                Button("Redo") {
                    canvasState.redo()
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!canvasState.canRedo)
            }

            CommandGroup(after: .undoRedo) {
                Divider()

                Button("Select All") {
                    canvasState.selectAll()
                }
                .keyboardShortcut("a", modifiers: .command)

                Button("Delete Selected") {
                    canvasState.removeSelectedNodes()
                }
                .keyboardShortcut(.delete, modifiers: [])
                .disabled(!canvasState.hasSelection)
            }

            // View commands
            CommandGroup(after: .toolbar) {
                Divider()

                Button("Zoom In") {
                    canvasState.zoomIn()
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    canvasState.zoomOut()
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Reset Zoom") {
                    canvasState.resetView()
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @Bindable var state: CanvasState
    @State private var showNodePalette: Bool = false
    @State private var showInspector: Bool = true
    @State private var wfThemePreset: WFThemePreset = .sharpDark
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        HSplitView {
            // Main canvas area
            VStack(spacing: 0) {
                // Toolbar
                ToolbarView(state: state, showNodePalette: $showNodePalette)

                Divider()
                    .background(DesignSystem.Colors.divider(isDark: themeManager.isDarkMode))

                // Canvas
                WorkflowCanvas(state: state)
            }
            .frame(minWidth: 400)

            // Inspector sidebar
            if showInspector {
                InspectorView(state: state)
                    .frame(minWidth: 280, maxWidth: 320)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(DesignSystem.Colors.canvasBackground(isDark: themeManager.isDarkMode))
        .toolbar {
            // WFKit Theme selector
            ToolbarItem(placement: .automatic) {
                Menu {
                    ForEach(WFThemePreset.allCases) { preset in
                        Button(action: { wfThemePreset = preset }) {
                            HStack {
                                Image(systemName: preset.icon)
                                Text(preset.rawValue)
                                if wfThemePreset == preset {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: wfThemePreset.icon)
                        Text("WFKit")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                }
                .help("WFKit Theme: \(wfThemePreset.rawValue)")
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: { showInspector.toggle() }) {
                    Image(systemName: showInspector ? "sidebar.trailing" : "sidebar.trailing")
                        .symbolVariant(showInspector ? .none : .slash)
                }
                .help(showInspector ? "Hide Inspector" : "Show Inspector")
            }
        }
        .wfTheme(wfThemePreset.theme)
        .onAppear {
            // Select the first node to show inspector content
            if let firstNode = state.nodes.first {
                state.selectNode(firstNode.id, exclusive: true)
            }
        }
    }
}

// MARK: - Preview

#Preview("Workflow") {
    ContentView(state: CanvasState.sampleState())
}
