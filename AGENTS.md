# AGENTS.md

This file provides context for AI coding assistants working with WFKit.

## What is WFKit?

WFKit is a Swift Package that provides a native workflow/node editor for macOS and iOS apps. Think React Flow, but for SwiftUI. No WebViews, no Electron - pure native performance.

## Architecture Overview

```
Sources/WFKit/
├── Canvas/
│   ├── WorkflowCanvas.swift    # Main canvas with pan/zoom
│   └── NodeView.swift          # Individual node rendering
├── Models/
│   ├── CanvasState.swift       # @Observable state container
│   └── WorkflowNode.swift      # Node model
├── Inspector/
│   └── InspectorView.swift     # Property inspector panel
├── Toolbar/
│   └── ToolbarView.swift       # Canvas toolbar
└── Theme/
    └── WFTheme.swift           # Theming system
```

## Key Patterns

### State Management
- `CanvasState` is an `@Observable` class
- Use `@State var canvas = CanvasState()` in your view
- Pass to `WFWorkflowEditor(state: canvas)`

### Node Types
Built-in types: `.trigger`, `.action`, `.condition`, `.output`, `.llm`

Extend with custom types:
```swift
extension NodeType {
    static let custom = NodeType(id: "custom", icon: "star", color: .blue)
}
```

### Connections
- Nodes have input/output ports
- Connections are directed (source → target)
- Use `canvas.connect(from:to:)` or `canvas.connect(from:port:to:)`

## Common Tasks

### Add a node programmatically
```swift
let node = WorkflowNode(type: .action, title: "My Node", position: .init(x: 100, y: 100))
canvas.addNode(node)
```

### Remove a node
```swift
canvas.removeNode(node)
```

### Get all nodes
```swift
canvas.nodes  // [WorkflowNode]
```

### Get connections
```swift
canvas.connections  // [Connection]
```

## Build Commands

```bash
swift build           # Build the package
swift test            # Run tests
swift build -c release # Release build
```

## Demo App

The package includes a demo app. Open `Package.swift` in Xcode and run the `WFKitDemo` target.

## Dependencies

None. WFKit is dependency-free, using only SwiftUI and Foundation.
