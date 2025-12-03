import SwiftUI
import AppKit

// MARK: - Workflow Canvas View

struct WorkflowCanvas: View {
    @Bindable var state: CanvasState
    @State private var draggedNodeId: UUID?
    @State private var panDragOffset: CGSize = .zero
    @FocusState private var isFocused: Bool
    @State private var isSpacePressed: Bool = false
    @State private var isPanMode: Bool = false
    @State private var keyEventMonitor: Any?
    @State private var scrollEventMonitor: Any?
    @State private var canvasSize: CGSize = .zero
    @State private var zoomTimer: Timer?
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        canvasWithBasicKeyboard
            .contextMenu {
                canvasContextMenu
            }
            .onAppear {
                isFocused = true
                setupKeyboardMonitoring()
                startZoomInterpolation()
            }
            .onDisappear {
                cleanupKeyboardMonitoring()
                stopZoomInterpolation()
            }
    }

    @ViewBuilder
    private var canvasWithBasicKeyboard: some View {
        canvasGeometry
            .background(DesignSystem.Colors.canvasBackground(isDark: themeManager.isDarkMode))
            .focusable()
            .focused($isFocused)
            .focusEffectDisabled()
            .modifier(CanvasKeyboardModifier(
                state: state,
                onDelete: handleDelete,
                onArrowKey: handleArrowKey
            ))
    }

    // MARK: - Canvas Geometry (extracted to help type-checker)

    @ViewBuilder
    private var canvasGeometry: some View {
        GeometryReader { geometry in
            canvasStack(geometry: geometry)
                .clipped()
                .contentShape(Rectangle())
                .simultaneousGesture(backgroundPanGesture())
                .simultaneousGesture(magnificationGesture)
                .onTapGesture {
                    state.clearSelection()
                    isFocused = true
                }
                .coordinateSpace(name: "canvas")
                .onChange(of: geometry.size) { _, newSize in
                    canvasSize = newSize
                }
                .onAppear {
                    canvasSize = geometry.size
                }
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = state.scale * value
                state.targetScale = max(state.minScale, min(newScale, state.maxScale))
            }
    }

    @ViewBuilder
    private func canvasStack(geometry: GeometryProxy) -> some View {
        ZStack {
            // Background with grid
            CanvasBackground(scale: state.scale, offset: state.offset)

            // Canvas content (transformed)
            canvasContent
                .scaleEffect(state.scale, anchor: .topLeading)
                .offset(state.offset)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: state.scale)

            // Minimap overlay (bottom-right corner)
            minimapOverlay(canvasSize: geometry.size)

            // Pan mode indicator (top-left corner)
            panModeIndicator
        }
    }

    @ViewBuilder
    private func minimapOverlay(canvasSize: CGSize) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                MinimapView(
                    state: state,
                    canvasSize: canvasSize
                )
                .padding(16)
            }
        }
    }

    @ViewBuilder
    private var panModeIndicator: some View {
        if isPanMode {
            VStack {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 11))
                        Text("Pan Mode")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.8))
                    .clipShape(Capsule())
                    .shadow(radius: 4)
                    .padding(16)
                    Spacer()
                }
                Spacer()
            }
        }
    }

    // MARK: - Context Menus

    @ViewBuilder
    private var canvasContextMenu: some View {
        Menu("Add Node") {
            ForEach(NodeType.allCases) { nodeType in
                Button {
                    // Add node at center of visible area
                    let centerPoint = CGPoint(
                        x: -state.offset.width / state.scale + canvasSize.width / (2 * state.scale),
                        y: -state.offset.height / state.scale + canvasSize.height / (2 * state.scale)
                    )
                    state.addNode(type: nodeType, at: centerPoint)
                } label: {
                    Label(nodeType.rawValue, systemImage: nodeType.icon)
                }
            }
        }

        Divider()

        Button("Paste") {
            state.pasteNodes()
        }
        .keyboardShortcut("v", modifiers: .command)
        .disabled(!canPaste())

        Button("Select All") {
            state.selectAll()
        }
        .keyboardShortcut("a", modifiers: .command)

        Divider()

        Button("Zoom to Fit") {
            state.zoomToFit(in: canvasSize)
        }
        .keyboardShortcut("0", modifiers: .command)

        Button("Reset View") {
            state.resetView()
        }
    }

    private func canPaste() -> Bool {
        let pasteboard = NSPasteboard.general
        guard let jsonString = pasteboard.string(forType: .string),
              let data = jsonString.data(using: .utf8),
              let _ = try? JSONDecoder().decode(WorkflowData.self, from: data) else {
            return false
        }
        return true
    }

    // MARK: - Event Monitoring

    private func startZoomInterpolation() {
        zoomTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            // Smooth interpolation toward target scale
            let difference = state.targetScale - state.scale
            if abs(difference) > 0.001 {
                // Exponential easing
                state.scale += difference * 0.15
            } else if difference != 0 {
                state.scale = state.targetScale
            }
        }
    }

    private func stopZoomInterpolation() {
        zoomTimer?.invalidate()
        zoomTimer = nil
    }

    private func setupKeyboardMonitoring() {
        // Monitor key events for space bar (pan mode) and command keys
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { event in
            // Space bar for pan mode
            if event.keyCode == 49 { // Space bar
                if event.type == .keyDown && !self.isSpacePressed {
                    self.isSpacePressed = true
                    self.isPanMode = true
                    NSCursor.openHand.push()
                } else if event.type == .keyUp && self.isSpacePressed {
                    self.isSpacePressed = false
                    self.isPanMode = false
                    NSCursor.pop()
                }
            }

            // Command key shortcuts (only on keyDown)
            if event.type == .keyDown && event.modifierFlags.contains(.command) {
                switch event.charactersIgnoringModifiers?.lowercased() {
                case "c":
                    self.state.copySelectedNodes()
                    return nil // Consume event
                case "v":
                    self.state.pasteNodes()
                    return nil
                case "d":
                    self.state.duplicateSelectedNodes()
                    return nil
                case "a":
                    self.state.selectAll()
                    return nil
                default:
                    break
                }
            }
            return event
        }

        // Monitor scroll wheel for zooming
        scrollEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            self.handleScrollWheel(event: event)
            return event
        }
    }

    private func cleanupKeyboardMonitoring() {
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyEventMonitor = nil
        }
        if let monitor = scrollEventMonitor {
            NSEvent.removeMonitor(monitor)
            scrollEventMonitor = nil
        }
        if isPanMode {
            NSCursor.pop()
            isPanMode = false
            isSpacePressed = false
        }
    }

    private func handleScrollWheel(event: NSEvent) {
        // Scroll to zoom: up = zoom in, down = zoom out
        let zoomDelta = event.scrollingDeltaY * 0.01
        let scaleFactor = 1.0 + zoomDelta

        let newScale = state.targetScale * scaleFactor
        state.targetScale = max(state.minScale, min(newScale, state.maxScale))
    }

    // MARK: - Canvas Content

    @ViewBuilder
    private var canvasContent: some View {
        ZStack {
            // Connections layer (below nodes)
            connectionsLayer

            // Pending connection while dragging
            if let pending = state.pendingConnection {
                let isSnapped = state.hoveredPortId != nil && state.validDropPortIds.contains(state.hoveredPortId ?? UUID())
                PendingConnectionView(
                    from: pending.sourceAnchor.position,
                    to: pending.currentPoint,
                    color: isSnapped ? .green : .blue
                )
            }

            // Nodes layer
            nodesLayer
        }
    }

    // MARK: - Connections Layer

    @ViewBuilder
    private var connectionsLayer: some View {
        // Preview connections for valid drop ports when dragging
        if let pending = state.pendingConnection,
           !state.validDropPortIds.isEmpty {
            ForEach(Array(state.validDropPortIds), id: \.self) { portId in
                if let (_, targetPos) = findPortPosition(portId: portId) {
                    // Show faint preview curve to nearby valid ports
                    let distance = hypot(
                        pending.currentPoint.x - targetPos.x,
                        pending.currentPoint.y - targetPos.y
                    )
                    // Only show preview if within reasonable range
                    if distance < 400 {
                        ConnectionPreviewView(
                            from: pending.sourceAnchor.position,
                            to: targetPos,
                            color: .blue.opacity(0.2)
                        )
                    }
                }
            }
        }

        // Actual connections with gradients
        ForEach(state.connections) { connection in
            if let startPos = state.portPosition(nodeId: connection.sourceNodeId, portId: connection.sourcePortId),
               let endPos = state.portPosition(nodeId: connection.targetNodeId, portId: connection.targetPortId) {
                let sourceNode = state.nodes.first(where: { $0.id == connection.sourceNodeId })
                let targetNode = state.nodes.first(where: { $0.id == connection.targetNodeId })
                ConnectionView(
                    from: startPos,
                    to: endPos,
                    color: sourceNode?.type.color.opacity(0.8) ?? .gray,
                    sourceColor: sourceNode?.type.color,
                    targetColor: targetNode?.type.color,
                    isSelected: state.selectedConnectionId == connection.id,
                    isHovered: state.hoveredConnectionId == connection.id
                )
                .contentShape(ConnectionHitShape(from: startPos, to: endPos, tolerance: 10))
                .onTapGesture {
                    handleConnectionTap(connection)
                }
                .onHover { isHovered in
                    if !state.isDragging {
                        state.hoveredConnectionId = isHovered ? connection.id : nil
                    }
                }
                .contextMenu {
                    Button("Delete Connection") {
                        state.removeConnection(connection.id)
                    }
                }
            }
        }
    }

    private func connectionColor(for connection: WorkflowConnection) -> Color {
        if let node = state.nodes.first(where: { $0.id == connection.sourceNodeId }) {
            return node.type.color.opacity(0.8)
        }
        return .gray
    }

    // Helper to find port position by portId
    private func findPortPosition(portId: UUID) -> (UUID, CGPoint)? {
        for node in state.nodes {
            if let pos = state.portPosition(nodeId: node.id, portId: portId) {
                return (node.id, pos)
            }
        }
        return nil
    }

    // MARK: - Nodes Layer

    @ViewBuilder
    private var nodesLayer: some View {
        ForEach(state.nodes) { node in
            NodeView(
                node: node,
                isSelected: state.selectedNodeIds.contains(node.id),
                isHovered: state.hoveredNodeId == node.id,
                canvasState: state,
                onPortDragStart: { anchor in
                    state.pendingConnection = PendingConnection(from: anchor)
                    state.updateValidDropPorts(for: anchor)
                },
                onPortDragUpdate: { canvasPoint in
                    // Implement magnetic snapping to nearby valid ports
                    let snapThreshold: CGFloat = 25
                    var snappedPoint = canvasPoint
                    var closestDistance: CGFloat = snapThreshold

                    // Find the nearest valid port
                    for portId in state.validDropPortIds {
                        if let (_, portPos) = findPortPosition(portId: portId) {
                            let distance = hypot(
                                canvasPoint.x - portPos.x,
                                canvasPoint.y - portPos.y
                            )
                            if distance < closestDistance {
                                closestDistance = distance
                                snappedPoint = portPos
                            }
                        }
                    }

                    state.pendingConnection?.currentPoint = snappedPoint

                    // Update snapped port ID for visual feedback
                    if closestDistance < snapThreshold {
                        // Find which port we're snapped to
                        for portId in state.validDropPortIds {
                            if let (_, portPos) = findPortPosition(portId: portId),
                               hypot(snappedPoint.x - portPos.x, snappedPoint.y - portPos.y) < 1 {
                                state.hoveredPortId = portId
                                break
                            }
                        }
                    }
                },
                onPortDragEnd: { targetAnchor in
                    completePendingConnection(to: targetAnchor)
                },
                onPortHover: { portId in
                    state.hoveredPortId = portId
                },
                onNodeUpdate: { updatedNode in
                    state.updateNode(updatedNode)
                }
            )
            .contentShape(Rectangle())
            .highPriorityGesture(nodeDragGesture(for: node))
            .onTapGesture {
                handleNodeTap(node)
            }
            .onHover { isHovered in
                if !state.isDragging {
                    state.hoveredNodeId = isHovered ? node.id : nil
                }
            }
            .position(
                x: node.position.x + node.size.width / 2,
                y: node.position.y + node.size.height / 2
            )
        }
    }

    // MARK: - Gestures

    private func backgroundPanGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                // Only pan if we're not dragging a node
                guard !state.isDragging else { return }

                state.isPanning = true
                let delta = CGSize(
                    width: value.translation.width - panDragOffset.width,
                    height: value.translation.height - panDragOffset.height
                )
                state.offset.width += delta.width
                state.offset.height += delta.height
                panDragOffset = value.translation
            }
            .onEnded { _ in
                state.isPanning = false
                panDragOffset = .zero
            }
    }

    @State private var dragStartLocation: CGPoint? = nil

    private func nodeDragGesture(for node: WorkflowNode) -> some Gesture {
        DragGesture(minimumDistance: 3, coordinateSpace: .named("canvas"))
            .onChanged { value in
                // Skip if in pan mode
                guard !isPanMode else { return }

                // First drag frame: setup and capture start location
                if !state.isDragging {
                    state.isDragging = true
                    state.beginNodeMove()
                    draggedNodeId = node.id
                    dragStartLocation = value.startLocation

                    // Select node if not already selected
                    if !state.selectedNodeIds.contains(node.id) {
                        state.selectNode(node.id, exclusive: true)
                    }
                }

                // Calculate delta from fixed start location (not translation which can oscillate)
                guard let startLoc = dragStartLocation else { return }
                let delta = CGSize(
                    width: (value.location.x - startLoc.x) / state.scale,
                    height: (value.location.y - startLoc.y) / state.scale
                )
                state.moveSelectedNodesFromSnapshot(by: delta)
            }
            .onEnded { _ in
                state.endNodeMove()
                state.isDragging = false
                draggedNodeId = nil
                dragStartLocation = nil

                // Snap to grid on release (unless Shift held)
                if !NSEvent.modifierFlags.contains(.shift) {
                    state.snapSelectedNodesToGrid()
                }
            }
    }

    // MARK: - Event Handlers

    enum ArrowDirection {
        case up, down, left, right
    }

    private func handleArrowKey(direction: ArrowDirection) {
        guard state.hasSelection else { return }

        let modifiers = NSEvent.modifierFlags

        // Determine nudge amount based on modifiers
        let nudgeAmount: CGFloat
        if modifiers.contains(.shift) {
            // Shift: 1px for fine control
            nudgeAmount = 1
        } else if modifiers.contains(.command) {
            // Cmd: 5x grid (100px) for large moves
            nudgeAmount = 100
        } else {
            // Default: grid size (20px)
            nudgeAmount = 20
        }

        // Calculate delta based on direction
        let delta: CGSize
        switch direction {
        case .up:
            delta = CGSize(width: 0, height: -nudgeAmount)
        case .down:
            delta = CGSize(width: 0, height: nudgeAmount)
        case .left:
            delta = CGSize(width: -nudgeAmount, height: 0)
        case .right:
            delta = CGSize(width: nudgeAmount, height: 0)
        }

        state.nudgeSelectedNodes(by: delta)
    }

    private func handleNodeTap(_ node: WorkflowNode) {
        if NSEvent.modifierFlags.contains(.command) {
            state.toggleNodeSelection(node.id)
        } else if NSEvent.modifierFlags.contains(.shift) {
            state.selectNode(node.id, exclusive: false)
        } else {
            state.selectNode(node.id, exclusive: true)
        }
    }

    private func completePendingConnection(to targetAnchor: ConnectionAnchor?) {
        defer {
            state.pendingConnection = nil
            state.validDropPortIds.removeAll()
        }

        guard let pending = state.pendingConnection,
              let target = targetAnchor else { return }

        // Validate connection using CanvasState validation
        let source = pending.sourceAnchor
        guard state.canConnect(from: source, to: target) else { return }

        // Determine which is source and which is target
        let (outputAnchor, inputAnchor) = source.isInput ? (target, source) : (source, target)

        let connection = WorkflowConnection(
            sourceNodeId: outputAnchor.nodeId,
            sourcePortId: outputAnchor.portId,
            targetNodeId: inputAnchor.nodeId,
            targetPortId: inputAnchor.portId
        )

        state.addConnection(connection)
    }

    private func handleConnectionTap(_ connection: WorkflowConnection) {
        state.selectConnection(connection.id)
    }

    private func handleDelete() {
        if let selectedConnectionId = state.selectedConnectionId {
            // Delete selected connection
            state.removeConnection(selectedConnectionId)
            state.deselectConnection()
        } else if !state.selectedNodeIds.isEmpty {
            // Delete selected nodes
            state.removeSelectedNodes()
        }
    }

}

// MARK: - Connection Hit Shape

struct ConnectionHitShape: Shape {
    let from: CGPoint
    let to: CGPoint
    let tolerance: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Create bezier curve (same as ConnectionView)
        let dx = to.x - from.x
        let dy = to.y - from.y
        let distance = sqrt(dx * dx + dy * dy)

        var controlOffset: CGFloat
        if abs(dx) < 50 {
            controlOffset = max(abs(dy) * 0.3, 80)
        } else if abs(dy) < 50 {
            controlOffset = min(abs(dx) * 0.5, distance * 0.4)
        } else {
            controlOffset = min(max(abs(dx) * 0.4, 100), distance * 0.45)
        }

        let control1 = CGPoint(x: from.x + controlOffset, y: from.y)
        let control2 = CGPoint(x: to.x - controlOffset, y: to.y)

        path.move(to: from)
        path.addCurve(to: to, control1: control1, control2: control2)

        return path.strokedPath(StrokeStyle(lineWidth: tolerance * 2, lineCap: .round))
    }
}

// MARK: - Canvas Background

struct CanvasBackground: View {
    let scale: CGFloat
    let offset: CGSize
    @Environment(ThemeManager.self) private var themeManager

    private let gridSize: CGFloat = 20
    private let majorGridInterval: Int = 5
    private let parallaxFactor: CGFloat = 0.95

    var body: some View {
        ZStack {
            // Theme-adaptive background
            DesignSystem.Colors.canvasBackground(isDark: themeManager.isDarkMode)

            // Dot grid with parallax
            Canvas { context, size in
                // Apply parallax to offset
                let parallaxOffset = CGSize(
                    width: offset.width * parallaxFactor,
                    height: offset.height * parallaxFactor
                )

                let scaledGridSize = gridSize * scale
                let startX = -parallaxOffset.width.truncatingRemainder(dividingBy: scaledGridSize)
                let startY = -parallaxOffset.height.truncatingRemainder(dividingBy: scaledGridSize)

                // Draw dot grid
                drawDotGrid(
                    context: context,
                    size: size,
                    startX: startX,
                    startY: startY,
                    gridSize: scaledGridSize
                )
            }
            .drawingGroup() // Performance optimization
        }
    }

    private func drawDotGrid(
        context: GraphicsContext,
        size: CGSize,
        startX: CGFloat,
        startY: CGFloat,
        gridSize: CGFloat
    ) {
        let minorDotRadius: CGFloat = 1.0
        let majorDotRadius: CGFloat = 1.5
        // Theme-adaptive grid dots
        let minorDotColor = DesignSystem.Colors.gridDot(isDark: themeManager.isDarkMode).opacity(0.45)
        let majorDotColor = DesignSystem.Colors.gridDot(isDark: themeManager.isDarkMode).opacity(0.5)

        var row = 0
        var y = startY
        while y < size.height + gridSize {
            var col = 0
            var x = startX
            while x < size.width + gridSize {
                // Major dot every 5 grid units
                let isMajor = (row % majorGridInterval == 0) && (col % majorGridInterval == 0)
                let dotRadius = isMajor ? majorDotRadius : minorDotRadius
                let dotColor = isMajor ? majorDotColor : minorDotColor

                let dotRect = CGRect(
                    x: x - dotRadius,
                    y: y - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                )

                context.fill(
                    Path(ellipseIn: dotRect),
                    with: .color(dotColor)
                )

                x += gridSize
                col += 1
            }
            y += gridSize
            row += 1
        }
    }
}

// MARK: - Canvas Keyboard Modifier

struct CanvasKeyboardModifier: ViewModifier {
    @Bindable var state: CanvasState
    let onDelete: () -> Void
    let onArrowKey: (WorkflowCanvas.ArrowDirection) -> Void

    func body(content: Content) -> some View {
        content
            .onKeyPress(.delete) {
                onDelete()
                return .handled
            }
            .onKeyPress(.deleteForward) {
                onDelete()
                return .handled
            }
            .onKeyPress(.escape) {
                state.clearSelection()
                return .handled
            }
            .onKeyPress(.tab) {
                handleTab()
                return .handled
            }
            .modifier(ArrowKeyModifier(onArrowKey: onArrowKey))
    }

    private func handleTab() {
        if NSEvent.modifierFlags.contains(.shift) {
            state.selectPreviousNode()
        } else {
            state.selectNextNode()
        }
    }
}

// MARK: - Arrow Key Modifier

struct ArrowKeyModifier: ViewModifier {
    let onArrowKey: (WorkflowCanvas.ArrowDirection) -> Void

    func body(content: Content) -> some View {
        content
            .onKeyPress(.upArrow) {
                onArrowKey(.up)
                return .handled
            }
            .onKeyPress(.downArrow) {
                onArrowKey(.down)
                return .handled
            }
            .onKeyPress(.leftArrow) {
                onArrowKey(.left)
                return .handled
            }
            .onKeyPress(.rightArrow) {
                onArrowKey(.right)
                return .handled
            }
    }
}


