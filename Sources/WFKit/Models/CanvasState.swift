import Foundation
import SwiftUI
import AppKit

// MARK: - Canvas Snapshot (for Undo/Redo)

public struct CanvasSnapshot: Equatable, Sendable {
    public let nodes: [WorkflowNode]
    public let connections: [WorkflowConnection]
    public let selectedNodeIds: Set<UUID>

    public static func == (lhs: CanvasSnapshot, rhs: CanvasSnapshot) -> Bool {
        lhs.nodes == rhs.nodes &&
        lhs.connections == rhs.connections &&
        lhs.selectedNodeIds == rhs.selectedNodeIds
    }
}

// MARK: - Serializable Data

public struct WorkflowData: Codable, Sendable {
    public var nodes: [WorkflowNode]
    public var connections: [WorkflowConnection]

    public init(nodes: [WorkflowNode], connections: [WorkflowConnection]) {
        self.nodes = nodes
        self.connections = connections
    }
}

// MARK: - Canvas State (Observable)

@Observable
public final class CanvasState {
    // MARK: - Workflow Data
    public var nodes: [WorkflowNode] = []
    public var connections: [WorkflowConnection] = []

    // MARK: - Canvas Transform
    public var offset: CGSize = .zero
    public var scale: CGFloat = 1.0
    public var minScale: CGFloat = 0.25
    public var maxScale: CGFloat = 3.0
    public var targetScale: CGFloat = 1.0 // For smooth zoom animations

    // MARK: - Selection State
    public var selectedNodeIds: Set<UUID> = []
    public var hoveredNodeId: UUID? = nil
    public var selectedConnectionId: UUID? = nil
    public var hoveredConnectionId: UUID? = nil

    // MARK: - Connection State
    public var pendingConnection: PendingConnection? = nil
    public var hoveredPortId: UUID? = nil
    public var validDropPortIds: Set<UUID> = []

    // MARK: - Interaction State
    public var isDragging: Bool = false
    public var isPanning: Bool = false

    // MARK: - Drag Snapshot (for smooth dragging from initial position)
    private var dragSnapshot: [UUID: CGPoint] = [:]

    // MARK: - Undo/Redo State
    private var undoStack: [CanvasSnapshot] = []
    private var redoStack: [CanvasSnapshot] = []
    private let maxUndoStackSize = 50
    private var isPerformingUndoRedo = false

    // MARK: - Initialization

    public init() {}

    // MARK: - Computed Properties

    public var selectedNodes: [WorkflowNode] {
        nodes.filter { selectedNodeIds.contains($0.id) }
    }

    public var hasSelection: Bool {
        !selectedNodeIds.isEmpty
    }

    public var singleSelectedNode: WorkflowNode? {
        guard selectedNodeIds.count == 1,
              let id = selectedNodeIds.first else { return nil }
        return nodes.first { $0.id == id }
    }

    public var canUndo: Bool {
        !undoStack.isEmpty
    }

    public var canRedo: Bool {
        !redoStack.isEmpty
    }

    // MARK: - Undo/Redo Operations

    private func createSnapshot() -> CanvasSnapshot {
        CanvasSnapshot(
            nodes: nodes,
            connections: connections,
            selectedNodeIds: selectedNodeIds
        )
    }

    private func restoreSnapshot(_ snapshot: CanvasSnapshot) {
        isPerformingUndoRedo = true
        nodes = snapshot.nodes
        connections = snapshot.connections
        selectedNodeIds = snapshot.selectedNodeIds
        isPerformingUndoRedo = false
    }

    private func saveSnapshot() {
        guard !isPerformingUndoRedo else { return }

        let snapshot = createSnapshot()

        // Don't save if nothing changed
        if let lastSnapshot = undoStack.last, lastSnapshot == snapshot {
            return
        }

        undoStack.append(snapshot)

        // Limit stack size
        if undoStack.count > maxUndoStackSize {
            undoStack.removeFirst()
        }

        // Clear redo stack on new action
        redoStack.removeAll()
    }

    public func undo() {
        guard !undoStack.isEmpty else { return }

        // Save current state to redo stack
        redoStack.append(createSnapshot())

        // Restore previous state
        let snapshot = undoStack.removeLast()
        restoreSnapshot(snapshot)
    }

    public func redo() {
        guard !redoStack.isEmpty else { return }

        // Save current state to undo stack
        undoStack.append(createSnapshot())

        // Restore next state
        let snapshot = redoStack.removeLast()
        restoreSnapshot(snapshot)
    }

    // MARK: - Node Operations

    public func addNode(_ node: WorkflowNode) {
        saveSnapshot()
        nodes.append(node)
    }

    public func addNode(type: NodeType, at position: CGPoint) {
        saveSnapshot()
        let node = WorkflowNode(type: type, position: position)
        nodes.append(node)
        selectNode(node.id, exclusive: true)
    }

    // MARK: - Convenience API (Auto-positioned)

    /// Add a node without specifying position - use autoLayout() after adding all nodes
    @discardableResult
    public func addNode(
        type: NodeType,
        title: String? = nil,
        configuration: NodeConfiguration = NodeConfiguration(),
        position: CGPoint? = nil
    ) -> WorkflowNode {
        saveSnapshot()
        let node = WorkflowNode(
            type: type,
            title: title,
            position: position ?? nextAutoPosition(),
            configuration: configuration
        )
        nodes.append(node)
        return node
    }

    /// Connect two nodes using first available output → first available input
    public func connect(_ source: WorkflowNode, to target: WorkflowNode) {
        guard let sourcePort = source.outputs.first,
              let targetPort = target.inputs.first else { return }

        let connection = WorkflowConnection(
            sourceNodeId: source.id,
            sourcePortId: sourcePort.id,
            targetNodeId: target.id,
            targetPortId: targetPort.id
        )
        addConnection(connection)
    }

    /// Connect from a specific named output port to target's input
    public func connect(_ source: WorkflowNode, port portLabel: String, to target: WorkflowNode) {
        guard let sourcePort = source.outputs.first(where: { $0.label == portLabel }),
              let targetPort = target.inputs.first else { return }

        let connection = WorkflowConnection(
            sourceNodeId: source.id,
            sourcePortId: sourcePort.id,
            targetNodeId: target.id,
            targetPortId: targetPort.id
        )
        addConnection(connection)
    }

    /// Auto-layout all nodes based on graph structure (left-to-right flow)
    public func autoLayout(spacing: CGSize = CGSize(width: 280, height: 160), origin: CGPoint = CGPoint(x: 100, y: 100)) {
        guard !nodes.isEmpty else { return }

        // Build adjacency for topological sort
        var inDegree: [UUID: Int] = [:]
        var outEdges: [UUID: [UUID]] = [:]

        for node in nodes {
            inDegree[node.id] = 0
            outEdges[node.id] = []
        }

        for conn in connections {
            inDegree[conn.targetNodeId, default: 0] += 1
            outEdges[conn.sourceNodeId, default: []].append(conn.targetNodeId)
        }

        // Kahn's algorithm for topological levels
        var levels: [[UUID]] = []
        var queue = nodes.filter { inDegree[$0.id] == 0 }.map { $0.id }
        var remaining = inDegree

        while !queue.isEmpty {
            levels.append(queue)
            var nextQueue: [UUID] = []

            for nodeId in queue {
                for targetId in outEdges[nodeId] ?? [] {
                    remaining[targetId, default: 0] -= 1
                    if remaining[targetId] == 0 {
                        nextQueue.append(targetId)
                    }
                }
            }
            queue = nextQueue
        }

        // Handle any remaining nodes (cycles or disconnected)
        let positioned = Set(levels.flatMap { $0 })
        let unpositioned = nodes.filter { !positioned.contains($0.id) }.map { $0.id }
        if !unpositioned.isEmpty {
            levels.append(unpositioned)
        }

        // Position nodes by level
        for (col, level) in levels.enumerated() {
            for (row, nodeId) in level.enumerated() {
                if let index = nodes.firstIndex(where: { $0.id == nodeId }) {
                    nodes[index].position = CGPoint(
                        x: origin.x + CGFloat(col) * spacing.width,
                        y: origin.y + CGFloat(row) * spacing.height
                    )
                }
            }
        }
    }

    /// Get next auto-position for incrementally added nodes
    private func nextAutoPosition() -> CGPoint {
        guard let lastNode = nodes.last else {
            return CGPoint(x: 100, y: 100)
        }
        // Stack vertically with some offset
        return CGPoint(
            x: lastNode.position.x,
            y: lastNode.position.y + lastNode.size.height + 40
        )
    }

    public func removeNode(_ id: UUID) {
        saveSnapshot()
        nodes.removeAll { $0.id == id }
        // Remove connections involving this node
        connections.removeAll { $0.sourceNodeId == id || $0.targetNodeId == id }
        selectedNodeIds.remove(id)
    }

    public func removeSelectedNodes() {
        guard !selectedNodeIds.isEmpty else { return }
        saveSnapshot()
        for id in selectedNodeIds {
            // Don't save snapshot for each individual removal
            let currentFlag = isPerformingUndoRedo
            isPerformingUndoRedo = true
            nodes.removeAll { $0.id == id }
            connections.removeAll { $0.sourceNodeId == id || $0.targetNodeId == id }
            isPerformingUndoRedo = currentFlag
        }
        selectedNodeIds.removeAll()
    }

    public func updateNode(_ node: WorkflowNode) {
        saveSnapshot()
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes[index] = node
        }
    }

    public func moveNode(_ id: UUID, to position: CGPoint) {
        if let index = nodes.firstIndex(where: { $0.id == id }) {
            nodes[index].position = position
        }
    }

    public func moveSelectedNodes(by delta: CGSize) {
        for id in selectedNodeIds {
            if let index = nodes.firstIndex(where: { $0.id == id }) {
                nodes[index].position.x += delta.width
                nodes[index].position.y += delta.height
            }
        }
    }

    public func beginNodeMove() {
        saveSnapshot()
        // Capture initial positions of selected nodes
        dragSnapshot.removeAll()
        for id in selectedNodeIds {
            if let node = nodes.first(where: { $0.id == id }) {
                dragSnapshot[id] = node.position
            }
        }
    }

    public func moveSelectedNodesFromSnapshot(by delta: CGSize) {
        for id in selectedNodeIds {
            if let index = nodes.firstIndex(where: { $0.id == id }),
               let initialPosition = dragSnapshot[id] {
                nodes[index].position = CGPoint(
                    x: initialPosition.x + delta.width,
                    y: initialPosition.y + delta.height
                )
            }
        }
    }

    public func endNodeMove() {
        dragSnapshot.removeAll()
    }

    // MARK: - Selection Operations

    public func selectNode(_ id: UUID, exclusive: Bool = false) {
        if exclusive {
            selectedNodeIds = [id]
        } else {
            selectedNodeIds.insert(id)
        }
    }

    public func deselectNode(_ id: UUID) {
        selectedNodeIds.remove(id)
    }

    public func toggleNodeSelection(_ id: UUID) {
        if selectedNodeIds.contains(id) {
            selectedNodeIds.remove(id)
        } else {
            selectedNodeIds.insert(id)
        }
    }

    public func clearSelection() {
        selectedNodeIds.removeAll()
        selectedConnectionId = nil
    }

    public func selectAll() {
        selectedNodeIds = Set(nodes.map { $0.id })
    }

    public func selectConnection(_ id: UUID) {
        selectedConnectionId = id
        selectedNodeIds.removeAll() // Deselect nodes when selecting a connection
    }

    public func deselectConnection() {
        selectedConnectionId = nil
    }

    // MARK: - Connection Operations

    /// The connection currently being reconnected (if any)
    public var reconnectingConnection: WorkflowConnection? = nil

    /// Start reconnecting an existing connection by dragging one of its endpoints
    /// - Parameters:
    ///   - connection: The connection to reconnect
    ///   - draggingSource: If true, dragging the source endpoint. If false, dragging the target endpoint.
    public func startReconnection(_ connection: WorkflowConnection, fromSource draggingSource: Bool) {
        WFLogger.connection("START reconnection", details: "draggingSource=\(draggingSource), id=\(connection.id.uuidString.prefix(8))")

        // Store the connection being reconnected (keep it in the array, just mark it)
        reconnectingConnection = connection

        // Get the anchor position for the fixed end (the end that's NOT being dragged)
        let anchorNodeId: UUID
        let anchorPortId: UUID
        let isInput: Bool

        if draggingSource {
            // Dragging the source endpoint → target stays fixed
            // The fixed anchor is the target (an input port)
            anchorNodeId = connection.targetNodeId
            anchorPortId = connection.targetPortId
            isInput = true // Target is an input port
            WFLogger.debug("Anchor: TARGET (input port)", category: .connection)
        } else {
            // Dragging the target endpoint → source stays fixed
            // The fixed anchor is the source (an output port)
            anchorNodeId = connection.sourceNodeId
            anchorPortId = connection.sourcePortId
            isInput = false // Source is an output port
            WFLogger.debug("Anchor: SOURCE (output port)", category: .connection)
        }

        guard let anchorPosition = portPosition(nodeId: anchorNodeId, portId: anchorPortId) else {
            WFLogger.error("Failed to get anchor position!", category: .connection)
            reconnectingConnection = nil
            return
        }

        WFLogger.debug("Anchor position: \(anchorPosition)", category: .connection)

        // Create the pending connection from the fixed anchor
        let anchor = ConnectionAnchor(
            nodeId: anchorNodeId,
            portId: anchorPortId,
            position: anchorPosition,
            isInput: isInput
        )

        pendingConnection = PendingConnection(from: anchor)
        updateValidDropPorts(for: anchor)

        WFLogger.info("Valid drop ports: \(validDropPortIds.count)", category: .connection)
    }

    /// Complete or cancel a reconnection
    public func completeReconnection(to targetAnchor: ConnectionAnchor?) {
        WFLogger.connection("END reconnection", details: "targetAnchor=\(targetAnchor != nil ? "provided" : "nil")")

        defer {
            WFLogger.debug("Cleanup: clearing state", category: .connection)
            pendingConnection = nil
            validDropPortIds.removeAll()
            reconnectingConnection = nil
            hoveredPortId = nil
        }

        guard let pending = pendingConnection,
              let originalConnection = reconnectingConnection else {
            WFLogger.error("No pending connection or original connection!", category: .connection)
            return
        }

        if let target = targetAnchor {
            WFLogger.debug("Target: nodeId=\(target.nodeId.uuidString.prefix(8)), isInput=\(target.isInput)", category: .connection)
            // Exclude the original connection from duplicate check (we're replacing it)
            let canConnectResult = canConnect(from: pending.sourceAnchor, to: target, excluding: originalConnection.id)
            WFLogger.debug("canConnect: \(canConnectResult)", category: .connection)

            if canConnectResult {
                saveSnapshot()

                // Remove the original connection
                connections.removeAll { $0.id == originalConnection.id }

                let source = pending.sourceAnchor
                let (outputAnchor, inputAnchor) = source.isInput ? (target, source) : (source, target)

                let newConnection = WorkflowConnection(
                    sourceNodeId: outputAnchor.nodeId,
                    sourcePortId: outputAnchor.portId,
                    targetNodeId: inputAnchor.nodeId,
                    targetPortId: inputAnchor.portId
                )
                // Use withAnimation to ensure the connection appears immediately
                withAnimation(.easeOut(duration: 0.2)) {
                    connections.append(newConnection)
                }
                WFLogger.info("Created new connection: \(newConnection.id.uuidString.prefix(8))", category: .connection)
            } else {
                WFLogger.warning("Cannot connect - keeping original", category: .connection)
            }
        } else {
            WFLogger.warning("No target - cancelled, keeping original", category: .connection)
        }
    }

    public func addConnection(_ connection: WorkflowConnection) {
        // Prevent duplicate connections
        guard !connections.contains(where: {
            $0.sourceNodeId == connection.sourceNodeId &&
            $0.sourcePortId == connection.sourcePortId &&
            $0.targetNodeId == connection.targetNodeId &&
            $0.targetPortId == connection.targetPortId
        }) else { return }

        // Prevent self-connections
        guard connection.sourceNodeId != connection.targetNodeId else { return }

        saveSnapshot()
        // Use withAnimation to ensure the connection appears immediately with a smooth entrance
        withAnimation(.easeOut(duration: 0.2)) {
            connections.append(connection)
        }
    }

    public func removeConnection(_ id: UUID) {
        saveSnapshot()
        connections.removeAll { $0.id == id }
    }

    public func removeConnectionsForPort(nodeId: UUID, portId: UUID) {
        saveSnapshot()
        connections.removeAll {
            ($0.sourceNodeId == nodeId && $0.sourcePortId == portId) ||
            ($0.targetNodeId == nodeId && $0.targetPortId == portId)
        }
    }

    /// Start a new connection from a port (initiated from inspector or programmatically)
    /// - Parameters:
    ///   - nodeId: The node containing the port
    ///   - portId: The port to start the connection from
    ///   - isInput: Whether the port is an input port
    public func startConnectionFromPort(nodeId: UUID, portId: UUID, isInput: Bool) {
        guard let position = portPosition(nodeId: nodeId, portId: portId) else { return }

        let anchor = ConnectionAnchor(
            nodeId: nodeId,
            portId: portId,
            position: position,
            isInput: isInput
        )

        pendingConnection = PendingConnection(from: anchor)
        updateValidDropPorts(for: anchor)
    }

    /// Complete a pending connection to a target port
    public func completeConnection(to targetNodeId: UUID, targetPortId: UUID, isInput: Bool) {
        defer {
            pendingConnection = nil
            validDropPortIds.removeAll()
            hoveredPortId = nil
        }

        guard let pending = pendingConnection,
              let targetPosition = portPosition(nodeId: targetNodeId, portId: targetPortId) else {
            return
        }

        let targetAnchor = ConnectionAnchor(
            nodeId: targetNodeId,
            portId: targetPortId,
            position: targetPosition,
            isInput: isInput
        )

        if canConnect(from: pending.sourceAnchor, to: targetAnchor) {
            saveSnapshot()

            let source = pending.sourceAnchor
            let (outputAnchor, inputAnchor) = source.isInput ? (targetAnchor, source) : (source, targetAnchor)

            let newConnection = WorkflowConnection(
                sourceNodeId: outputAnchor.nodeId,
                sourcePortId: outputAnchor.portId,
                targetNodeId: inputAnchor.nodeId,
                targetPortId: inputAnchor.portId
            )
            // Use withAnimation to ensure the connection appears immediately
            withAnimation(.easeOut(duration: 0.2)) {
                connections.append(newConnection)
            }
        }
    }

    /// Cancel the pending connection
    public func cancelPendingConnection() {
        pendingConnection = nil
        validDropPortIds.removeAll()
        hoveredPortId = nil
    }

    /// Check if we're in connection mode
    public var isConnecting: Bool {
        pendingConnection != nil
    }

    // MARK: - Canvas Operations

    public func resetView() {
        offset = .zero
        scale = 1.0
        targetScale = 1.0
    }

    public func zoomIn(animated: Bool = true) {
        let newScale = min(scale * 1.25, maxScale)
        if animated {
            targetScale = newScale
        } else {
            scale = newScale
            targetScale = newScale
        }
    }

    public func zoomOut(animated: Bool = true) {
        let newScale = max(scale / 1.25, minScale)
        if animated {
            targetScale = newScale
        } else {
            scale = newScale
            targetScale = newScale
        }
    }

    public func setZoom(to newScale: CGFloat, animated: Bool = true) {
        let clampedScale = max(minScale, min(newScale, maxScale))
        if animated {
            targetScale = clampedScale
        } else {
            scale = clampedScale
            targetScale = clampedScale
        }
    }

    public func zoomToFit(in size: CGSize, padding: CGFloat = 50) {
        guard !nodes.isEmpty else {
            resetView()
            return
        }

        // Calculate bounding box of all nodes
        let minX = nodes.map { $0.position.x }.min() ?? 0
        let maxX = nodes.map { $0.position.x + $0.size.width }.max() ?? 0
        let minY = nodes.map { $0.position.y }.min() ?? 0
        let maxY = nodes.map { $0.position.y + $0.size.height }.max() ?? 0

        let contentWidth = maxX - minX + padding * 2
        let contentHeight = maxY - minY + padding * 2

        let scaleX = size.width / contentWidth
        let scaleY = size.height / contentHeight
        scale = max(minScale, min(min(scaleX, scaleY), maxScale))
        targetScale = scale

        // Center the content
        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2
        offset = CGSize(
            width: size.width / 2 - centerX * scale,
            height: size.height / 2 - centerY * scale
        )
    }

    public func zoomToward(point: CGPoint, scaleFactor: CGFloat, canvasSize: CGSize) {
        let newScale = max(minScale, min(scale * scaleFactor, maxScale))

        // Calculate the canvas point under the cursor
        let canvasPointValue = canvasPoint(from: point)

        // Apply the new scale
        scale = newScale

        // Adjust offset to keep the canvas point under the cursor
        let newScreenPoint = screenPoint(from: canvasPointValue)
        offset.width += point.x - newScreenPoint.x
        offset.height += point.y - newScreenPoint.y
    }

    // MARK: - Grid Snapping

    public var gridSize: CGFloat = 20

    public func snapToGrid(_ point: CGPoint, gridSize: CGFloat? = nil) -> CGPoint {
        let size = gridSize ?? self.gridSize
        return CGPoint(
            x: round(point.x / size) * size,
            y: round(point.y / size) * size
        )
    }

    public func snapSelectedNodesToGrid(gridSize: CGFloat? = nil) {
        let size = gridSize ?? self.gridSize
        for id in selectedNodeIds {
            if let index = nodes.firstIndex(where: { $0.id == id }) {
                nodes[index].position = snapToGrid(nodes[index].position, gridSize: size)
            }
        }
    }

    // MARK: - Keyboard Navigation

    public func nudgeSelectedNodes(by delta: CGSize) {
        guard !selectedNodeIds.isEmpty else { return }
        saveSnapshot()
        moveSelectedNodes(by: delta)
    }

    public func selectNextNode() {
        guard !nodes.isEmpty else { return }

        if let currentId = selectedNodeIds.first,
           let currentIndex = nodes.firstIndex(where: { $0.id == currentId }) {
            let nextIndex = (currentIndex + 1) % nodes.count
            selectNode(nodes[nextIndex].id, exclusive: true)
        } else {
            // No selection, select first node
            selectNode(nodes[0].id, exclusive: true)
        }
    }

    public func selectPreviousNode() {
        guard !nodes.isEmpty else { return }

        if let currentId = selectedNodeIds.first,
           let currentIndex = nodes.firstIndex(where: { $0.id == currentId }) {
            let previousIndex = currentIndex == 0 ? nodes.count - 1 : currentIndex - 1
            selectNode(nodes[previousIndex].id, exclusive: true)
        } else {
            // No selection, select last node
            selectNode(nodes[nodes.count - 1].id, exclusive: true)
        }
    }

    // MARK: - Coordinate Conversion

    public func canvasPoint(from screenPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: (screenPoint.x - offset.width) / scale,
            y: (screenPoint.y - offset.height) / scale
        )
    }

    public func screenPoint(from canvasPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: canvasPoint.x * scale + offset.width,
            y: canvasPoint.y * scale + offset.height
        )
    }

    // MARK: - Hit Testing

    public func nodeAt(point: CGPoint) -> WorkflowNode? {
        // Return topmost node (last in array) at point
        nodes.last { node in
            let rect = CGRect(origin: node.position, size: node.size)
            return rect.contains(point)
        }
    }

    public func connectionAt(point: CGPoint, tolerance: CGFloat = 10) -> UUID? {
        // Iterate connections in reverse order (topmost first)
        for connection in connections.reversed() {
            guard let startPos = portPosition(nodeId: connection.sourceNodeId, portId: connection.sourcePortId),
                  let endPos = portPosition(nodeId: connection.targetNodeId, portId: connection.targetPortId) else {
                continue
            }

            if isPointNearBezierCurve(point: point, from: startPos, to: endPos, tolerance: tolerance) {
                return connection.id
            }
        }
        return nil
    }

    private func isPointNearBezierCurve(point: CGPoint, from start: CGPoint, to end: CGPoint, tolerance: CGFloat) -> Bool {
        // Calculate control points (same as ConnectionView bezierPath)
        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = sqrt(dx * dx + dy * dy)

        var controlOffset: CGFloat
        if abs(dx) < 50 {
            controlOffset = max(abs(dy) * 0.3, 80)
        } else if abs(dy) < 50 {
            controlOffset = min(abs(dx) * 0.5, distance * 0.4)
        } else {
            controlOffset = min(max(abs(dx) * 0.4, 100), distance * 0.45)
        }

        let control1 = CGPoint(x: start.x + controlOffset, y: start.y)
        let control2 = CGPoint(x: end.x - controlOffset, y: end.y)

        // Sample the bezier curve and find minimum distance
        let samples = 50
        var minDistance: CGFloat = .infinity

        for i in 0...samples {
            let t = CGFloat(i) / CGFloat(samples)
            let curvePoint = bezierPoint(t: t, p0: start, p1: control1, p2: control2, p3: end)
            let dist = hypot(point.x - curvePoint.x, point.y - curvePoint.y)
            minDistance = min(minDistance, dist)
        }

        return minDistance <= tolerance
    }

    private func bezierPoint(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let mt = 1 - t
        let mt2 = mt * mt
        let mt3 = mt2 * mt
        let t2 = t * t
        let t3 = t2 * t

        return CGPoint(
            x: mt3 * p0.x + 3 * mt2 * t * p1.x + 3 * mt * t2 * p2.x + t3 * p3.x,
            y: mt3 * p0.y + 3 * mt2 * t * p1.y + 3 * mt * t2 * p2.y + t3 * p3.y
        )
    }

    // MARK: - Port Positions

    public func portPosition(nodeId: UUID, portId: UUID) -> CGPoint? {
        guard let node = nodes.first(where: { $0.id == nodeId }) else { return nil }

        // Check inputs
        if let inputIndex = node.inputs.firstIndex(where: { $0.id == portId }) {
            let portHeight = node.size.height / CGFloat(node.inputs.count)
            let portCenterY = portHeight * CGFloat(inputIndex) + portHeight / 2
            return CGPoint(
                x: node.position.x,
                y: node.position.y + portCenterY
            )
        }

        // Check outputs
        if let outputIndex = node.outputs.firstIndex(where: { $0.id == portId }) {
            let portHeight = node.size.height / CGFloat(node.outputs.count)
            let portCenterY = portHeight * CGFloat(outputIndex) + portHeight / 2
            return CGPoint(
                x: node.position.x + node.size.width,
                y: node.position.y + portCenterY
            )
        }

        return nil
    }

    // MARK: - Port Hit Testing

    public func portAt(canvasPoint: CGPoint, tolerance: CGFloat = 15) -> (nodeId: UUID, portId: UUID, isInput: Bool)? {
        for node in nodes {
            // Check input ports
            for (index, port) in node.inputs.enumerated() {
                let portHeight = node.size.height / CGFloat(node.inputs.count)
                let portCenterY = portHeight * CGFloat(index) + portHeight / 2
                let portPos = CGPoint(
                    x: node.position.x,
                    y: node.position.y + portCenterY
                )

                let distance = sqrt(
                    pow(canvasPoint.x - portPos.x, 2) +
                    pow(canvasPoint.y - portPos.y, 2)
                )

                if distance <= tolerance {
                    return (nodeId: node.id, portId: port.id, isInput: true)
                }
            }

            // Check output ports
            for (index, port) in node.outputs.enumerated() {
                let portHeight = node.size.height / CGFloat(node.outputs.count)
                let portCenterY = portHeight * CGFloat(index) + portHeight / 2
                let portPos = CGPoint(
                    x: node.position.x + node.size.width,
                    y: node.position.y + portCenterY
                )

                let distance = sqrt(
                    pow(canvasPoint.x - portPos.x, 2) +
                    pow(canvasPoint.y - portPos.y, 2)
                )

                if distance <= tolerance {
                    return (nodeId: node.id, portId: port.id, isInput: false)
                }
            }
        }

        return nil
    }

    // MARK: - Connection Validation

    public func canConnect(from sourceAnchor: ConnectionAnchor, to targetAnchor: ConnectionAnchor, excluding excludedConnectionId: UUID? = nil) -> Bool {
        // Cannot connect a port to itself
        if sourceAnchor.nodeId == targetAnchor.nodeId && sourceAnchor.portId == targetAnchor.portId {
            return false
        }

        // Cannot connect two nodes to themselves (self-loop)
        if sourceAnchor.nodeId == targetAnchor.nodeId {
            return false
        }

        // Must connect input to output or output to input (not same type)
        if sourceAnchor.isInput == targetAnchor.isInput {
            return false
        }

        // Check if connection already exists (excluding the connection being reconnected)
        let (outputAnchor, inputAnchor) = sourceAnchor.isInput ? (targetAnchor, sourceAnchor) : (sourceAnchor, targetAnchor)

        let alreadyExists = connections.contains { connection in
            // Skip the connection being reconnected
            if let excludeId = excludedConnectionId, connection.id == excludeId {
                return false
            }
            return connection.sourceNodeId == outputAnchor.nodeId &&
                connection.sourcePortId == outputAnchor.portId &&
                connection.targetNodeId == inputAnchor.nodeId &&
                connection.targetPortId == inputAnchor.portId
        }

        return !alreadyExists
    }

    public func updateValidDropPorts(for sourceAnchor: ConnectionAnchor) {
        validDropPortIds.removeAll()

        // When reconnecting, exclude the original connection from validation
        let excludeId = reconnectingConnection?.id

        for node in nodes {
            // Skip the source node (no self-connections)
            if node.id == sourceAnchor.nodeId {
                continue
            }

            // Check input ports if dragging from output
            if !sourceAnchor.isInput {
                for port in node.inputs {
                    let targetAnchor = ConnectionAnchor(
                        nodeId: node.id,
                        portId: port.id,
                        position: .zero,
                        isInput: true
                    )
                    if canConnect(from: sourceAnchor, to: targetAnchor, excluding: excludeId) {
                        validDropPortIds.insert(port.id)
                    }
                }
            } else {
                // Check output ports if dragging from input
                for port in node.outputs {
                    let targetAnchor = ConnectionAnchor(
                        nodeId: node.id,
                        portId: port.id,
                        position: .zero,
                        isInput: false
                    )
                    if canConnect(from: sourceAnchor, to: targetAnchor, excluding: excludeId) {
                        validDropPortIds.insert(port.id)
                    }
                }
            }
        }
    }

    // MARK: - Clipboard Operations

    public func copySelectedNodes() {
        guard !selectedNodeIds.isEmpty else { return }

        let selectedNodesData = nodes.filter { selectedNodeIds.contains($0.id) }

        // Also copy connections between selected nodes
        let selectedConnections = connections.filter { connection in
            selectedNodeIds.contains(connection.sourceNodeId) &&
            selectedNodeIds.contains(connection.targetNodeId)
        }

        let clipboardData = WorkflowData(nodes: selectedNodesData, connections: selectedConnections)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let jsonData = try? encoder.encode(clipboardData),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(jsonString, forType: .string)
    }

    public func pasteNodes() {
        let pasteboard = NSPasteboard.general
        guard let jsonString = pasteboard.string(forType: .string),
              let data = jsonString.data(using: .utf8),
              let clipboardData = try? JSONDecoder().decode(WorkflowData.self, from: data) else {
            return
        }

        saveSnapshot()

        // Create ID mapping for pasted nodes
        var idMapping: [UUID: UUID] = [:]

        // Calculate offset for pasted nodes (shift by 20,20 from original)
        let pasteOffset = CGPoint(x: 20, y: 20)

        // Add nodes with new IDs and offset positions
        var newNodeIds: Set<UUID> = []
        for oldNode in clipboardData.nodes {
            let newId = UUID()
            idMapping[oldNode.id] = newId
            newNodeIds.insert(newId)

            let newNode = WorkflowNode(
                id: newId,
                type: oldNode.type,
                title: oldNode.title,
                position: CGPoint(
                    x: oldNode.position.x + pasteOffset.x,
                    y: oldNode.position.y + pasteOffset.y
                ),
                size: oldNode.size,
                inputs: oldNode.inputs,
                outputs: oldNode.outputs,
                configuration: oldNode.configuration,
                isCollapsed: oldNode.isCollapsed
            )
            nodes.append(newNode)
        }

        // Add connections with remapped node IDs
        for oldConnection in clipboardData.connections {
            if let newSourceId = idMapping[oldConnection.sourceNodeId],
               let newTargetId = idMapping[oldConnection.targetNodeId] {
                let newConnection = WorkflowConnection(
                    sourceNodeId: newSourceId,
                    sourcePortId: oldConnection.sourcePortId,
                    targetNodeId: newTargetId,
                    targetPortId: oldConnection.targetPortId
                )
                connections.append(newConnection)
            }
        }

        // Select the newly pasted nodes
        selectedNodeIds = newNodeIds
    }

    public func duplicateSelectedNodes() {
        guard !selectedNodeIds.isEmpty else { return }

        // Copy to clipboard and paste (reuses the logic)
        copySelectedNodes()
        pasteNodes()
    }

    // MARK: - Node Ordering Operations

    public func bringSelectedToFront() {
        guard !selectedNodeIds.isEmpty else { return }
        saveSnapshot()

        // Separate selected and unselected nodes
        let selected = nodes.filter { selectedNodeIds.contains($0.id) }
        let unselected = nodes.filter { !selectedNodeIds.contains($0.id) }

        // Place selected nodes at the end (on top)
        nodes = unselected + selected
    }

    public func sendSelectedToBack() {
        guard !selectedNodeIds.isEmpty else { return }
        saveSnapshot()

        // Separate selected and unselected nodes
        let selected = nodes.filter { selectedNodeIds.contains($0.id) }
        let unselected = nodes.filter { !selectedNodeIds.contains($0.id) }

        // Place selected nodes at the beginning (on bottom)
        nodes = selected + unselected
    }

    // MARK: - Serialization

    public func exportJSON() -> String? {
        let data = WorkflowData(nodes: nodes, connections: connections)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let jsonData = try? encoder.encode(data) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }

    public func importJSON(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let workflowData = try? JSONDecoder().decode(WorkflowData.self, from: data) else {
            return false
        }
        nodes = workflowData.nodes
        connections = workflowData.connections
        return true
    }
}

// MARK: - Sample Data

public extension CanvasState {
    static func sampleState() -> CanvasState {
        let state = CanvasState()

        // Create sample nodes using convenience API (positions will be auto-laid out)
        let trigger = state.addNode(
            type: .trigger,
            title: "Voice Input"
        )

        let llm = state.addNode(
            type: .llm,
            title: "Summarize",
            configuration: NodeConfiguration(
                prompt: "Summarize the following transcript:\n{{input}}",
                model: "gemini-2.0-flash",
                temperature: 0.7
            )
        )

        let condition = state.addNode(
            type: .condition,
            title: "Has Tasks?",
            configuration: NodeConfiguration(
                condition: "output contains 'task'"
            )
        )

        let action = state.addNode(
            type: .action,
            title: "Create Reminder",
            configuration: NodeConfiguration(
                actionType: "reminder"
            )
        )

        let output = state.addNode(
            type: .output,
            title: "Save Result"
        )

        // Create connections
        state.connect(trigger, to: llm)
        state.connect(llm, to: condition)
        state.connect(condition, port: "True", to: action)
        state.connect(condition, port: "False", to: output)

        // Apply auto-layout for a nice flow
        state.autoLayout(
            spacing: CGSize(width: 300, height: 140),
            origin: CGPoint(x: 100, y: 100)
        )

        return state
    }
}
