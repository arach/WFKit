import SwiftUI

// MARK: - Read-Only Environment Key

private struct WFReadOnlyKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    public var wfReadOnly: Bool {
        get { self[WFReadOnlyKey.self] }
        set { self[WFReadOnlyKey.self] = newValue }
    }
}

// MARK: - WFWorkflowEditor

/// The main workflow editor component.
/// Drop this into your app to get a complete node-based workflow editor.
///
/// Usage:
/// ```swift
/// @State private var canvasState = CanvasState()
///
/// // Editable mode (default)
/// WFWorkflowEditor(state: canvasState)
///
/// // Read-only mode (for visualization only)
/// WFWorkflowEditor(state: canvasState, isReadOnly: true)
/// ```
public struct WFWorkflowEditor: View {
    @Bindable var state: CanvasState
    let isReadOnly: Bool
    @State private var showNodePalette: Bool = false
    @State private var showInspector: Bool = true
    @Environment(\.wfTheme) private var theme

    public init(state: CanvasState, isReadOnly: Bool = false) {
        self.state = state
        self.isReadOnly = isReadOnly
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar (hidden in read-only mode)
            if !isReadOnly {
                ToolbarView(state: state, showNodePalette: $showNodePalette)

                // Divider
                Rectangle()
                    .fill(theme.divider)
                    .frame(height: 1)
            }

            // Canvas
            WorkflowCanvas(state: state)
        }
        .inspector(isPresented: $showInspector) {
            InspectorView(state: state, isVisible: $showInspector)
                .inspectorColumnWidth(min: 250, ideal: 350, max: 600)
        }
        .environment(\.wfReadOnly, isReadOnly)
        .background(theme.canvasBackground)
        .onChange(of: state.selectedNodeIds) { _, newSelection in
            // Auto-show inspector when a node is selected (only in edit mode)
            if !isReadOnly && !newSelection.isEmpty && !showInspector {
                showInspector = true
            }
        }
        .toolbar {
            // Only show inspector toggle in edit mode
            if !isReadOnly {
                ToolbarItem(placement: .navigation) {
                    Button(action: { showInspector.toggle() }) {
                        Image(systemName: showInspector ? "sidebar.right" : "sidebar.right")
                            .symbolVariant(showInspector ? .fill : .none)
                    }
                    .help(showInspector ? "Hide Inspector" : "Show Inspector")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("WFWorkflowEditor") {
    WFWorkflowEditor(state: CanvasState.sampleState())
        .frame(width: 1200, height: 800)
        .environment(WFThemeManager())
}
