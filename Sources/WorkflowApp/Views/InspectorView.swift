import SwiftUI

// MARK: - Inspector Design Tokens

private struct InspectorDesign {
    // Theme-adaptive color palette - improved contrast
    static func bg900(isDark: Bool) -> Color {
        isDark ? Color(red: 0x0D/255.0, green: 0x0D/255.0, blue: 0x0D/255.0) : Color(red: 0xF8/255.0, green: 0xF8/255.0, blue: 0xF8/255.0)
    }

    static func bg800(isDark: Bool) -> Color {
        isDark ? Color(red: 0x16/255.0, green: 0x16/255.0, blue: 0x16/255.0) : Color(red: 0xFF/255.0, green: 0xFF/255.0, blue: 0xFF/255.0)
    }

    static func bg700(isDark: Bool) -> Color {
        isDark ? Color(red: 0x22/255.0, green: 0x22/255.0, blue: 0x22/255.0) : Color(red: 0xF0/255.0, green: 0xF0/255.0, blue: 0xF0/255.0)
    }

    // Input field background - slightly lighter than section bg
    static func inputBg(isDark: Bool) -> Color {
        isDark ? Color(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0) : Color(red: 0xFF/255.0, green: 0xFF/255.0, blue: 0xFF/255.0)
    }

    static func border(isDark: Bool) -> Color {
        isDark ? Color(red: 0x38/255.0, green: 0x38/255.0, blue: 0x38/255.0) : Color(red: 0xD0/255.0, green: 0xD0/255.0, blue: 0xD0/255.0)
    }

    // Text colors - improved contrast
    static func textPrimary(isDark: Bool) -> Color {
        isDark ? Color(red: 0xF0/255.0, green: 0xF0/255.0, blue: 0xF0/255.0) : Color(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0)
    }

    static func textSecondary(isDark: Bool) -> Color {
        isDark ? Color(red: 0xB0/255.0, green: 0xB0/255.0, blue: 0xB0/255.0) : Color(red: 0x5A/255.0, green: 0x5A/255.0, blue: 0x5A/255.0)
    }

    static func textTertiary(isDark: Bool) -> Color {
        isDark ? Color(red: 0x70/255.0, green: 0x70/255.0, blue: 0x70/255.0) : Color(red: 0x8A/255.0, green: 0x8A/255.0, blue: 0x8A/255.0)
    }

    // Placeholder text - subtle but readable
    static func textPlaceholder(isDark: Bool) -> Color {
        isDark ? Color(red: 0x5A/255.0, green: 0x5A/255.0, blue: 0x5A/255.0) : Color(red: 0xA0/255.0, green: 0xA0/255.0, blue: 0xA0/255.0)
    }

    // Corner radius
    static let cornerRadius: CGFloat = 6
    static let cornerRadiusSmall: CGFloat = 4

    // Preset color swatches for custom node colors
    static let presetColors = [
        "#FF9F0A", // Orange
        "#FFD60A", // Yellow
        "#30D158", // Green
        "#64D2FF", // Cyan
        "#0A84FF", // Blue
        "#BF5AF2", // Purple
        "#FF375F", // Pink
        "#FF453A", // Red
        "#AC8E68", // Brown
        "#98989D"  // Gray
    ]
}

// MARK: - Inspector View

struct InspectorView: View {
    @Bindable var state: CanvasState
    @State private var expandedSections: Set<String> = ["properties", "appearance", "configuration"]
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(spacing: 0) {
            // Header - flush to edge
            inspectorHeader

            // Thin divider
            Rectangle()
                .fill(InspectorDesign.border(isDark: themeManager.isDarkMode))
                .frame(height: 1)

            // Content - flush to edge
            if let node = state.singleSelectedNode {
                ScrollView {
                    VStack(spacing: 0) {
                        // Appearance section (Color picker)
                        InspectorSection(
                            title: "APPEARANCE",
                            icon: "paintpalette.fill",
                            id: "appearance",
                            expandedSections: $expandedSections
                        ) {
                            appearanceSection(node)
                        }

                        // Node properties section
                        InspectorSection(
                            title: "PROPERTIES",
                            icon: "slider.horizontal.3",
                            id: "properties",
                            expandedSections: $expandedSections
                        ) {
                            nodePropertiesSection(node)
                        }

                        // Configuration section based on node type
                        InspectorSection(
                            title: "CONFIGURATION",
                            icon: "gearshape.fill",
                            id: "configuration",
                            expandedSections: $expandedSections
                        ) {
                            nodeConfigurationSection(node)
                        }

                        // Ports section
                        InspectorSection(
                            title: "CONNECTIONS",
                            icon: "arrow.triangle.branch",
                            id: "connections",
                            expandedSections: $expandedSections
                        ) {
                            portsSection(node)
                        }
                    }
                    .padding(.vertical, 12)
                }
            } else if state.selectedNodeIds.count > 1 {
                multiSelectionView
            } else {
                emptySelectionView
            }
        }
        .frame(width: 280)
        .background(InspectorDesign.bg900(isDark: themeManager.isDarkMode))
    }

    // MARK: - Header

    @ViewBuilder
    private var inspectorHeader: some View {
        HStack(spacing: 8) {
            Text("INSPECTOR")
                .font(.system(size: 10, weight: .bold, design: .default))
                .tracking(1.2)
                .foregroundColor(InspectorDesign.textSecondary(isDark: themeManager.isDarkMode))

            Spacer()

            if state.hasSelection {
                Button(action: { state.clearSelection() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(InspectorDesign.textTertiary(isDark: themeManager.isDarkMode))
                }
                .buttonStyle(.plain)
                .padding(6)
                .background(InspectorDesign.bg700(isDark: themeManager.isDarkMode))
                .clipShape(RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(InspectorDesign.bg800(isDark: themeManager.isDarkMode))
    }

    // MARK: - Appearance Section (Color Picker)

    @ViewBuilder
    private func appearanceSection(_ node: WorkflowNode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Color preset swatches
            VStack(alignment: .leading, spacing: 6) {
                Text("Node Color")
                    .font(.system(size: 9, weight: .semibold, design: .default))
                    .tracking(0.5)
                    .foregroundColor(InspectorDesign.textSecondary(isDark: themeManager.isDarkMode))
                    .textCase(.uppercase)

                // Default color option
                HStack(spacing: 8) {
                    Button(action: {
                        var updated = node
                        updated.customColor = nil
                        state.updateNode(updated)
                    }) {
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(node.type.color)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .strokeBorder(
                                            node.customColor == nil ? Color.white : InspectorDesign.border(isDark: themeManager.isDarkMode),
                                            lineWidth: node.customColor == nil ? 2 : 1
                                        )
                                )

                            Text("Default")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(InspectorDesign.textSecondary(isDark: themeManager.isDarkMode))

                            Spacer()
                        }
                        .padding(8)
                        .background(node.customColor == nil ? InspectorDesign.bg700(isDark: themeManager.isDarkMode) : InspectorDesign.bg900(isDark: themeManager.isDarkMode))
                        .clipShape(RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius))
                    }
                    .buttonStyle(.plain)
                }

                // Preset color swatches grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(InspectorDesign.presetColors, id: \.self) { hexColor in
                        Button(action: {
                            var updated = node
                            updated.customColor = hexColor
                            state.updateNode(updated)
                        }) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: hexColor))
                                .frame(height: 28)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .strokeBorder(
                                            node.customColor == hexColor ? Color.white : InspectorDesign.border(isDark: themeManager.isDarkMode),
                                            lineWidth: node.customColor == hexColor ? 2 : 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Node Properties Section

    @ViewBuilder
    private func nodePropertiesSection(_ node: WorkflowNode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            InspectorField(label: "TITLE") {
                TextField("Title", text: Binding(
                    get: { node.title },
                    set: { newValue in
                        var updated = node
                        updated.title = newValue
                        state.updateNode(updated)
                    }
                ))
                .textFieldStyle(WFTextFieldStyle(isDark: themeManager.isDarkMode))
                .font(.system(size: 12, design: .default))
            }

            // Type (read-only)
            InspectorField(label: "TYPE") {
                HStack(spacing: 8) {
                    Image(systemName: node.type.icon)
                        .font(.system(size: 11))
                        .foregroundColor(node.effectiveColor)
                    Text(node.type.rawValue)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(InspectorDesign.textSecondary(isDark: themeManager.isDarkMode))
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(InspectorDesign.bg900(isDark: themeManager.isDarkMode))
                .clipShape(RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius)
                        .strokeBorder(InspectorDesign.border(isDark: themeManager.isDarkMode), lineWidth: 1)
                )
            }

            // Position
            HStack(spacing: 8) {
                InspectorField(label: "X") {
                    TextField("X", value: Binding(
                        get: { node.position.x },
                        set: { newValue in
                            guard let newValue = newValue else { return }
                            var updated = node
                            updated.position.x = newValue
                            state.updateNode(updated)
                        }
                    ), format: .number)
                    .textFieldStyle(WFTextFieldStyle(isDark: themeManager.isDarkMode))
                    .font(.system(size: 11, design: .monospaced))
                }

                InspectorField(label: "Y") {
                    TextField("Y", value: Binding(
                        get: { node.position.y },
                        set: { newValue in
                            guard let newValue = newValue else { return }
                            var updated = node
                            updated.position.y = newValue
                            state.updateNode(updated)
                        }
                    ), format: .number)
                    .textFieldStyle(WFTextFieldStyle(isDark: themeManager.isDarkMode))
                    .font(.system(size: 11, design: .monospaced))
                }
            }
        }
    }

    // MARK: - Node Configuration Section

    @ViewBuilder
    private func nodeConfigurationSection(_ node: WorkflowNode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            switch node.type {
            case .llm:
                llmConfigSection(node)
            case .condition:
                conditionConfigSection(node)
            case .transform:
                transformConfigSection(node)
            case .action:
                actionConfigSection(node)
            case .trigger:
                triggerConfigSection(node)
            case .output:
                outputConfigSection(node)
            }
        }
    }

    // MARK: - LLM Config

    @ViewBuilder
    private func llmConfigSection(_ node: WorkflowNode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Model selector
            InspectorField(label: "Model") {
                WFPicker(
                    selection: Binding(
                        get: { node.configuration.model ?? "gemini-2.0-flash" },
                        set: { newValue in
                            var updated = node
                            updated.configuration.model = newValue
                            state.updateNode(updated)
                        }
                    ),
                    options: [
                        ("gemini-2.0-flash", "Gemini 2.0 Flash"),
                        ("gemini-1.5-pro", "Gemini 1.5 Pro"),
                        ("gpt-4o", "GPT-4o"),
                        ("claude-sonnet-4", "Claude Sonnet 4")
                    ]
                )
            }

            // Temperature
            InspectorField(label: "Temperature") {
                VStack(spacing: 4) {
                    HStack {
                        Slider(value: Binding(
                            get: { node.configuration.temperature ?? 0.7 },
                            set: { newValue in
                                var updated = node
                                updated.configuration.temperature = newValue
                                state.updateNode(updated)
                            }
                        ), in: 0...2, step: 0.1)
                        .accentColor(node.effectiveColor)

                        Text(String(format: "%.1f", node.configuration.temperature ?? 0.7))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(InspectorDesign.textPrimary(isDark: themeManager.isDarkMode))
                            .frame(width: 36)
                            .padding(4)
                            .background(InspectorDesign.bg900(isDark: themeManager.isDarkMode))
                            .clipShape(RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius))
                    }

                    HStack {
                        Text("0.0")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(InspectorDesign.textTertiary(isDark: themeManager.isDarkMode))
                        Spacer()
                        Text("Precise")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(InspectorDesign.textTertiary(isDark: themeManager.isDarkMode))
                        Spacer()
                        Text("Creative")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(InspectorDesign.textTertiary(isDark: themeManager.isDarkMode))
                        Spacer()
                        Text("2.0")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(InspectorDesign.textTertiary(isDark: themeManager.isDarkMode))
                    }
                }
            }

            // Max Tokens
            InspectorField(label: "Max Tokens") {
                TextField("Max tokens (optional)", value: Binding(
                    get: { node.configuration.maxTokens },
                    set: { newValue in
                        var updated = node
                        updated.configuration.maxTokens = newValue
                        state.updateNode(updated)
                    }
                ), format: .number)
                .textFieldStyle(WFTextFieldStyle(isDark: themeManager.isDarkMode))
                .font(.system(size: 11, design: .monospaced))
            }

            // System Prompt
            InspectorField(label: "System Prompt") {
                WFTextEditor(
                    text: Binding(
                        get: { node.configuration.systemPrompt ?? "" },
                        set: { newValue in
                            var updated = node
                            updated.configuration.systemPrompt = newValue.isEmpty ? nil : newValue
                            state.updateNode(updated)
                        }
                    ),
                    placeholder: "Optional system instructions...",
                    height: 80
                )
            }

            // Prompt
            InspectorField(label: "Prompt") {
                WFTextEditor(
                    text: Binding(
                        get: { node.configuration.prompt ?? "" },
                        set: { newValue in
                            var updated = node
                            updated.configuration.prompt = newValue
                            state.updateNode(updated)
                        }
                    ),
                    placeholder: "Enter your prompt...",
                    height: 120
                )
            }
        }
    }

    // MARK: - Condition Config

    @ViewBuilder
    private func conditionConfigSection(_ node: WorkflowNode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            InspectorField(label: "Condition") {
                WFTextEditor(
                    text: Binding(
                        get: { node.configuration.condition ?? "" },
                        set: { newValue in
                            var updated = node
                            updated.configuration.condition = newValue
                            state.updateNode(updated)
                        }
                    ),
                    placeholder: "e.g., output.contains('urgent')",
                    height: 80
                )
            }

            Text("Use variables: {{input}}, {{output}}")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(InspectorDesign.textTertiary(isDark: themeManager.isDarkMode))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(InspectorDesign.bg900(isDark: themeManager.isDarkMode).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius))
        }
    }

    // MARK: - Transform Config

    @ViewBuilder
    private func transformConfigSection(_ node: WorkflowNode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            InspectorField(label: "Transform Type") {
                WFPicker(
                    selection: Binding(
                        get: { node.configuration.transformType ?? "extractJSON" },
                        set: { newValue in
                            var updated = node
                            updated.configuration.transformType = newValue
                            state.updateNode(updated)
                        }
                    ),
                    options: [
                        ("extractJSON", "Extract JSON"),
                        ("extractList", "Extract List"),
                        ("formatMarkdown", "Format Markdown"),
                        ("regex", "Regex"),
                        ("template", "Template")
                    ]
                )
            }

            InspectorField(label: "Expression") {
                WFTextEditor(
                    text: Binding(
                        get: { node.configuration.expression ?? "" },
                        set: { newValue in
                            var updated = node
                            updated.configuration.expression = newValue
                            state.updateNode(updated)
                        }
                    ),
                    placeholder: "Enter transform expression...",
                    height: 100
                )
            }
        }
    }

    // MARK: - Action Config

    @ViewBuilder
    private func actionConfigSection(_ node: WorkflowNode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            InspectorField(label: "Action Type") {
                WFPicker(
                    selection: Binding(
                        get: { node.configuration.actionType ?? "notification" },
                        set: { newValue in
                            var updated = node
                            updated.configuration.actionType = newValue
                            state.updateNode(updated)
                        }
                    ),
                    options: [
                        ("notification", "Notification"),
                        ("reminder", "Reminder"),
                        ("appleNotes", "Apple Notes"),
                        ("clipboard", "Clipboard"),
                        ("saveFile", "Save File"),
                        ("webhook", "Webhook"),
                        ("shell", "Shell Command")
                    ]
                )
            }

            // Show additional fields based on action type
            if let actionType = node.configuration.actionType {
                switch actionType {
                case "webhook":
                    InspectorField(label: "Webhook URL") {
                        TextField("https://...", text: Binding(
                            get: { node.configuration.actionConfig?["url"] ?? "" },
                            set: { newValue in
                                var updated = node
                                var config = updated.configuration.actionConfig ?? [:]
                                config["url"] = newValue
                                updated.configuration.actionConfig = config
                                state.updateNode(updated)
                            }
                        ))
                        .textFieldStyle(WFTextFieldStyle(isDark: themeManager.isDarkMode))
                        .font(.system(size: 11, design: .monospaced))
                    }
                case "shell":
                    InspectorField(label: "Command") {
                        WFTextEditor(
                            text: Binding(
                                get: { node.configuration.actionConfig?["command"] ?? "" },
                                set: { newValue in
                                    var updated = node
                                    var config = updated.configuration.actionConfig ?? [:]
                                    config["command"] = newValue
                                    updated.configuration.actionConfig = config
                                    state.updateNode(updated)
                                }
                            ),
                            placeholder: "Enter shell command...",
                            height: 80
                        )
                    }
                case "saveFile":
                    InspectorField(label: "File Path") {
                        TextField("~/Documents/output.txt", text: Binding(
                            get: { node.configuration.actionConfig?["path"] ?? "" },
                            set: { newValue in
                                var updated = node
                                var config = updated.configuration.actionConfig ?? [:]
                                config["path"] = newValue
                                updated.configuration.actionConfig = config
                                state.updateNode(updated)
                            }
                        ))
                        .textFieldStyle(WFTextFieldStyle(isDark: themeManager.isDarkMode))
                        .font(.system(size: 11, design: .monospaced))
                    }
                default:
                    EmptyView()
                }
            }
        }
    }

    // MARK: - Trigger Config

    @ViewBuilder
    private func triggerConfigSection(_ node: WorkflowNode) -> some View {
        Text("Workflow entry point")
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(InspectorDesign.textTertiary(isDark: themeManager.isDarkMode))
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(InspectorDesign.bg900(isDark: themeManager.isDarkMode).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius))
    }

    // MARK: - Output Config

    @ViewBuilder
    private func outputConfigSection(_ node: WorkflowNode) -> some View {
        Text("Workflow endpoint")
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(InspectorDesign.textTertiary(isDark: themeManager.isDarkMode))
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(InspectorDesign.bg900(isDark: themeManager.isDarkMode).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius))
    }

    // MARK: - Ports Section

    @ViewBuilder
    private func portsSection(_ node: WorkflowNode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !node.inputs.isEmpty {
                Text("INPUTS")
                    .font(.system(size: 9, weight: .semibold, design: .default))
                    .tracking(0.5)
                    .foregroundColor(InspectorDesign.textSecondary(isDark: themeManager.isDarkMode))
                    .textCase(.uppercase)

                ForEach(node.inputs) { port in
                    portRow(port, connections: connectionsForPort(nodeId: node.id, portId: port.id))
                }
            }

            if !node.outputs.isEmpty {
                Text("OUTPUTS")
                    .font(.system(size: 9, weight: .semibold, design: .default))
                    .tracking(0.5)
                    .foregroundColor(InspectorDesign.textSecondary(isDark: themeManager.isDarkMode))
                    .textCase(.uppercase)
                    .padding(.top, 4)

                ForEach(node.outputs) { port in
                    portRow(port, connections: connectionsForPort(nodeId: node.id, portId: port.id))
                }
            }
        }
    }

    @ViewBuilder
    private func portRow(_ port: Port, connections: [WorkflowConnection]) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(connections.isEmpty ? InspectorDesign.border(isDark: themeManager.isDarkMode) : Color.blue)
                .frame(width: 8, height: 8)

            Text(port.label)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(InspectorDesign.textSecondary(isDark: themeManager.isDarkMode))

            Spacer()

            if !connections.isEmpty {
                Text("\(connections.count)")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(InspectorDesign.textTertiary(isDark: themeManager.isDarkMode))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(InspectorDesign.bg900(isDark: themeManager.isDarkMode))
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(InspectorDesign.bg900(isDark: themeManager.isDarkMode))
        .clipShape(RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius))
    }

    private func connectionsForPort(nodeId: UUID, portId: UUID) -> [WorkflowConnection] {
        state.connections.filter {
            ($0.sourceNodeId == nodeId && $0.sourcePortId == portId) ||
            ($0.targetNodeId == nodeId && $0.targetPortId == portId)
        }
    }

    // MARK: - Empty States

    @ViewBuilder
    private var emptySelectionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cursorarrow.click.2")
                .font(.system(size: 32))
                .foregroundColor(InspectorDesign.textTertiary(isDark: themeManager.isDarkMode))

            Text("NO SELECTION")
                .font(.system(size: 11, weight: .bold, design: .default))
                .tracking(1.0)
                .foregroundColor(InspectorDesign.textSecondary(isDark: themeManager.isDarkMode))

            Text("Select a node to inspect\nand edit its properties")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(InspectorDesign.textTertiary(isDark: themeManager.isDarkMode))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @ViewBuilder
    private var multiSelectionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 32))
                .foregroundColor(InspectorDesign.textTertiary(isDark: themeManager.isDarkMode))

            Text("\(state.selectedNodeIds.count) NODES SELECTED")
                .font(.system(size: 11, weight: .bold, design: .default))
                .tracking(1.0)
                .foregroundColor(InspectorDesign.textSecondary(isDark: themeManager.isDarkMode))

            Button(action: { state.removeSelectedNodes() }) {
                Text("DELETE SELECTED")
                    .font(.system(size: 10, weight: .semibold, design: .default))
                    .tracking(0.5)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Inspector Section

struct InspectorSection<Content: View>: View {
    let title: String
    let icon: String
    let id: String
    @Binding var expandedSections: Set<String>
    @ViewBuilder let content: () -> Content
    @Environment(ThemeManager.self) private var themeManager

    var isExpanded: Bool {
        expandedSections.contains(id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header button
            Button(action: { toggleExpanded() }) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(InspectorDesign.textTertiary(isDark: themeManager.isDarkMode))
                        .frame(width: 16, height: 16)

                    Text(title)
                        .font(.system(size: 10, weight: .semibold, design: .default))
                        .tracking(1.0)
                        .foregroundColor(InspectorDesign.textSecondary(isDark: themeManager.isDarkMode))

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(InspectorDesign.textTertiary(isDark: themeManager.isDarkMode))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
            }
            .buttonStyle(.plain)

            // Section content
            if isExpanded {
                Rectangle()
                    .fill(InspectorDesign.border(isDark: themeManager.isDarkMode).opacity(0.5))
                    .frame(height: 1)
                    .padding(.horizontal, 12)

                content()
                    .padding(12)
            }
        }
        .background(InspectorDesign.bg800(isDark: themeManager.isDarkMode))
        .clipShape(RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius)
                .strokeBorder(InspectorDesign.border(isDark: themeManager.isDarkMode).opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private func toggleExpanded() {
        if isExpanded {
            expandedSections.remove(id)
        } else {
            expandedSections.insert(id)
        }
    }
}

// MARK: - Inspector Field

struct InspectorField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .default))
                .tracking(0.3)
                .foregroundColor(InspectorDesign.textSecondary(isDark: themeManager.isDarkMode))

            content()
        }
    }
}

// MARK: - WF Text Field Style

struct WFTextFieldStyle: TextFieldStyle {
    let isDark: Bool

    init(isDark: Bool = true) {
        self.isDark = isDark
    }

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .foregroundColor(InspectorDesign.textPrimary(isDark: isDark))
            .background(
                RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius)
                    .fill(InspectorDesign.inputBg(isDark: isDark))
            )
            .overlay(
                RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius)
                    .strokeBorder(InspectorDesign.border(isDark: isDark), lineWidth: 1)
            )
    }
}

// MARK: - WF Text Editor

struct WFTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let height: CGFloat
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(InspectorDesign.textPrimary(isDark: themeManager.isDarkMode))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(InspectorDesign.textPlaceholder(isDark: themeManager.isDarkMode))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius)
                .fill(InspectorDesign.inputBg(isDark: themeManager.isDarkMode))
        )
        .overlay(
            RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius)
                .strokeBorder(InspectorDesign.border(isDark: themeManager.isDarkMode), lineWidth: 1)
        )
    }
}

// MARK: - WF Picker

struct WFPicker: View {
    @Binding var selection: String
    let options: [(value: String, label: String)]
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(options, id: \.value) { option in
                Text(option.label).tag(option.value)
            }
        }
        .pickerStyle(.menu)
        .font(.system(size: 11, design: .monospaced))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius)
                .fill(InspectorDesign.inputBg(isDark: themeManager.isDarkMode))
        )
        .overlay(
            RoundedRectangle(cornerRadius: InspectorDesign.cornerRadius)
                .strokeBorder(InspectorDesign.border(isDark: themeManager.isDarkMode), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Inspector View") {
    InspectorView(state: CanvasState.sampleState())
}
