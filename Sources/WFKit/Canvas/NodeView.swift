import SwiftUI

// MARK: - Node View

public struct NodeView: View {
    let node: WorkflowNode
    let isSelected: Bool
    let isHovered: Bool
    let canvasState: CanvasState

    var onPortDragStart: ((ConnectionAnchor) -> Void)?
    var onPortDragUpdate: ((CGPoint) -> Void)?
    var onPortDragEnd: ((ConnectionAnchor?) -> Void)?
    var onPortHover: ((UUID?) -> Void)?
    var onNodeUpdate: ((WorkflowNode) -> Void)?

    @State private var isDraggingPort: Bool = false
    @State private var showEditor: Bool = false
    @State private var editedNode: WorkflowNode
    @Environment(\.wfTheme) private var theme

    public init(
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

    private let cornerRadius: CGFloat = 6
    private let portSize: CGFloat = 10

    public var body: some View {
        ZStack {
            nodeBackground

            VStack(spacing: 0) {
                nodeHeader
                nodeBody
            }
            .frame(width: node.size.width, height: node.size.height)

            inputPorts
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
                    var updatedNode = node
                    updatedNode.type = nodeType
                    onNodeUpdate?(updatedNode)
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
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(theme.nodeBackground)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isSelected
                            ? node.effectiveColor
                            : (isHovered ? theme.nodeBorderHover : theme.nodeBorder),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(
                color: isSelected ? node.effectiveColor.opacity(0.25) : (theme.isDark ? Color.black.opacity(0.3) : Color.black.opacity(0.15)),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
            .shadow(
                color: theme.isDark ? Color.black.opacity(0.2) : Color.black.opacity(0.1),
                radius: 2,
                x: 0,
                y: 1
            )
    }

    // MARK: - Node Header

    @ViewBuilder
    private var nodeHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: node.type.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.isDark ? Color(hex: "0D0D0D") : Color(hex: "1A1A1A"))
                .frame(width: 20, height: 20)
                .background(node.effectiveColor)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            Text(node.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.textPrimary)
                .lineLimit(1)

            Spacer()

            Text(node.type.rawValue.uppercased())
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .tracking(0.5)
                .foregroundColor(theme.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(theme.sectionBackground.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
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
            Rectangle()
                .fill(node.effectiveColor.opacity(0.2))
                .frame(height: 1)
                .offset(y: 15.5)
        )
    }

    // MARK: - Node Body

    @ViewBuilder
    private var nodeBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(nodeSummary)
                .font(.system(size: 10))
                .foregroundColor(theme.textSecondary)
                .lineLimit(2)
                .padding(.horizontal, 12)

            Spacer()
        }
        .padding(.top, 8)
    }

    private var nodeSummary: String {
        switch node.type {
        case .trigger:
            return "Starts the workflow"

        case .llm:
            var parts: [String] = []
            if let model = node.configuration.model {
                let shortModel = model.split(separator: "-").last.map(String.init) ?? model
                parts.append(shortModel)
            }
            if let temp = node.configuration.temperature {
                parts.append("t:\(String(format: "%.1f", temp))")
            }
            if let maxTokens = node.configuration.maxTokens {
                parts.append("\(maxTokens)tok")
            }
            if parts.isEmpty {
                return "AI processing"
            }
            return parts.joined(separator: " · ")

        case .transform:
            if let expr = node.configuration.expression, !expr.isEmpty {
                let preview = expr.prefix(35).replacingOccurrences(of: "\n", with: " ")
                return "\(preview)\(expr.count > 35 ? "…" : "")"
            }
            return "Transform data"

        case .condition:
            if let cond = node.configuration.condition, !cond.isEmpty {
                let preview = cond.prefix(30).replacingOccurrences(of: "\n", with: " ")
                return "if \(preview)\(cond.count > 30 ? "…" : "")"
            }
            return "Conditional branch"

        case .action:
            if let actionType = node.configuration.actionType, !actionType.isEmpty {
                return actionType
            }
            return "Perform action"

        case .output:
            return "Output result"
        }
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
            .frame(width: portSize * 3)
            .offset(x: -node.size.width / 2)  // Port centered on left edge
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
            .frame(width: portSize * 3)
            .offset(x: node.size.width / 2)  // Port centered on right edge
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
    @Environment(\.wfTheme) private var theme

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
            Circle()
                .fill(
                    isHovered || isDragging || isValidDropTarget
                        ? color
                        : theme.border
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
                    let canvasPoint = canvasState.canvasPoint(from: value.location)
                    onDragUpdate?(canvasPoint)
                }
                .onEnded { value in
                    isDragging = false
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
            .foregroundColor(isHovered ? theme.textSecondary : theme.textTertiary)
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

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Node title", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

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
