import SwiftUI

// MARK: - WFWorkflowEditor

/// The main workflow editor component.
/// Drop this into your app to get a complete node-based workflow editor.
///
/// Usage:
/// ```swift
/// @State private var canvasState = CanvasState()
///
/// WFWorkflowEditor(state: $canvasState)
/// ```
public struct WFWorkflowEditor: View {
    @Bindable var state: CanvasState
    @State private var showNodePalette: Bool = false
    @State private var showInspector: Bool = true
    @Environment(\.wfTheme) private var theme

    public init(state: CanvasState) {
        self.state = state
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            ToolbarView(state: state, showNodePalette: $showNodePalette)

            // Divider
            Rectangle()
                .fill(theme.divider)
                .frame(height: 1)

            // Canvas
            WorkflowCanvas(state: state)
        }
        .inspector(isPresented: $showInspector) {
            InspectorView(state: state, isVisible: $showInspector)
                .inspectorColumnWidth(min: 250, ideal: 350, max: 600)
        }
        .background(theme.canvasBackground)
        .onChange(of: state.selectedNodeIds) { _, newSelection in
            // Auto-show inspector when a node is selected
            if !newSelection.isEmpty && !showInspector {
                showInspector = true
            }
        }
        .toolbar {
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

// MARK: - Preview

#Preview("WFWorkflowEditor") {
    WFWorkflowEditor(state: CanvasState.sampleState())
        .frame(width: 1200, height: 800)
        .environment(WFThemeManager())
}
