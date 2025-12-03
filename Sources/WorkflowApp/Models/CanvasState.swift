import Foundation
import SwiftUI
import AppKit

// MARK: - Canvas Snapshot (for Undo/Redo)

struct CanvasSnapshot: Equatable {
    let nodes: [WorkflowNode]
    let connections: [WorkflowConnection]
    let selectedNodeIds: Set<UUID>

    static func == (lhs: CanvasSnapshot, rhs: CanvasSnapshot) -> Bool {
        lhs.nodes == rhs.nodes &&
        lhs.connections == rhs.connections &&
        lhs.selectedNodeIds == rhs.selectedNodeIds
    }
}

// MARK: - Canvas State (Observable)

@Observable
final class CanvasState {
    // MARK: - Workflow Data
    var nodes: [WorkflowNode] = []
    var connections: [WorkflowConnection] = []

    // MARK: - Canvas Transform
    var offset: CGSize = .zero
    var scale: CGFloat = 1.0
    var minScale: CGFloat = 0.25
    var maxScale: CGFloat = 3.0
    var targetScale: CGFloat = 1.0 // For smooth zoom animations

    // MARK: - Selection State
    var selectedNodeIds: Set<UUID> = []
    var hoveredNodeId: UUID? = nil
    var selectedConnectionId: UUID? = nil
    var hoveredConnectionId: UUID? = nil

    // MARK: - Connection State
    var pendingConnection: PendingConnection? = nil
    var hoveredPortId: UUID? = nil
    var validDropPortIds: Set<UUID> = []

    // MARK: - Interaction State
    var isDragging: Bool = false
    var isPanning: Bool = false

    // MARK: - Drag Snapshot (for smooth dragging from initial position)
    private var dragSnapshot: [UUID: CGPoint] = [:]

    // MARK: - Undo/Redo State
    private var undoStack: [CanvasSnapshot] = []
    private var redoStack: [CanvasSnapshot] = []
    private let maxUndoStackSize = 50
    private var isPerformingUndoRedo = false

    // MARK: - Computed Properties

    var selectedNodes: [WorkflowNode] {
        nodes.filter { selectedNodeIds.contains($0.id) }
    }

    var hasSelection: Bool {
        !selectedNodeIds.isEmpty
    }

    var singleSelectedNode: WorkflowNode? {
        guard selectedNodeIds.count == 1,
              let id = selectedNodeIds.first else { return nil }
        return nodes.first { $0.id == id }
    }

    var canUndo: Bool {
        !undoStack.isEmpty
    }

    var canRedo: Bool {
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

    func undo() {
        guard !undoStack.isEmpty else { return }

        // Save current state to redo stack
        redoStack.append(createSnapshot())

        // Restore previous state
        let snapshot = undoStack.removeLast()
        restoreSnapshot(snapshot)
    }

    func redo() {
        guard !redoStack.isEmpty else { return }

        // Save current state to undo stack
        undoStack.append(createSnapshot())

        // Restore next state
        let snapshot = redoStack.removeLast()
        restoreSnapshot(snapshot)
    }

    // MARK: - Node Operations

    func addNode(_ node: WorkflowNode) {
        saveSnapshot()
        nodes.append(node)
    }

    func addNode(type: NodeType, at position: CGPoint) {
        saveSnapshot()
        let node = WorkflowNode(type: type, position: position)
        nodes.append(node)
        selectNode(node.id, exclusive: true)
    }

    func removeNode(_ id: UUID) {
        saveSnapshot()
        nodes.removeAll { $0.id == id }
        // Remove connections involving this node
        connections.removeAll { $0.sourceNodeId == id || $0.targetNodeId == id }
        selectedNodeIds.remove(id)
    }

    func removeSelectedNodes() {
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

    func updateNode(_ node: WorkflowNode) {
        saveSnapshot()
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes[index] = node
        }
    }

    func moveNode(_ id: UUID, to position: CGPoint) {
        if let index = nodes.firstIndex(where: { $0.id == id }) {
            nodes[index].position = position
        }
    }

    func moveSelectedNodes(by delta: CGSize) {
        for id in selectedNodeIds {
            if let index = nodes.firstIndex(where: { $0.id == id }) {
                nodes[index].position.x += delta.width
                nodes[index].position.y += delta.height
            }
        }
    }

    func beginNodeMove() {
        saveSnapshot()
        // Capture initial positions of selected nodes
        dragSnapshot.removeAll()
        for id in selectedNodeIds {
            if let node = nodes.first(where: { $0.id == id }) {
                dragSnapshot[id] = node.position
            }
        }
    }

    func moveSelectedNodesFromSnapshot(by delta: CGSize) {
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

    func endNodeMove() {
        dragSnapshot.removeAll()
    }

    // MARK: - Selection Operations

    func selectNode(_ id: UUID, exclusive: Bool = false) {
        if exclusive {
            selectedNodeIds = [id]
        } else {
            selectedNodeIds.insert(id)
        }
    }

    func deselectNode(_ id: UUID) {
        selectedNodeIds.remove(id)
    }

    func toggleNodeSelection(_ id: UUID) {
        if selectedNodeIds.contains(id) {
            selectedNodeIds.remove(id)
        } else {
            selectedNodeIds.insert(id)
        }
    }

    func clearSelection() {
        selectedNodeIds.removeAll()
        selectedConnectionId = nil
    }

    func selectAll() {
        selectedNodeIds = Set(nodes.map { $0.id })
    }

    func selectConnection(_ id: UUID) {
        selectedConnectionId = id
        selectedNodeIds.removeAll() // Deselect nodes when selecting a connection
    }

    func deselectConnection() {
        selectedConnectionId = nil
    }

    // MARK: - Connection Operations

    func addConnection(_ connection: WorkflowConnection) {
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
        connections.append(connection)
    }

    func removeConnection(_ id: UUID) {
        saveSnapshot()
        connections.removeAll { $0.id == id }
    }

    func removeConnectionsForPort(nodeId: UUID, portId: UUID) {
        saveSnapshot()
        connections.removeAll {
            ($0.sourceNodeId == nodeId && $0.sourcePortId == portId) ||
            ($0.targetNodeId == nodeId && $0.targetPortId == portId)
        }
    }

    // MARK: - Canvas Operations

    func resetView() {
        offset = .zero
        scale = 1.0
    }

    func zoomIn(animated: Bool = true) {
        let newScale = min(scale * 1.25, maxScale)
        if animated {
            targetScale = newScale
        } else {
            scale = newScale
            targetScale = newScale
        }
    }

    func zoomOut(animated: Bool = true) {
        let newScale = max(scale / 1.25, minScale)
        if animated {
            targetScale = newScale
        } else {
            scale = newScale
            targetScale = newScale
        }
    }

    func setZoom(to newScale: CGFloat, animated: Bool = true) {
        let clampedScale = max(minScale, min(newScale, maxScale))
        if animated {
            targetScale = clampedScale
        } else {
            scale = clampedScale
            targetScale = clampedScale
        }
    }

    func zoomToFit(in size: CGSize, padding: CGFloat = 50) {
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

        // Center the content
        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2
        offset = CGSize(
            width: size.width / 2 - centerX * scale,
            height: size.height / 2 - centerY * scale
        )
    }

    func zoomToward(point: CGPoint, scaleFactor: CGFloat, canvasSize: CGSize) {
        let newScale = max(minScale, min(scale * scaleFactor, maxScale))

        // Calculate the canvas point under the cursor
        let canvasPoint = canvasPoint(from: point)

        // Apply the new scale
        scale = newScale

        // Adjust offset to keep the canvas point under the cursor
        let newScreenPoint = screenPoint(from: canvasPoint)
        offset.width += point.x - newScreenPoint.x
        offset.height += point.y - newScreenPoint.y
    }

    // MARK: - Grid Snapping

    private let gridSize: CGFloat = 20

    func snapToGrid(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: round(point.x / gridSize) * gridSize,
            y: round(point.y / gridSize) * gridSize
        )
    }

    func snapSelectedNodesToGrid() {
        for id in selectedNodeIds {
            if let index = nodes.firstIndex(where: { $0.id == id }) {
                // Snap to grid (already returns rounded values from snapToGrid)
                nodes[index].position = snapToGrid(nodes[index].position)
            }
        }
    }

    // MARK: - Keyboard Navigation

    func nudgeSelectedNodes(by delta: CGSize) {
        guard !selectedNodeIds.isEmpty else { return }
        saveSnapshot()
        moveSelectedNodes(by: delta)
    }

    func selectNextNode() {
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

    func selectPreviousNode() {
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

    func canvasPoint(from screenPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: (screenPoint.x - offset.width) / scale,
            y: (screenPoint.y - offset.height) / scale
        )
    }

    func screenPoint(from canvasPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: canvasPoint.x * scale + offset.width,
            y: canvasPoint.y * scale + offset.height
        )
    }

    // MARK: - Hit Testing

    func nodeAt(point: CGPoint) -> WorkflowNode? {
        // Return topmost node (last in array) at point
        nodes.last { node in
            let rect = CGRect(origin: node.position, size: node.size)
            return rect.contains(point)
        }
    }

    func connectionAt(point: CGPoint, tolerance: CGFloat = 10) -> UUID? {
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

    func portPosition(nodeId: UUID, portId: UUID) -> CGPoint? {
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

    func portAt(canvasPoint: CGPoint, tolerance: CGFloat = 15) -> (nodeId: UUID, portId: UUID, isInput: Bool)? {
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

    func canConnect(from sourceAnchor: ConnectionAnchor, to targetAnchor: ConnectionAnchor) -> Bool {
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

        // Check if connection already exists
        let (outputAnchor, inputAnchor) = sourceAnchor.isInput ? (targetAnchor, sourceAnchor) : (sourceAnchor, targetAnchor)

        let alreadyExists = connections.contains { connection in
            connection.sourceNodeId == outputAnchor.nodeId &&
            connection.sourcePortId == outputAnchor.portId &&
            connection.targetNodeId == inputAnchor.nodeId &&
            connection.targetPortId == inputAnchor.portId
        }

        return !alreadyExists
    }

    func updateValidDropPorts(for sourceAnchor: ConnectionAnchor) {
        validDropPortIds.removeAll()

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
                    if canConnect(from: sourceAnchor, to: targetAnchor) {
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
                    if canConnect(from: sourceAnchor, to: targetAnchor) {
                        validDropPortIds.insert(port.id)
                    }
                }
            }
        }
    }

    // MARK: - Clipboard Operations

    func copySelectedNodes() {
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

    func pasteNodes() {
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

            var newNode = oldNode
            newNode = WorkflowNode(
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

    func duplicateSelectedNodes() {
        guard !selectedNodeIds.isEmpty else { return }

        // Copy to clipboard and paste (reuses the logic)
        copySelectedNodes()
        pasteNodes()
    }

    // MARK: - Node Ordering Operations

    func bringSelectedToFront() {
        guard !selectedNodeIds.isEmpty else { return }
        saveSnapshot()

        // Separate selected and unselected nodes
        let selected = nodes.filter { selectedNodeIds.contains($0.id) }
        let unselected = nodes.filter { !selectedNodeIds.contains($0.id) }

        // Place selected nodes at the end (on top)
        nodes = unselected + selected
    }

    func sendSelectedToBack() {
        guard !selectedNodeIds.isEmpty else { return }
        saveSnapshot()

        // Separate selected and unselected nodes
        let selected = nodes.filter { selectedNodeIds.contains($0.id) }
        let unselected = nodes.filter { !selectedNodeIds.contains($0.id) }

        // Place selected nodes at the beginning (on bottom)
        nodes = selected + unselected
    }

    // MARK: - Node Color Operations

    func changeNodeColor(_ nodeId: UUID, to color: Color) {
        guard let index = nodes.firstIndex(where: { $0.id == nodeId }) else { return }
        saveSnapshot()

        // Update node type based on color (approximate matching)
        // This is a simplified approach - in a real app you might store custom colors
        let nodeTypes: [NodeType] = [.trigger, .llm, .transform, .condition, .action, .output]
        if let matchingType = nodeTypes.first(where: { $0.color == color }) {
            nodes[index].type = matchingType
        }
    }

    // MARK: - Serialization

    func exportJSON() -> String? {
        let data = WorkflowData(nodes: nodes, connections: connections)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let jsonData = try? encoder.encode(data) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }

    func importJSON(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let workflowData = try? JSONDecoder().decode(WorkflowData.self, from: data) else {
            return false
        }
        nodes = workflowData.nodes
        connections = workflowData.connections
        return true
    }
}

// MARK: - Serializable Data

struct WorkflowData: Codable {
    var nodes: [WorkflowNode]
    var connections: [WorkflowConnection]
}

// MARK: - Sample Data

extension CanvasState {
    static func sampleState() -> CanvasState {
        let state = CanvasState()

        // Create sample nodes
        let triggerNode = WorkflowNode(
            type: .trigger,
            title: "Voice Input",
            position: CGPoint(x: 100, y: 200)
        )

        let llmNode = WorkflowNode(
            type: .llm,
            title: "Summarize",
            position: CGPoint(x: 400, y: 150),
            configuration: NodeConfiguration(
                prompt: "Summarize the following transcript:\n{{input}}",
                model: "gemini-2.0-flash",
                temperature: 0.7
            )
        )

        let conditionNode = WorkflowNode(
            type: .condition,
            title: "Has Tasks?",
            position: CGPoint(x: 400, y: 350),
            configuration: NodeConfiguration(
                condition: "output contains 'task'"
            )
        )

        let actionNode = WorkflowNode(
            type: .action,
            title: "Create Reminder",
            position: CGPoint(x: 700, y: 200),
            configuration: NodeConfiguration(
                actionType: "reminder"
            )
        )

        let outputNode = WorkflowNode(
            type: .output,
            title: "Save Result",
            position: CGPoint(x: 700, y: 400)
        )

        state.nodes = [triggerNode, llmNode, conditionNode, actionNode, outputNode]

        // Create connections
        if let triggerOut = triggerNode.outputs.first,
           let llmIn = llmNode.inputs.first {
            state.connections.append(WorkflowConnection(
                sourceNodeId: triggerNode.id,
                sourcePortId: triggerOut.id,
                targetNodeId: llmNode.id,
                targetPortId: llmIn.id
            ))
        }

        if let llmOut = llmNode.outputs.first,
           let condIn = conditionNode.inputs.first {
            state.connections.append(WorkflowConnection(
                sourceNodeId: llmNode.id,
                sourcePortId: llmOut.id,
                targetNodeId: conditionNode.id,
                targetPortId: condIn.id
            ))
        }

        // True branch to action
        if let condTrue = conditionNode.outputs.first,
           let actionIn = actionNode.inputs.first {
            state.connections.append(WorkflowConnection(
                sourceNodeId: conditionNode.id,
                sourcePortId: condTrue.id,
                targetNodeId: actionNode.id,
                targetPortId: actionIn.id
            ))
        }

        // False branch to output
        if conditionNode.outputs.count > 1,
           let condFalse = conditionNode.outputs.last,
           let outputIn = outputNode.inputs.first {
            state.connections.append(WorkflowConnection(
                sourceNodeId: conditionNode.id,
                sourcePortId: condFalse.id,
                targetNodeId: outputNode.id,
                targetPortId: outputIn.id
            ))
        }

        return state
    }
}
