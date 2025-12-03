// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Workflow",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        // Library - importable by other projects (Talkie, etc.)
        .library(name: "WFKit", targets: ["WFKit"]),
        // Demo app - example instantiation of WFKit
        .executable(name: "Workflow", targets: ["WorkflowApp"])
    ],
    targets: [
        // WFKit library - reusable components
        .target(
            name: "WFKit",
            path: "Sources/WFKit"
        ),
        // Demo app - imports WFKit
        .executableTarget(
            name: "WorkflowApp",
            dependencies: ["WFKit"],
            path: "Sources/WorkflowApp"
        )
    ]
)
