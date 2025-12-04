import SwiftUI
import AppKit

// MARK: - Connection View (Bezier Curve)

public struct ConnectionView: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color
    var sourceColor: Color? = nil
    var targetColor: Color? = nil
    var lineWidth: CGFloat = 2.0
    var animated: Bool = false
    var showFlowAnimation: Bool = true
    var isSelected: Bool = false
    var isHovered: Bool = false
    var curveStyle: WFConnectionStyle = .bezier

    @State private var animationPhase: CGFloat = 0
    @State private var flowPhase: CGFloat = 0
    @Environment(\.wfTheme) private var theme
    @Environment(\.wfLayoutMode) private var layoutMode

    public init(
        from: CGPoint,
        to: CGPoint,
        color: Color,
        sourceColor: Color? = nil,
        targetColor: Color? = nil,
        lineWidth: CGFloat = 2.0,
        animated: Bool = false,
        showFlowAnimation: Bool = true,
        isSelected: Bool = false,
        isHovered: Bool = false,
        curveStyle: WFConnectionStyle = .bezier
    ) {
        self.from = from
        self.to = to
        self.color = color
        self.sourceColor = sourceColor
        self.targetColor = targetColor
        self.lineWidth = lineWidth
        self.animated = animated
        self.showFlowAnimation = showFlowAnimation
        self.isSelected = isSelected
        self.isHovered = isHovered
        self.curveStyle = curveStyle
    }

    /// The effective curve style (uses theme default if not explicitly set)
    private var effectiveStyle: WFConnectionStyle {
        curveStyle
    }

    /// Calculate the bounding rect for the bezier curve including control points
    private var bezierBounds: CGRect {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let distance = sqrt(dx * dx + dy * dy)

        // Calculate control offset based on layout mode
        var controlOffset: CGFloat
        if layoutMode == .vertical {
            if abs(dy) < 50 {
                controlOffset = max(abs(dx) * 0.3, 80)
            } else if abs(dx) < 50 {
                controlOffset = min(abs(dy) * 0.5, distance * 0.4)
            } else {
                controlOffset = min(max(abs(dy) * 0.4, 100), distance * 0.45)
            }
        } else {
            if abs(dx) < 50 {
                controlOffset = max(abs(dy) * 0.3, 80)
            } else if abs(dy) < 50 {
                controlOffset = min(abs(dx) * 0.5, distance * 0.4)
            } else {
                controlOffset = min(max(abs(dx) * 0.4, 100), distance * 0.45)
            }
        }

        // Calculate all control points
        let control1: CGPoint
        let control2: CGPoint

        if layoutMode == .vertical {
            if dy >= 0 {
                control1 = CGPoint(x: from.x, y: from.y + controlOffset)
                control2 = CGPoint(x: to.x, y: to.y - controlOffset)
            } else {
                control1 = CGPoint(x: from.x, y: from.y - controlOffset)
                control2 = CGPoint(x: to.x, y: to.y + controlOffset)
            }
        } else {
            control1 = CGPoint(x: from.x + controlOffset, y: from.y)
            control2 = CGPoint(x: to.x - controlOffset, y: to.y)
        }

        // Find bounding box of all points
        let allX = [from.x, to.x, control1.x, control2.x]
        let allY = [from.y, to.y, control1.y, control2.y]

        let minX = allX.min()! - 50  // Extra padding for stroke width and arrows
        let maxX = allX.max()! + 50
        let minY = allY.min()! - 50
        let maxY = allY.max()! + 50

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    public var body: some View {
        let bounds = bezierBounds

        Canvas { context, size in
            // Translate context to account for bounds offset
            var context = context
            context.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)

            let path = connectionPath(from: from, to: to, style: effectiveStyle)

            // Use theme line width as base, with vertical mode multiplier
            let themeLineWidth = theme.connectionLineWidth
            let baseLineWidth = layoutMode == .vertical ? (themeLineWidth * 1.5) : themeLineWidth
            let effectiveLineWidth = isSelected ? baseLineWidth + 1.5 : (isHovered ? baseLineWidth + 1.0 : baseLineWidth)
            let effectiveColor = isSelected ? Color.blue : (isHovered ? color.opacity(0.9) : color)

            if isSelected {
                context.stroke(
                    path,
                    with: .color(Color.blue.opacity(0.3)),
                    style: StrokeStyle(lineWidth: effectiveLineWidth + 4, lineCap: .round)
                )
            } else if isHovered {
                context.stroke(
                    path,
                    with: .color(color.opacity(0.25)),
                    style: StrokeStyle(lineWidth: effectiveLineWidth + 2, lineCap: .round)
                )
            }

            context.stroke(
                path,
                with: .color(effectiveColor.opacity(0.15)),
                style: StrokeStyle(lineWidth: effectiveLineWidth + 1, lineCap: .round)
            )

            if animated {
                context.stroke(
                    path,
                    with: .color(effectiveColor),
                    style: StrokeStyle(
                        lineWidth: effectiveLineWidth,
                        lineCap: .round,
                        dash: [8, 4],
                        dashPhase: animationPhase
                    )
                )
            } else {
                if let srcColor = sourceColor, let tgtColor = targetColor {
                    let gradient = Gradient(colors: [
                        isSelected ? Color.blue : srcColor,
                        isSelected ? Color.blue.opacity(0.8) : tgtColor
                    ])
                    context.stroke(
                        path,
                        with: .linearGradient(
                            gradient,
                            startPoint: from,
                            endPoint: to
                        ),
                        style: StrokeStyle(lineWidth: effectiveLineWidth, lineCap: .round)
                    )
                } else {
                    context.stroke(
                        path,
                        with: .color(effectiveColor),
                        style: StrokeStyle(lineWidth: effectiveLineWidth, lineCap: .round)
                    )
                }

                if showFlowAnimation {
                    drawFlowAnimation(context: context, path: path)
                }
            }

            drawArrowHead(context: context, path: path, color: isSelected ? Color.blue : (targetColor ?? effectiveColor))

            if isHovered {
                drawDeleteButton(context: context, path: path)
            }
        }
        .frame(width: bounds.width, height: bounds.height)
        .position(x: bounds.midX, y: bounds.midY)
        .allowsHitTesting(false)
        .onAppear {
            if animated {
                withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                    animationPhase = 12
                }
            }
            if showFlowAnimation && !animated {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    flowPhase = 1.0
                }
            }
        }
    }

    // MARK: - Path Generation

    /// Dispatcher for different connection styles
    private func connectionPath(from start: CGPoint, to end: CGPoint, style: WFConnectionStyle) -> Path {
        switch style {
        case .bezier:
            // Use vertical bezier in vertical layout mode
            return layoutMode == .vertical ? verticalBezierPath(from: start, to: end) : bezierPath(from: start, to: end)
        case .straight:
            return straightPath(from: start, to: end)
        case .step:
            return stepPath(from: start, to: end)
        case .smoothStep:
            return smoothStepPath(from: start, to: end)
        }
    }

    // MARK: - Bezier Path

    private func bezierPath(from start: CGPoint, to end: CGPoint) -> Path {
        var path = Path()
        path.move(to: start)

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

        path.addCurve(to: end, control1: control1, control2: control2)

        return path
    }

    // MARK: - Vertical Bezier Path (for vertical layout mode)

    private func verticalBezierPath(from start: CGPoint, to end: CGPoint) -> Path {
        var path = Path()
        path.move(to: start)

        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = sqrt(dx * dx + dy * dy)

        var controlOffset: CGFloat

        // Vertical-first routing: control points extend up/down
        if abs(dy) < 50 {
            controlOffset = max(abs(dx) * 0.3, 80)
        } else if abs(dx) < 50 {
            controlOffset = min(abs(dy) * 0.5, distance * 0.4)
        } else {
            controlOffset = min(max(abs(dy) * 0.4, 100), distance * 0.45)
        }

        // Control points extend in the direction of flow
        // Normal flow (top to bottom): dy > 0, control1 goes down, control2 comes from up
        // Reverse flow (bottom to top): dy < 0, control1 goes up, control2 comes from down
        let control1: CGPoint
        let control2: CGPoint

        if dy >= 0 {
            // Normal: start is above end (top to bottom)
            control1 = CGPoint(x: start.x, y: start.y + controlOffset)
            control2 = CGPoint(x: end.x, y: end.y - controlOffset)
        } else {
            // Reverse: start is below end (bottom to top)
            control1 = CGPoint(x: start.x, y: start.y - controlOffset)
            control2 = CGPoint(x: end.x, y: end.y + controlOffset)
        }

        path.addCurve(to: end, control1: control1, control2: control2)

        return path
    }

    // MARK: - Straight Path

    private func straightPath(from start: CGPoint, to end: CGPoint) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }

    // MARK: - Step Path (90-degree orthogonal)

    private func stepPath(from start: CGPoint, to end: CGPoint) -> Path {
        var path = Path()
        path.move(to: start)

        let dx = end.x - start.x
        let dy = end.y - start.y

        // Horizontal-first routing (for left-to-right flow)
        if dx >= 0 {
            // Normal case: target is to the right
            let midX = start.x + dx / 2
            path.addLine(to: CGPoint(x: midX, y: start.y))
            path.addLine(to: CGPoint(x: midX, y: end.y))
            path.addLine(to: end)
        } else {
            // Backwards case: target is to the left, route around
            let offsetY = abs(dy) < 50 ? 50 : abs(dy) * 0.3
            let routeY = dy >= 0 ? start.y + offsetY : start.y - offsetY

            path.addLine(to: CGPoint(x: start.x + 30, y: start.y))
            path.addLine(to: CGPoint(x: start.x + 30, y: routeY))
            path.addLine(to: CGPoint(x: end.x - 30, y: routeY))
            path.addLine(to: CGPoint(x: end.x - 30, y: end.y))
            path.addLine(to: end)
        }

        return path
    }

    // MARK: - Smooth Step Path (rounded orthogonal)

    private func smoothStepPath(from start: CGPoint, to end: CGPoint) -> Path {
        var path = Path()
        path.move(to: start)

        let dx = end.x - start.x
        let dy = end.y - start.y
        let cornerRadius: CGFloat = min(20, abs(dx) / 4, abs(dy) / 4)

        // Horizontal-first routing with rounded corners
        if dx >= 0 && abs(dx) > cornerRadius * 2 {
            let midX = start.x + dx / 2

            if abs(dy) < cornerRadius * 2 {
                // Nearly horizontal - just use bezier
                return bezierPath(from: start, to: end)
            }

            // First horizontal segment
            path.addLine(to: CGPoint(x: midX - cornerRadius, y: start.y))

            // First corner
            if dy > 0 {
                path.addQuadCurve(
                    to: CGPoint(x: midX, y: start.y + cornerRadius),
                    control: CGPoint(x: midX, y: start.y)
                )
            } else {
                path.addQuadCurve(
                    to: CGPoint(x: midX, y: start.y - cornerRadius),
                    control: CGPoint(x: midX, y: start.y)
                )
            }

            // Vertical segment
            if dy > 0 {
                path.addLine(to: CGPoint(x: midX, y: end.y - cornerRadius))
                // Second corner
                path.addQuadCurve(
                    to: CGPoint(x: midX + cornerRadius, y: end.y),
                    control: CGPoint(x: midX, y: end.y)
                )
            } else {
                path.addLine(to: CGPoint(x: midX, y: end.y + cornerRadius))
                // Second corner
                path.addQuadCurve(
                    to: CGPoint(x: midX + cornerRadius, y: end.y),
                    control: CGPoint(x: midX, y: end.y)
                )
            }

            // Final horizontal segment
            path.addLine(to: end)
        } else if dx < 0 {
            // Backwards routing with smooth corners
            let offsetY: CGFloat = abs(dy) < 50 ? 50 : abs(dy) * 0.3
            let routeY = dy >= 0 ? start.y + offsetY : start.y - offsetY
            let smallRadius = min(cornerRadius, 15)

            // First short horizontal
            path.addLine(to: CGPoint(x: start.x + 30 - smallRadius, y: start.y))

            // Corner down/up
            if dy >= 0 {
                path.addQuadCurve(
                    to: CGPoint(x: start.x + 30, y: start.y + smallRadius),
                    control: CGPoint(x: start.x + 30, y: start.y)
                )
                path.addLine(to: CGPoint(x: start.x + 30, y: routeY - smallRadius))
                path.addQuadCurve(
                    to: CGPoint(x: start.x + 30 - smallRadius, y: routeY),
                    control: CGPoint(x: start.x + 30, y: routeY)
                )
            } else {
                path.addQuadCurve(
                    to: CGPoint(x: start.x + 30, y: start.y - smallRadius),
                    control: CGPoint(x: start.x + 30, y: start.y)
                )
                path.addLine(to: CGPoint(x: start.x + 30, y: routeY + smallRadius))
                path.addQuadCurve(
                    to: CGPoint(x: start.x + 30 - smallRadius, y: routeY),
                    control: CGPoint(x: start.x + 30, y: routeY)
                )
            }

            // Long horizontal at routeY
            path.addLine(to: CGPoint(x: end.x - 30 + smallRadius, y: routeY))

            // Corner to vertical
            if dy >= 0 {
                path.addQuadCurve(
                    to: CGPoint(x: end.x - 30, y: routeY + smallRadius),
                    control: CGPoint(x: end.x - 30, y: routeY)
                )
                path.addLine(to: CGPoint(x: end.x - 30, y: end.y - smallRadius))
                path.addQuadCurve(
                    to: CGPoint(x: end.x - 30 + smallRadius, y: end.y),
                    control: CGPoint(x: end.x - 30, y: end.y)
                )
            } else {
                path.addQuadCurve(
                    to: CGPoint(x: end.x - 30, y: routeY - smallRadius),
                    control: CGPoint(x: end.x - 30, y: routeY)
                )
                path.addLine(to: CGPoint(x: end.x - 30, y: end.y + smallRadius))
                path.addQuadCurve(
                    to: CGPoint(x: end.x - 30 + smallRadius, y: end.y),
                    control: CGPoint(x: end.x - 30, y: end.y)
                )
            }

            path.addLine(to: end)
        } else {
            // Very short horizontal distance - use simple path
            path.addLine(to: end)
        }

        return path
    }

    // MARK: - Flow Animation

    private func drawFlowAnimation(context: GraphicsContext, path: Path) {
        let dotCount = 3
        let dotSize: CGFloat = 4
        let dotSpacing = 1.0 / CGFloat(dotCount + 1)

        for i in 0..<dotCount {
            let offset = CGFloat(i) * dotSpacing + dotSpacing
            let position = (offset + flowPhase).truncatingRemainder(dividingBy: 1.0)

            if let point = path.trimmedPath(from: position, to: position).currentPoint {
                var dotPath = Path()
                dotPath.addEllipse(in: CGRect(
                    x: point.x - dotSize / 2,
                    y: point.y - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                ))

                let opacity = sin(position * .pi) * 0.6 + 0.2
                context.fill(
                    dotPath,
                    with: .color((targetColor ?? color).opacity(opacity))
                )
            }
        }
    }

    // MARK: - Arrow Head

    private func drawArrowHead(context: GraphicsContext, path: Path, color: Color) {
        let endPoint = path.currentPoint ?? to
        let tangentLength: CGFloat = 0.02

        let trimmedPath = path.trimmedPath(from: max(0, 1 - tangentLength), to: 1)
        let pathPoints = extractPathPoints(trimmedPath)

        guard pathPoints.count >= 2 else {
            drawSimpleArrowHead(context: context, at: endPoint, color: color)
            return
        }

        let lastPoint = pathPoints[pathPoints.count - 1]
        let secondLastPoint = pathPoints[pathPoints.count - 2]

        let dx = lastPoint.x - secondLastPoint.x
        let dy = lastPoint.y - secondLastPoint.y
        let angle = atan2(dy, dx)

        let arrowLength: CGFloat = 12
        let arrowWidth: CGFloat = 8

        var arrowPath = Path()
        arrowPath.move(to: endPoint)
        arrowPath.addLine(to: CGPoint(
            x: endPoint.x - arrowLength * cos(angle) - arrowWidth * cos(angle + .pi / 2),
            y: endPoint.y - arrowLength * sin(angle) - arrowWidth * sin(angle + .pi / 2)
        ))
        arrowPath.addLine(to: CGPoint(
            x: endPoint.x - arrowLength * cos(angle) - arrowWidth * cos(angle - .pi / 2),
            y: endPoint.y - arrowLength * sin(angle) - arrowWidth * sin(angle - .pi / 2)
        ))
        arrowPath.closeSubpath()

        context.fill(arrowPath, with: .color(color))

        context.stroke(
            arrowPath,
            with: .color(color.opacity(0.5)),
            style: StrokeStyle(lineWidth: 0.5, lineJoin: .round)
        )
    }

    private func drawSimpleArrowHead(context: GraphicsContext, at point: CGPoint, color: Color) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let angle = atan2(dy, dx)

        let arrowLength: CGFloat = 12
        let arrowWidth: CGFloat = 8

        var arrowPath = Path()
        arrowPath.move(to: point)
        arrowPath.addLine(to: CGPoint(
            x: point.x - arrowLength * cos(angle) - arrowWidth * cos(angle + .pi / 2),
            y: point.y - arrowLength * sin(angle) - arrowWidth * sin(angle + .pi / 2)
        ))
        arrowPath.addLine(to: CGPoint(
            x: point.x - arrowLength * cos(angle) - arrowWidth * cos(angle - .pi / 2),
            y: point.y - arrowLength * sin(angle) - arrowWidth * sin(angle - .pi / 2)
        ))
        arrowPath.closeSubpath()

        context.fill(arrowPath, with: .color(color))
    }

    private func extractPathPoints(_ path: Path) -> [CGPoint] {
        var points: [CGPoint] = []
        path.forEach { element in
            switch element {
            case .move(to: let point), .line(to: let point):
                points.append(point)
            case .curve(to: let point, control1: _, control2: _):
                points.append(point)
            case .quadCurve(to: let point, control: _):
                points.append(point)
            case .closeSubpath:
                break
            }
        }
        return points
    }

    // MARK: - Delete Button

    private func drawDeleteButton(context: GraphicsContext, path: Path) {
        if let midPoint = path.trimmedPath(from: 0.5, to: 0.5).currentPoint {
            let buttonRadius: CGFloat = 8

            var circlePath = Path()
            circlePath.addEllipse(in: CGRect(
                x: midPoint.x - buttonRadius,
                y: midPoint.y - buttonRadius,
                width: buttonRadius * 2,
                height: buttonRadius * 2
            ))

            context.fill(circlePath, with: .color(Color.red.opacity(0.8)))
            context.stroke(circlePath, with: .color(Color.white.opacity(0.3)), style: StrokeStyle(lineWidth: 1))

            let xSize: CGFloat = 5
            var xPath = Path()
            xPath.move(to: CGPoint(x: midPoint.x - xSize / 2, y: midPoint.y - xSize / 2))
            xPath.addLine(to: CGPoint(x: midPoint.x + xSize / 2, y: midPoint.y + xSize / 2))
            xPath.move(to: CGPoint(x: midPoint.x + xSize / 2, y: midPoint.y - xSize / 2))
            xPath.addLine(to: CGPoint(x: midPoint.x - xSize / 2, y: midPoint.y + xSize / 2))

            context.stroke(xPath, with: .color(.white), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
    }
}

// MARK: - Pending Connection View

public struct PendingConnectionView: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color
    var isSnapped: Bool = false

    @State private var pulsePhase: CGFloat = 0

    public init(from: CGPoint, to: CGPoint, color: Color, isSnapped: Bool = false) {
        self.from = from
        self.to = to
        self.color = color
        self.isSnapped = isSnapped
    }

    public var body: some View {
        ZStack {
            // Glow effect when snapped
            if isSnapped {
                ConnectionView(
                    from: from,
                    to: to,
                    color: Color.green.opacity(0.3 + pulsePhase * 0.2),
                    lineWidth: 6,
                    animated: false,
                    showFlowAnimation: false
                )
                .blur(radius: 3)
            }

            // Main connection line
            ConnectionView(
                from: from,
                to: to,
                color: isSnapped ? Color.green : color.opacity(0.7),
                lineWidth: isSnapped ? 2.5 : 1.8,
                animated: !isSnapped,
                showFlowAnimation: false
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                pulsePhase = 1.0
            }
        }
    }
}

// MARK: - Connection Endpoint Handle (for drag-to-reconnect)

public struct ConnectionEndpointHandle: View {
    let position: CGPoint
    let color: Color
    let isSource: Bool
    let connection: WorkflowConnection
    let canvasState: CanvasState
    let onReconnectionUpdate: (CGPoint) -> Void
    let onReconnectionEnd: (ConnectionAnchor?) -> Void

    @State private var isDragging: Bool = false
    @State private var isHovered: Bool = false
    @Environment(\.wfTheme) private var theme

    private let handleSize: CGFloat = 14
    private let hitAreaSize: CGFloat = 24

    public init(
        position: CGPoint,
        color: Color,
        isSource: Bool,
        connection: WorkflowConnection,
        canvasState: CanvasState,
        onReconnectionUpdate: @escaping (CGPoint) -> Void,
        onReconnectionEnd: @escaping (ConnectionAnchor?) -> Void
    ) {
        self.position = position
        self.color = color
        self.isSource = isSource
        self.connection = connection
        self.canvasState = canvasState
        self.onReconnectionUpdate = onReconnectionUpdate
        self.onReconnectionEnd = onReconnectionEnd
    }

    public var body: some View {
        ZStack {
            // Outer glow when hovered/dragging
            if isHovered || isDragging {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: handleSize + 8, height: handleSize + 8)
            }

            // Main handle
            Circle()
                .fill(isDragging ? color : (isHovered ? color.opacity(0.9) : theme.nodeBackground))
                .overlay(
                    Circle()
                        .strokeBorder(color, lineWidth: 2)
                )
                .frame(width: handleSize, height: handleSize)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .frame(width: hitAreaSize, height: hitAreaSize)
        .contentShape(Circle().size(width: hitAreaSize, height: hitAreaSize))
        .position(position)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.openHand.push()
            } else if !isDragging {
                NSCursor.pop()
            }
        }
        .highPriorityGesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .named("canvas"))
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        WFLogger.gesture("Drag started", details: "isSource=\(isSource)")
                        NSCursor.pop()
                        NSCursor.closedHand.push()
                        // Start reconnection - fromSource means we're dragging from source end
                        canvasState.startReconnection(connection, fromSource: isSource)
                    }
                    let canvasPoint = canvasState.canvasPoint(from: value.location)
                    onReconnectionUpdate(canvasPoint)
                }
                .onEnded { value in
                    WFLogger.gesture("Drag ended")
                    isDragging = false
                    NSCursor.pop()
                    let canvasPoint = canvasState.canvasPoint(from: value.location)
                    WFLogger.debug("Canvas point: \(canvasPoint)", category: .gesture)
                    if let portHit = canvasState.portAt(canvasPoint: canvasPoint) {
                        WFLogger.debug("Port hit: nodeId=\(portHit.nodeId.uuidString.prefix(8)), isInput=\(portHit.isInput)", category: .gesture)
                        let targetAnchor = ConnectionAnchor(
                            nodeId: portHit.nodeId,
                            portId: portHit.portId,
                            position: canvasState.portPosition(nodeId: portHit.nodeId, portId: portHit.portId) ?? canvasPoint,
                            isInput: portHit.isInput
                        )
                        onReconnectionEnd(targetAnchor)
                    } else {
                        WFLogger.debug("No port hit - cancelling", category: .gesture)
                        onReconnectionEnd(nil)
                    }
                }
        )
    }
}

// MARK: - Connection Preview View (for hover)

public struct ConnectionPreviewView: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color

    public init(from: CGPoint, to: CGPoint, color: Color) {
        self.from = from
        self.to = to
        self.color = color
    }

    public var body: some View {
        ConnectionView(
            from: from,
            to: to,
            color: color,
            lineWidth: 1.5,
            animated: false,
            showFlowAnimation: false
        )
    }
}
