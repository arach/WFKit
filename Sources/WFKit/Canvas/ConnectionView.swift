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

    @State private var animationPhase: CGFloat = 0
    @State private var flowPhase: CGFloat = 0

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
        isHovered: Bool = false
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
    }

    public var body: some View {
        Canvas { context, size in
            let path = bezierPath(from: from, to: to)

            let effectiveLineWidth = isSelected ? lineWidth + 1.5 : (isHovered ? lineWidth + 1.0 : lineWidth)
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
