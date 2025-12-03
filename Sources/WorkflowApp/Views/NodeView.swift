import SwiftUI

// MARK: - Talkie Design Tokens

private struct TalkieDesign {
    // Theme-adaptive colors
    static func nodeBackground(isDark: Bool) -> Color {
        isDark ? Color(hex: "#1A1A1A") : Color(hex: "#FFFFFF")
    }

    static func borderDefault(isDark: Bool) -> Color {
        isDark ? Color(hex: "#2A2A2A") : Color(hex: "#D0D0D0")
    }

    static func borderHover(isDark: Bool) -> Color {
        isDark ? Color(hex: "#3A3A3A") : Color(hex: "#B0B0B0")
    }

    static func textPrimary(isDark: Bool) -> Color {
        isDark ? Color.white : Color(hex: "#1A1A1A")
    }

    static func textSecondary(isDark: Bool) -> Color {
        isDark ? Color(hex: "#A0A0A0") : Color(hex: "#6A6A6A")
    }

    static func textTertiary(isDark: Bool) -> Color {
        isDark ? Color(hex: "#6B6B6B") : Color(hex: "#9A9A9A")
    }

    static func sectionBackground(isDark: Bool) -> Color {
        isDark ? Color(hex: "#2A2A2A") : Color(hex: "#F5F5F5")
    }

    static func iconBackground(isDark: Bool) -> Color {
        isDark ? Color(hex: "#0D0D0D") : Color(hex: "#1A1A1A")
    }

    // Spacing
    static let spacingTight: CGFloat = 4
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 12
    static let spacingLarge: CGFloat = 16

    // Border radius - sharper corners
    static let radiusSmall: CGFloat = 2
    static let radiusMedium: CGFloat = 4
    static let radiusLarge: CGFloat = 6

    // Port size
    static let portSize: CGFloat = 10
}

// MARK: - Node View

struct NodeView: View {
    let node: WorkflowNode
    let isSelected: Bool
    let isHovered: Bool
    let canvasState: CanvasState

    // Port interaction callbacks
    var onPortDragStart: ((ConnectionAnchor) -> Void)?
    var onPortDragUpdate: ((CGPoint) -> Void)?
    var onPortDragEnd: ((ConnectionAnchor?) -> Void)?
    var onPortHover: ((UUID?) -> Void)?
    var onNodeUpdate: ((WorkflowNode) -> Void)?

    @State private var isDraggingPort: Bool = false
    @State private var showEditor: Bool = false
    @State private var editedNode: WorkflowNode
    @Environment(ThemeManager.self) private var themeManager

    init(
        node: WorkflowNode,
        isSelected: Bool,
        isHovered: Bool,
        canvasState: CanvasState,
        onPortDragStart: ((ConnectionAnchor) -> Void)? = nil,
        onPortDragUpdate: ((CGPoint) -> Void)? = nil,
        onPortDragEnd: ((ConnectionAnchor?) -> Void)? = nil,
        onPortHover: ((UUID?) -> Void)? = nil,
        onNodeUpdate: ((WorkflowNode) -> Void)? = nil
    ) {
        self.node = node
        self.isSelected = isSelected
        self.isHovered = isHovered
        self.canvasState = canvasState
        self.onPortDragStart = onPortDragStart
        self.onPortDragUpdate = onPortDragUpdate
        self.onPortDragEnd = onPortDragEnd
        self.onPortHover = onPortHover
        self.onNodeUpdate = onNodeUpdate
        self._editedNode = State(initialValue: node)
    }

    private let cornerRadius: CGFloat = TalkieDesign.radiusLarge
    private let portSize: CGFloat = TalkieDesign.portSize

    var body: some View {
        ZStack {
            // Node background with glass morphism
            nodeBackground

            // Node content
            VStack(spacing: 0) {
                // Header with gradient
                nodeHeader

                // Body (ports area)
                nodeBody
            }
            .frame(width: node.size.width, height: node.size.height)

            // Input ports (left side)
            inputPorts

            // Output ports (right side)
            outputPorts
        }
        .frame(width: node.size.width, height: node.size.height)
        .onTapGesture(count: 2) {
            editedNode = node
            showEditor = true
        }
        .contextMenu {
            nodeContextMenu
        }
        .popover(isPresented: $showEditor, arrowEdge: .trailing) {
            NodeEditorView(node: $editedNode, onSave: {
                onNodeUpdate?(editedNode)
                showEditor = false
            })
            .frame(width: 320, height: 400)
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var nodeContextMenu: some View {
        Button("Edit") {
            editedNode = node
            showEditor = true
        }
        .keyboardShortcut(.return, modifiers: [])

        Button("Duplicate") {
            canvasState.selectNode(node.id, exclusive: true)
            canvasState.duplicateSelectedNodes()
        }
        .keyboardShortcut("d", modifiers: .command)

        Button("Copy") {
            canvasState.selectNode(node.id, exclusive: true)
            canvasState.copySelectedNodes()
        }
        .keyboardShortcut("c", modifiers: .command)

        Divider()

        Button("Delete", role: .destructive) {
            canvasState.removeNode(node.id)
        }
        .keyboardShortcut(.delete, modifiers: [])

        Divider()

        Menu("Change Color") {
            ForEach(NodeType.allCases) { nodeType in
                Button {
                    canvasState.changeNodeColor(node.id, to: nodeType.color)
                } label: {
                    Label(nodeType.rawValue, systemImage: nodeType.icon)
                }
            }
        }

        Divider()

        Button("Bring to Front") {
            canvasState.selectNode(node.id, exclusive: true)
            canvasState.bringSelectedToFront()
        }
        .keyboardShortcut("]", modifiers: .command)

        Button("Send to Back") {
            canvasState.selectNode(node.id, exclusive: true)
            canvasState.sendSelectedToBack()
        }
        .keyboardShortcut("[", modifiers: .command)
    }

    // MARK: - Node Background

    @ViewBuilder
    private var nodeBackground: some View {
        // Theme-adaptive background with subtle border and shadow
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(TalkieDesign.nodeBackground(isDark: themeManager.isDarkMode))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isSelected
                            ? node.effectiveColor
                            : (isHovered ? TalkieDesign.borderHover(isDark: themeManager.isDarkMode) : TalkieDesign.borderDefault(isDark: themeManager.isDarkMode)),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            // Subtle shadow with theme adaptation
            .shadow(
                color: isSelected ? node.effectiveColor.opacity(0.25) : (themeManager.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.15)),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
            .shadow(
                color: (themeManager.isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.1)),
                radius: 2,
                x: 0,
                y: 1
            )
    }

    // MARK: - Node Header

    @ViewBuilder
    private var nodeHeader: some View {
        HStack(spacing: TalkieDesign.spacingSmall) {
            // Type icon with colored background
            Image(systemName: node.type.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(TalkieDesign.iconBackground(isDark: themeManager.isDarkMode))
                .frame(width: 20, height: 20)
                .background(node.effectiveColor)
                .clipShape(RoundedRectangle(cornerRadius: TalkieDesign.radiusSmall))

            // Title with SF Pro (clean, professional)
            Text(node.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(TalkieDesign.textPrimary(isDark: themeManager.isDarkMode))
                .lineLimit(1)

            Spacer()

            // Type badge - uppercase, tracked, monospace with more contrast
            Text(node.type.rawValue.uppercased())
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .tracking(0.5)
                .foregroundColor(TalkieDesign.textSecondary(isDark: themeManager.isDarkMode))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(TalkieDesign.sectionBackground(isDark: themeManager.isDarkMode).opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: TalkieDesign.radiusSmall))
        }
        .padding(.horizontal, TalkieDesign.spacingMedium)
        .padding(.vertical, TalkieDesign.spacingSmall)
        .background(
            // Subtle gradient from node color
            LinearGradient(
                gradient: Gradient(colors: [
                    node.effectiveColor.opacity(0.12),
                    node.effectiveColor.opacity(0.06)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: cornerRadius
            )
        )
        .overlay(
            // Subtle colored bottom border
            Rectangle()
                .fill(node.effectiveColor.opacity(0.2))
                .frame(height: 1)
                .offset(y: 15.5)
        )
    }

    // MARK: - Node Body

    @ViewBuilder
    private var nodeBody: some View {
        VStack(alignment: .leading, spacing: TalkieDesign.spacingTight) {
            // Show configuration preview with monospace for dev-tool feel
            if let prompt = node.configuration.prompt {
                Text(prompt)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(TalkieDesign.textSecondary(isDark: themeManager.isDarkMode))
                    .lineLimit(2)
                    .padding(.horizontal, TalkieDesign.spacingMedium)
            } else if let condition = node.configuration.condition {
                Text("if: \(condition)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(TalkieDesign.textSecondary(isDark: themeManager.isDarkMode))
                    .lineLimit(1)
                    .padding(.horizontal, TalkieDesign.spacingMedium)
            } else if let actionType = node.configuration.actionType {
                Text(actionType)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(TalkieDesign.textSecondary(isDark: themeManager.isDarkMode))
                    .padding(.horizontal, TalkieDesign.spacingMedium)
            }

            Spacer()
        }
        .padding(.top, TalkieDesign.spacingSmall)
    }

    // MARK: - Input Ports

    @ViewBuilder
    private var inputPorts: some View {
        if !node.inputs.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(node.inputs.enumerated()), id: \.element.id) { index, port in
                    PortView(
                        port: port,
                        nodeId: node.id,
                        color: node.effectiveColor,
                        canvasState: canvasState,
                        onDragStart: onPortDragStart,
                        onDragUpdate: onPortDragUpdate,
                        onDragEnd: onPortDragEnd,
                        onHover: onPortHover
                    )
                    .frame(height: node.size.height / CGFloat(node.inputs.count))
                }
            }
            .frame(width: portSize * 2)
            .offset(x: -node.size.width / 2 - portSize / 2)
        }
    }

    // MARK: - Output Ports

    @ViewBuilder
    private var outputPorts: some View {
        if !node.outputs.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(node.outputs.enumerated()), id: \.element.id) { index, port in
                    PortView(
                        port: port,
                        nodeId: node.id,
                        color: node.effectiveColor,
                        canvasState: canvasState,
                        onDragStart: onPortDragStart,
                        onDragUpdate: onPortDragUpdate,
                        onDragEnd: onPortDragEnd,
                        onHover: onPortHover
                    )
                    .frame(height: node.size.height / CGFloat(node.outputs.count))
                }
            }
            .frame(width: portSize * 2)
            .offset(x: node.size.width / 2 + portSize / 2)
        }
    }
}

// MARK: - Port View

struct PortView: View {
    let port: Port
    let nodeId: UUID
    let color: Color
    let canvasState: CanvasState

    var onDragStart: ((ConnectionAnchor) -> Void)?
    var onDragUpdate: ((CGPoint) -> Void)?
    var onDragEnd: ((ConnectionAnchor?) -> Void)?
    var onHover: ((UUID?) -> Void)?

    @State private var isHovered: Bool = false
    @State private var isDragging: Bool = false
    @Environment(ThemeManager.self) private var themeManager

    private let portSize: CGFloat = 12

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                if !port.isInput {
                    Spacer()
                    portLabel
                }

                portCircle

                if port.isInput {
                    portLabel
                    Spacer()
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var portCircle: some View {
        let isValidDropTarget = canvasState.validDropPortIds.contains(port.id)
        let isPendingSource = canvasState.pendingConnection?.sourceAnchor.portId == port.id

        ZStack {
            // Clean port circle (no glow effects)
            Circle()
                .fill(
                    isHovered || isDragging || isValidDropTarget
                        ? color
                        : TalkieDesign.borderDefault(isDark: themeManager.isDarkMode)
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            isValidDropTarget
                                ? Color.green
                                : (isPendingSource ? color.opacity(0.8) : color.opacity(0.5)),
                            lineWidth: 1.5
                        )
                )
                .frame(width: portSize, height: portSize)
                .shadow(
                    color: Color.black.opacity(0.2),
                    radius: 2,
                    x: 0,
                    y: 1
                )
        }
        .scaleEffect(isHovered || isValidDropTarget ? 1.2 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isValidDropTarget)
        .onHover { hovering in
            isHovered = hovering
            onHover?(hovering ? port.id : nil)
        }
        .gesture(
            DragGesture(minimumDistance: 5, coordinateSpace: .named("canvas"))
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        // Get port position in canvas coordinates
                        if let portPos = canvasState.portPosition(nodeId: nodeId, portId: port.id) {
                            let anchor = ConnectionAnchor(
                                nodeId: nodeId,
                                portId: port.id,
                                position: portPos,
                                isInput: port.isInput
                            )
                            onDragStart?(anchor)
                        }
                    }
                    // Convert drag location from canvas view to canvas content coordinates
                    let canvasPoint = canvasState.canvasPoint(from: value.location)
                    onDragUpdate?(canvasPoint)
                }
                .onEnded { value in
                    isDragging = false
                    // Find target port at end location in canvas coordinates
                    let canvasPoint = canvasState.canvasPoint(from: value.location)
                    if let portHit = canvasState.portAt(canvasPoint: canvasPoint) {
                        let targetAnchor = ConnectionAnchor(
                            nodeId: portHit.nodeId,
                            portId: portHit.portId,
                            position: canvasState.portPosition(nodeId: portHit.nodeId, portId: portHit.portId) ?? canvasPoint,
                            isInput: portHit.isInput
                        )
                        onDragEnd?(targetAnchor)
                    } else {
                        onDragEnd?(nil)
                    }
                }
        )
    }

    @ViewBuilder
    private var portLabel: some View {
        Text(port.label)
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundColor(isHovered ? TalkieDesign.textSecondary(isDark: themeManager.isDarkMode) : TalkieDesign.textTertiary(isDark: themeManager.isDarkMode))
            .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Node Editor View

struct NodeEditorView: View {
    @Binding var node: WorkflowNode
    var onSave: () -> Void

    @State private var title: String
    @State private var prompt: String
    @State private var systemPrompt: String
    @State private var model: String
    @State private var temperature: Double
    @State private var condition: String
    @State private var actionType: String

    init(node: Binding<WorkflowNode>, onSave: @escaping () -> Void) {
        self._node = node
        self.onSave = onSave
        self._title = State(initialValue: node.wrappedValue.title)
        self._prompt = State(initialValue: node.wrappedValue.configuration.prompt ?? "")
        self._systemPrompt = State(initialValue: node.wrappedValue.configuration.systemPrompt ?? "")
        self._model = State(initialValue: node.wrappedValue.configuration.model ?? "gemini-2.0-flash")
        self._temperature = State(initialValue: node.wrappedValue.configuration.temperature ?? 0.7)
        self._condition = State(initialValue: node.wrappedValue.configuration.condition ?? "")
        self._actionType = State(initialValue: node.wrappedValue.configuration.actionType ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: node.type.icon)
                    .foregroundColor(node.type.color)
                Text("Edit \(node.type.rawValue)")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            Divider()

            // Editor form
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Node title", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Type-specific fields
                    switch node.type {
                    case .llm:
                        llmFields
                    case .condition:
                        conditionFields
                    case .action:
                        actionFields
                    case .transform:
                        transformFields
                    default:
                        EmptyView()
                    }
                }
                .padding()
            }

            Divider()

            // Footer buttons
            HStack {
                Button("Cancel") {
                    onSave()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    saveChanges()
                    onSave()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    @ViewBuilder
    private var llmFields: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Prompt")
                .font(.caption)
                .foregroundColor(.secondary)
            TextEditor(text: $prompt)
                .font(.system(size: 11, design: .monospaced))
                .frame(height: 100)
                .border(Color.gray.opacity(0.3))
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("System Prompt (optional)")
                .font(.caption)
                .foregroundColor(.secondary)
            TextEditor(text: $systemPrompt)
                .font(.system(size: 11, design: .monospaced))
                .frame(height: 60)
                .border(Color.gray.opacity(0.3))
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("Model")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("Model name", text: $model)
                .textFieldStyle(.roundedBorder)
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("Temperature: \(temperature, specifier: "%.2f")")
                .font(.caption)
                .foregroundColor(.secondary)
            Slider(value: $temperature, in: 0...2, step: 0.1)
        }
    }

    @ViewBuilder
    private var conditionFields: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Condition Expression")
                .font(.caption)
                .foregroundColor(.secondary)
            TextEditor(text: $condition)
                .font(.system(size: 11, design: .monospaced))
                .frame(height: 80)
                .border(Color.gray.opacity(0.3))
            Text("Example: output.contains('important')")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var actionFields: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Action Type")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("e.g., reminder, notification", text: $actionType)
                .textFieldStyle(.roundedBorder)
        }
    }

    @ViewBuilder
    private var transformFields: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Transform Expression")
                .font(.caption)
                .foregroundColor(.secondary)
            TextEditor(text: $prompt)
                .font(.system(size: 11, design: .monospaced))
                .frame(height: 80)
                .border(Color.gray.opacity(0.3))
        }
    }

    private func saveChanges() {
        node.title = title

        switch node.type {
        case .llm:
            node.configuration.prompt = prompt.isEmpty ? nil : prompt
            node.configuration.systemPrompt = systemPrompt.isEmpty ? nil : systemPrompt
            node.configuration.model = model.isEmpty ? nil : model
            node.configuration.temperature = temperature
        case .condition:
            node.configuration.condition = condition.isEmpty ? nil : condition
        case .action:
            node.configuration.actionType = actionType.isEmpty ? nil : actionType
        case .transform:
            node.configuration.expression = prompt.isEmpty ? nil : prompt
        default:
            break
        }
    }
}

// MARK: - Preview

#Preview("Node View") {
    let state = CanvasState()
    VStack(spacing: 20) {
        NodeView(
            node: WorkflowNode(type: .trigger, title: "Voice Input"),
            isSelected: false,
            isHovered: false,
            canvasState: state
        )

        NodeView(
            node: WorkflowNode(
                type: .llm,
                title: "Summarize",
                configuration: NodeConfiguration(prompt: "Summarize this text...")
            ),
            isSelected: true,
            isHovered: false,
            canvasState: state
        )

        NodeView(
            node: WorkflowNode(
                type: .condition,
                title: "Check Priority",
                configuration: NodeConfiguration(condition: "priority == 'high'")
            ),
            isSelected: false,
            isHovered: true,
            canvasState: state
        )
    }
    .padding(40)
    .background(Color(nsColor: .windowBackgroundColor))
}
