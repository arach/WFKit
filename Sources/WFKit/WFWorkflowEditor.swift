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

// MARK: - Inspector Style

/// Controls how the inspector is displayed in WFWorkflowEditor
public enum WFInspectorStyle {
    /// Uses SwiftUI's .inspector() modifier - requires WindowGroup context
    case system
    /// Uses HStack layout - works in modals, sheets, and panels
    case inline
    /// No inspector
    case none
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
///
/// // With schema (for structured field display)
/// WFWorkflowEditor(state: canvasState, schema: MyAppSchema())
///
/// // In a modal/sheet context (use inline inspector)
/// WFWorkflowEditor(state: canvasState, inspectorStyle: .inline)
/// ```
public struct WFWorkflowEditor: View {
    @Bindable var state: CanvasState
    let isReadOnly: Bool
    let schema: (any WFSchemaProvider)?
    let inspectorStyle: WFInspectorStyle
    @Binding var showInspector: Bool
    @Environment(\.wfTheme) private var theme

    public init(
        state: CanvasState,
        schema: (any WFSchemaProvider)? = nil,
        isReadOnly: Bool = false,
        inspectorStyle: WFInspectorStyle = .system,
        showInspector: Binding<Bool> = .constant(true)
    ) {
        self.state = state
        self.schema = schema
        self.isReadOnly = isReadOnly
        self.inspectorStyle = inspectorStyle
        self._showInspector = showInspector
    }

    public var body: some View {
        Group {
            switch inspectorStyle {
            case .system:
                systemInspectorLayout
            case .inline:
                inlineInspectorLayout
            case .none:
                canvasOnly
            }
        }
        .environment(\.wfReadOnly, isReadOnly)
        .environment(\.wfSchema, schema)
        .onChange(of: state.selectedNodeIds) { _, newSelection in
            // Auto-show inspector when a node is selected
            if !newSelection.isEmpty && !showInspector && inspectorStyle != .none {
                showInspector = true
            }
        }
    }

    // MARK: - Layout Variants

    /// Canvas with system .inspector() modifier - requires WindowGroup
    @ViewBuilder
    private var systemInspectorLayout: some View {
        WorkflowCanvas(state: state)
            .inspector(isPresented: $showInspector) {
                InspectorView(state: state, isVisible: $showInspector)
                    .inspectorColumnWidth(min: 280, ideal: 320, max: 400)
            }
    }

    /// Canvas with inline HStack inspector - works in modals/sheets
    @ViewBuilder
    private var inlineInspectorLayout: some View {
        HStack(spacing: 0) {
            WorkflowCanvas(state: state)

            if showInspector {
                Rectangle()
                    .fill(theme.divider)
                    .frame(width: 1)

                InspectorView(state: state, isVisible: $showInspector)
                    .frame(width: 320)
            }
        }
    }

    /// Canvas only, no inspector
    @ViewBuilder
    private var canvasOnly: some View {
        WorkflowCanvas(state: state)
    }
}

// MARK: - Preview

#Preview("WFWorkflowEditor - System Inspector") {
    WFWorkflowEditor(state: CanvasState.sampleState(), inspectorStyle: .system)
        .frame(width: 1200, height: 800)
        .environment(WFThemeManager())
}

#Preview("WFWorkflowEditor - Inline Inspector") {
    WFWorkflowEditor(state: CanvasState.sampleState(), inspectorStyle: .inline)
        .frame(width: 1200, height: 800)
        .environment(WFThemeManager())
}
