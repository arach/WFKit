import SwiftUI
import AppKit
import WFKit

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Main App

@main
struct WorkflowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var canvasState = CanvasState.sampleState()
    @State private var themeManager = WFThemeManager()

    var body: some Scene {
        WindowGroup {
            WFWorkflowEditor(state: canvasState)
                .environment(\.wfTheme, themeManager)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
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
