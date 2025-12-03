import SwiftUI

// MARK: - Minimap View

struct MinimapView: View {
    @Bindable var state: CanvasState
    let canvasSize: CGSize
    let minimapSize: CGSize = CGSize(width: 200, height: 150)

    @State private var isDraggingViewport = false
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        Canvas { context, size in
            // Theme-adaptive background matching canvas
            let backgroundRect = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8)
            context.fill(
                backgroundRect,
                with: .color(DesignSystem.Colors.canvasBackground(isDark: themeManager.isDarkMode).opacity(0.9))
            )

            // Clean border
            context.stroke(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8),
                with: .color(DesignSystem.Colors.borderDefault(isDark: themeManager.isDarkMode)),
                lineWidth: 1
            )

            // Calculate scale and bounds
            guard let bounds = calculateContentBounds() else { return }

            let scaleX = (size.width - 20) / bounds.width
            let scaleY = (size.height - 20) / bounds.height
            let minimapScale = min(scaleX, scaleY)

            let offsetX = (size.width - bounds.width * minimapScale) / 2 - bounds.minX * minimapScale
            let offsetY = (size.height - bounds.height * minimapScale) / 2 - bounds.minY * minimapScale

            // Draw connections first (behind nodes)
            for connection in state.connections {
                if let startPos = state.portPosition(nodeId: connection.sourceNodeId, portId: connection.sourcePortId),
                   let endPos = state.portPosition(nodeId: connection.targetNodeId, portId: connection.targetPortId) {
                    var path = Path()
                    path.move(to: CGPoint(
                        x: startPos.x * minimapScale + offsetX,
                        y: startPos.y * minimapScale + offsetY
                    ))
                    path.addLine(to: CGPoint(
                        x: endPos.x * minimapScale + offsetX,
                        y: endPos.y * minimapScale + offsetY
                    ))
                    context.stroke(
                        path,
                        with: .color(Color.gray.opacity(0.25)),
                        lineWidth: 1
                    )
                }
            }

            // Draw nodes
            for node in state.nodes {
                let rect = CGRect(
                    x: node.position.x * minimapScale + offsetX,
                    y: node.position.y * minimapScale + offsetY,
                    width: node.size.width * minimapScale,
                    height: node.size.height * minimapScale
                )

                let path = Path(roundedRect: rect, cornerRadius: 2)

                // Fill with node type color
                context.fill(path, with: .color(node.type.color.opacity(0.85)))

                // Highlight selected nodes
                if state.selectedNodeIds.contains(node.id) {
                    context.stroke(
                        path,
                        with: .color(.white),
                        lineWidth: 1.5
                    )
                }
            }

            // Draw viewport rectangle with smooth animation
            let viewportRect = calculateViewportRect(
                canvasSize: canvasSize,
                minimapSize: size,
                contentBounds: bounds,
                minimapScale: minimapScale,
                offsetX: offsetX,
                offsetY: offsetY
            )

            let viewportPath = Path(roundedRect: viewportRect, cornerRadius: 2)

            // Extremely subtle viewport border (no fill)
            context.stroke(
                viewportPath,
                with: .color(Color(red: 0x00/255.0, green: 0x70/255.0, blue: 0xF3/255.0).opacity(0.3)),
                lineWidth: 1
            )
        }
        .frame(width: minimapSize.width, height: minimapSize.height)
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
        .gesture(minimapDragGesture)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: state.offset)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: state.scale)
    }

    // MARK: - Calculations

    private func calculateContentBounds() -> CGRect? {
        guard !state.nodes.isEmpty else { return nil }

        let padding: CGFloat = 50

        let minX = state.nodes.map { $0.position.x }.min() ?? 0
        let maxX = state.nodes.map { $0.position.x + $0.size.width }.max() ?? 0
        let minY = state.nodes.map { $0.position.y }.min() ?? 0
        let maxY = state.nodes.map { $0.position.y + $0.size.height }.max() ?? 0

        return CGRect(
            x: minX - padding,
            y: minY - padding,
            width: (maxX - minX) + padding * 2,
            height: (maxY - minY) + padding * 2
        )
    }

    private func calculateViewportRect(
        canvasSize: CGSize,
        minimapSize: CGSize,
        contentBounds: CGRect,
        minimapScale: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat
    ) -> CGRect {
        // Calculate the visible area in canvas coordinates
        let visibleMinX = -state.offset.width / state.scale
        let visibleMinY = -state.offset.height / state.scale
        let visibleMaxX = visibleMinX + canvasSize.width / state.scale
        let visibleMaxY = visibleMinY + canvasSize.height / state.scale

        // Convert to minimap coordinates
        let x = visibleMinX * minimapScale + offsetX
        let y = visibleMinY * minimapScale + offsetY
        let width = (visibleMaxX - visibleMinX) * minimapScale
        let height = (visibleMaxY - visibleMinY) * minimapScale

        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func minimapPointToCanvasPoint(_ point: CGPoint) -> CGPoint {
        guard let bounds = calculateContentBounds() else { return .zero }

        let scaleX = (minimapSize.width - 20) / bounds.width
        let scaleY = (minimapSize.height - 20) / bounds.height
        let minimapScale = min(scaleX, scaleY)

        let offsetX = (minimapSize.width - bounds.width * minimapScale) / 2 - bounds.minX * minimapScale
        let offsetY = (minimapSize.height - bounds.height * minimapScale) / 2 - bounds.minY * minimapScale

        let canvasX = (point.x - offsetX) / minimapScale
        let canvasY = (point.y - offsetY) / minimapScale

        return CGPoint(x: canvasX, y: canvasY)
    }

    // MARK: - Gestures

    private var minimapDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDraggingViewport = true

                // Convert minimap point to canvas coordinates
                let canvasPoint = minimapPointToCanvasPoint(value.location)

                // Center the viewport on this point with smooth animation
                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                    state.offset = CGSize(
                        width: canvasSize.width / 2 - canvasPoint.x * state.scale,
                        height: canvasSize.height / 2 - canvasPoint.y * state.scale
                    )
                }
            }
            .onEnded { _ in
                isDraggingViewport = false
            }
    }
}

// MARK: - Preview

#Preview("Minimap") {
    MinimapView(
        state: CanvasState.sampleState(),
        canvasSize: CGSize(width: 800, height: 600)
    )
    .padding()
    .frame(width: 300, height: 250)
    .background(Color(nsColor: .windowBackgroundColor))
}
