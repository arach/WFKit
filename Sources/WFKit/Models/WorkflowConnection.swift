import Foundation
import SwiftUI

// MARK: - Connection (Edge between nodes)

public struct WorkflowConnection: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var sourceNodeId: UUID
    public var sourcePortId: UUID
    public var targetNodeId: UUID
    public var targetPortId: UUID

    public init(
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

public struct ConnectionAnchor: Sendable {
    public let nodeId: UUID
    public let portId: UUID
    public let position: CGPoint
    public let isInput: Bool

    public init(nodeId: UUID, portId: UUID, position: CGPoint, isInput: Bool) {
        self.nodeId = nodeId
        self.portId = portId
        self.position = position
        self.isInput = isInput
    }
}

// MARK: - Pending Connection (while dragging)

public struct PendingConnection: Sendable {
    public var sourceAnchor: ConnectionAnchor
    public var currentPoint: CGPoint

    public init(from anchor: ConnectionAnchor) {
        self.sourceAnchor = anchor
        self.currentPoint = anchor.position
    }
}
