import Foundation
import SwiftUI

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

// MARK: - Node Types

enum NodeType: String, Codable, CaseIterable, Identifiable {
    case trigger = "Trigger"
    case llm = "LLM"
    case transform = "Transform"
    case condition = "Condition"
    case action = "Action"
    case output = "Output"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .trigger: return "bolt.fill"
        case .llm: return "brain"
        case .transform: return "wand.and.rays"
        case .condition: return "arrow.triangle.branch"
        case .action: return "play.fill"
        case .output: return "square.and.arrow.up"
        }
    }

    var color: Color {
        switch self {
        case .trigger: return Color(hex: "#FF9F0A") // Tactical orange
        case .llm: return Color(hex: "#BF5AF2") // Tactical purple
        case .transform: return Color(hex: "#0A84FF") // Tactical blue
        case .condition: return Color(hex: "#FFD60A") // Tactical yellow
        case .action: return Color(hex: "#30D158") // Tactical green
        case .output: return Color(hex: "#FF375F") // Tactical pink/red
        }
    }

    var defaultTitle: String {
        switch self {
        case .trigger: return "Start"
        case .llm: return "AI Process"
        case .transform: return "Transform"
        case .condition: return "If/Else"
        case .action: return "Action"
        case .output: return "Output"
        }
    }
}

// MARK: - Port (Connection Point)

struct Port: Identifiable, Codable, Hashable {
    let id: UUID
    var label: String
    var isInput: Bool

    init(id: UUID = UUID(), label: String, isInput: Bool) {
        self.id = id
        self.label = label
        self.isInput = isInput
    }

    static func input(_ label: String = "In") -> Port {
        Port(label: label, isInput: true)
    }

    static func output(_ label: String = "Out") -> Port {
        Port(label: label, isInput: false)
    }
}

// MARK: - Workflow Node

struct WorkflowNode: Identifiable, Codable, Hashable {
    let id: UUID
    var type: NodeType
    var title: String
    var position: CGPoint
    var size: CGSize
    var inputs: [Port]
    var outputs: [Port]
    var configuration: NodeConfiguration
    var isCollapsed: Bool
    var customColor: String? // Store as hex string for Codable support

    // Computed property for getting the effective color
    var effectiveColor: Color {
        if let hexColor = customColor {
            return Color(hex: hexColor)
        }
        return type.color
    }

    init(
        id: UUID = UUID(),
        type: NodeType,
        title: String? = nil,
        position: CGPoint = .zero,
        size: CGSize = CGSize(width: 200, height: 120),
        inputs: [Port]? = nil,
        outputs: [Port]? = nil,
        configuration: NodeConfiguration = NodeConfiguration(),
        isCollapsed: Bool = false,
        customColor: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title ?? type.defaultTitle
        self.position = position
        self.size = size
        self.inputs = inputs ?? Self.defaultInputs(for: type)
        self.outputs = outputs ?? Self.defaultOutputs(for: type)
        self.configuration = configuration
        self.isCollapsed = isCollapsed
        self.customColor = customColor
    }

    static func defaultInputs(for type: NodeType) -> [Port] {
        switch type {
        case .trigger:
            return [] // Triggers have no inputs
        case .condition:
            return [.input("In")]
        default:
            return [.input("In")]
        }
    }

    static func defaultOutputs(for type: NodeType) -> [Port] {
        switch type {
        case .output:
            return [] // Output nodes have no outputs
        case .condition:
            return [.output("True"), .output("False")]
        default:
            return [.output("Out")]
        }
    }

    // Hashable conformance for CGPoint and CGSize
    static func == (lhs: WorkflowNode, rhs: WorkflowNode) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Note: CGPoint and CGSize are already Codable in macOS 14+

// MARK: - Node Configuration

struct NodeConfiguration: Codable, Hashable {
    // LLM settings
    var prompt: String?
    var systemPrompt: String?
    var model: String?
    var temperature: Double?
    var maxTokens: Int?

    // Transform settings
    var transformType: String?
    var expression: String?

    // Condition settings
    var condition: String?

    // Action settings
    var actionType: String?
    var actionConfig: [String: String]?

    // Generic key-value for extensibility
    var customFields: [String: String]?

    init(
        prompt: String? = nil,
        systemPrompt: String? = nil,
        model: String? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        transformType: String? = nil,
        expression: String? = nil,
        condition: String? = nil,
        actionType: String? = nil,
        actionConfig: [String: String]? = nil,
        customFields: [String: String]? = nil
    ) {
        self.prompt = prompt
        self.systemPrompt = systemPrompt
        self.model = model
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.transformType = transformType
        self.expression = expression
        self.condition = condition
        self.actionType = actionType
        self.actionConfig = actionConfig
        self.customFields = customFields
    }
}
