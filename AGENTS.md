# AGENTS.md

This file provides context for AI coding assistants working with WFKit.

## What is WFKit?

WFKit is a Swift Package that provides a native workflow/node editor for macOS and iOS apps. Think React Flow, but for SwiftUI. No WebViews, no Electron - pure native performance.

## Critical Concept: Schema vs Instance

**This is the most important architectural concept to understand.**

WFKit separates two concerns:

### Schema (Type Definitions)
The **schema** describes *what kinds of nodes exist* and *what fields they have*. It's the application's type system - stable metadata that doesn't change per workflow.

- Defined once by the host app at initialization
- Describes node types (LLM, Notification, Condition, etc.)
- Defines field metadata (display names, types, ordering, help text)
- Passed via `WFSchemaProvider` protocol

### Instance (Runtime Data)
The **instance** is the actual workflow data - specific nodes, their positions, their field values, and their connections.

- Changes as users edit the workflow
- Contains node positions, titles, customFields values
- Stored in `CanvasState` and `WorkflowNode` models
- Serializable to JSON for persistence

### Why This Matters

The instance (`WorkflowNode.configuration.customFields`) stores raw key-value data like:
```json
{"_0.modelId": "gpt-4o", "_0.prompt": "Summarize...", "_0.temperature": "0.7"}
```

The schema tells WFKit *how to interpret and display* that data:
```swift
WFFieldSchema(id: "_0.modelId", displayName: "Model", type: .picker([...]), order: 0)
WFFieldSchema(id: "_0.prompt", displayName: "Prompt", type: .text, order: 1)
WFFieldSchema(id: "_0.temperature", displayName: "Temperature", type: .slider(min: 0, max: 2, step: 0.1), order: 2)
```

Without schema, WFKit falls back to auto-formatting keys (`_0.modelId` → "Model Id") and showing all fields alphabetically. With schema, the inspector shows properly labeled, ordered, grouped fields with appropriate controls.

### Integration Pattern

```swift
// Host app defines schema once
struct MyAppSchema: WFSchemaProvider {
    let nodeTypes: [WFNodeTypeSchema] = [
        WFNodeTypeSchema(
            id: "LLM",
            displayName: "AI Generation",
            category: "Processing",
            fields: [
                WFFieldSchema(id: "_0.modelId", displayName: "Model", type: .string, order: 0),
                WFFieldSchema(id: "_0.prompt", displayName: "Prompt", type: .text, order: 1),
            ]
        )
    ]
}

// Pass schema at initialization - it defines the world
WFWorkflowEditor(
    state: canvasState,      // Instance: changes per workflow
    schema: MyAppSchema(),   // Schema: stable type definitions
    isReadOnly: false
)
```

## Architecture Overview

```
Sources/WFKit/
├── Canvas/
│   ├── WorkflowCanvas.swift    # Main canvas with pan/zoom
│   └── NodeView.swift          # Individual node rendering
├── Models/
│   ├── CanvasState.swift       # @Observable state container
│   ├── WorkflowNode.swift      # Node model (instance data)
│   └── WFSchema.swift          # Schema types (type definitions)
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
