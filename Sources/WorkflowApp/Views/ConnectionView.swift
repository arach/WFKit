import SwiftUI

// MARK: - Connection View (Bezier Curve)

struct ConnectionView: View {
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

    var body: some View {
        Canvas { context, size in
            let path = bezierPath(from: from, to: to)

            // Calculate effective line width and colors based on state
            let effectiveLineWidth = isSelected ? lineWidth + 1.5 : (isHovered ? lineWidth + 1.0 : lineWidth)
            let effectiveColor = isSelected ? Color.blue : (isHovered ? color.opacity(0.9) : color)

            // Draw glow for selected or hovered
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

            // Draw subtle shadow
            context.stroke(
                path,
                with: .color(effectiveColor.opacity(0.15)),
                style: StrokeStyle(lineWidth: effectiveLineWidth + 1, lineCap: .round)
            )

            // Draw main line with gradient if both colors provided
            if animated {
                // Animated dashed line for pending connections
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
                // Use gradient if both colors are provided, otherwise solid color
                if let srcColor = sourceColor, let tgtColor = targetColor {
                    let gradient = Gradient(colors: [
                        isSelected ? Color.blue : srcColor,
                        isSelected ? Color.blue.opacity(0.8) : tgtColor
                    ])
                    // Create gradient from path start to end
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

                // Draw flow animation (subtle moving dots)
                if showFlowAnimation {
                    drawFlowAnimation(context: context, path: path)
                }
            }

            // Draw arrow head at the end
            drawArrowHead(context: context, path: path, color: isSelected ? Color.blue : (targetColor ?? effectiveColor))

            // Draw delete button on hover
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

        // Improved control point calculation for better curves
        var controlOffset: CGFloat

        // Handle edge cases: nodes directly above/below each other
        if abs(dx) < 50 {
            // Vertical or near-vertical connection
            controlOffset = max(abs(dy) * 0.3, 80)
        } else if abs(dy) < 50 {
            // Horizontal or near-horizontal connection
            controlOffset = min(abs(dx) * 0.5, distance * 0.4)
        } else {
            // Diagonal connection - use distance-based offset
            controlOffset = min(max(abs(dx) * 0.4, 100), distance * 0.45)
        }

        let control1 = CGPoint(x: start.x + controlOffset, y: start.y)
        let control2 = CGPoint(x: end.x - controlOffset, y: end.y)

        path.addCurve(to: end, control1: control1, control2: control2)

        return path
    }

    // MARK: - Flow Animation

    private func drawFlowAnimation(context: GraphicsContext, path: Path) {
        // Draw 3 subtle animated dots along the path
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

                // Fade in/out based on position
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
        // Get the tangent at the end of the path for proper alignment
        let endPoint = path.currentPoint ?? to
        let tangentLength: CGFloat = 0.02

        // Sample two points near the end to calculate tangent
        let trimmedPath = path.trimmedPath(from: max(0, 1 - tangentLength), to: 1)
        let pathPoints = extractPathPoints(trimmedPath)

        guard pathPoints.count >= 2 else {
            // Fallback to simple direction calculation
            drawSimpleArrowHead(context: context, at: endPoint, color: color)
            return
        }

        let lastPoint = pathPoints[pathPoints.count - 1]
        let secondLastPoint = pathPoints[pathPoints.count - 2]

        let dx = lastPoint.x - secondLastPoint.x
        let dy = lastPoint.y - secondLastPoint.y
        let angle = atan2(dy, dx)

        // Smoother, more elegant filled triangle arrow
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

        // Fill the arrow head
        context.fill(arrowPath, with: .color(color))

        // Add subtle stroke for definition
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

    // Helper to extract points from a path
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
        // Draw a small X button at the middle of the connection
        if let midPoint = path.trimmedPath(from: 0.5, to: 0.5).currentPoint {
            let buttonRadius: CGFloat = 8

            // Background circle
            var circlePath = Path()
            circlePath.addEllipse(in: CGRect(
                x: midPoint.x - buttonRadius,
                y: midPoint.y - buttonRadius,
                width: buttonRadius * 2,
                height: buttonRadius * 2
            ))

            context.fill(circlePath, with: .color(Color.red.opacity(0.8)))
            context.stroke(circlePath, with: .color(Color.white.opacity(0.3)), style: StrokeStyle(lineWidth: 1))

            // X mark
            let xSize: CGFloat = 5
            var xPath = Path()
            // First line of X
            xPath.move(to: CGPoint(x: midPoint.x - xSize / 2, y: midPoint.y - xSize / 2))
            xPath.addLine(to: CGPoint(x: midPoint.x + xSize / 2, y: midPoint.y + xSize / 2))
            // Second line of X
            xPath.move(to: CGPoint(x: midPoint.x + xSize / 2, y: midPoint.y - xSize / 2))
            xPath.addLine(to: CGPoint(x: midPoint.x - xSize / 2, y: midPoint.y + xSize / 2))

            context.stroke(xPath, with: .color(.white), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
    }
}

// MARK: - Pending Connection View

struct PendingConnectionView: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color
    var isSnapped: Bool = false

    var body: some View {
        ConnectionView(
            from: from,
            to: to,
            color: isSnapped ? color : color.opacity(0.7),
            lineWidth: isSnapped ? 2.0 : 1.8,
            animated: !isSnapped,
            showFlowAnimation: false
        )
    }
}

// MARK: - Connection Preview View (for hover)

struct ConnectionPreviewView: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color

    var body: some View {
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

// MARK: - Preview

#Preview("Connection View") {
    VStack {
        // Horizontal connection
        ConnectionView(
            from: CGPoint(x: 50, y: 100),
            to: CGPoint(x: 250, y: 100),
            color: .blue
        )
        .frame(width: 300, height: 200)
        .background(Color(nsColor: .windowBackgroundColor))

        // Diagonal connection
        ConnectionView(
            from: CGPoint(x: 50, y: 50),
            to: CGPoint(x: 250, y: 150),
            color: .purple
        )
        .frame(width: 300, height: 200)
        .background(Color(nsColor: .windowBackgroundColor))

        // Pending connection (animated)
        PendingConnectionView(
            from: CGPoint(x: 50, y: 100),
            to: CGPoint(x: 200, y: 80),
            color: .orange
        )
        .frame(width: 300, height: 200)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
