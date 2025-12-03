import Foundation
import SwiftUI

// MARK: - Connection (Edge between nodes)

struct WorkflowConnection: Identifiable, Codable, Hashable {
    let id: UUID
    var sourceNodeId: UUID
    var sourcePortId: UUID
    var targetNodeId: UUID
    var targetPortId: UUID

    init(
        id: UUID = UUID(),
        sourceNodeId: UUID,
        sourcePortId: UUID,
        targetNodeId: UUID,
        targetPortId: UUID
    ) {
        self.id = id
        self.sourceNodeId = sourceNodeId
        self.sourcePortId = sourcePortId
        self.targetNodeId = targetNodeId
        self.targetPortId = targetPortId
    }
}

// MARK: - Connection Anchor Point

struct ConnectionAnchor {
    let nodeId: UUID
    let portId: UUID
    let position: CGPoint
    let isInput: Bool
}

// MARK: - Pending Connection (while dragging)

struct PendingConnection {
    var sourceAnchor: ConnectionAnchor
    var currentPoint: CGPoint

    init(from anchor: ConnectionAnchor) {
        self.sourceAnchor = anchor
        self.currentPoint = anchor.position
    }
}
