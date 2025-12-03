import SwiftUI
import AppKit

// MARK: - App Theme

public enum WFAppearance: String, CaseIterable, Identifiable, Sendable {
    case dark
    case light
    case system

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .system: return "System"
        }
    }

    public var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Theme Manager

@Observable
public final class WFThemeManager {
    public var appearance: WFAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: "wfkitAppearance")
        }
    }

    public init() {
        if let saved = UserDefaults.standard.string(forKey: "wfkitAppearance"),
           let appearance = WFAppearance(rawValue: saved) {
            self.appearance = appearance
        } else {
            self.appearance = .dark
        }
    }

    public var isDark: Bool {
        switch appearance {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            return NSApp.effectiveAppearance.name == .darkAqua
        }
    }

    // MARK: - Canvas Colors

    public var canvasBackground: Color {
        isDark ? Color(hex: "0A0A0A") : Color(hex: "F5F5F5")
    }

    public var gridDot: Color {
        isDark ? Color(hex: "2A2A2A") : Color(hex: "D5D5D5")
    }

    // MARK: - Node Colors

    public var nodeBackground: Color {
        isDark ? Color(hex: "1A1A1A") : Color(hex: "FFFFFF")
    }

    public var nodeBackgroundHover: Color {
        isDark ? Color(hex: "2A2A2A") : Color(hex: "F0F0F0")
    }

    public var nodeBorder: Color {
        isDark ? Color(hex: "2A2A2A") : Color(hex: "D0D0D0")
    }

    public var nodeBorderHover: Color {
        isDark ? Color(hex: "3A3A3A") : Color(hex: "B0B0B0")
    }

    // MARK: - Panel/Inspector Colors

    public var panelBackground: Color {
        isDark ? Color(hex: "0D0D0D") : Color(hex: "F8F8F8")
    }

    public var sectionBackground: Color {
        isDark ? Color(hex: "161616") : Color(hex: "FFFFFF")
    }

    public var inputBackground: Color {
        isDark ? Color(hex: "1A1A1A") : Color(hex: "FFFFFF")
    }

    public var toolbarBackground: Color {
        isDark ? Color(hex: "1A1A1A") : Color(hex: "FFFFFF")
    }

    // MARK: - Border Colors

    public var border: Color {
        isDark ? Color(hex: "383838") : Color(hex: "D0D0D0")
    }

    public var borderHover: Color {
        isDark ? Color(hex: "484848") : Color(hex: "B0B0B0")
    }

    public var divider: Color {
        isDark ? Color(hex: "2A2A2A") : Color(hex: "E0E0E0")
    }

    // MARK: - Text Colors

    public var textPrimary: Color {
        isDark ? Color(hex: "F0F0F0") : Color(hex: "1A1A1A")
    }

    public var textSecondary: Color {
        isDark ? Color(hex: "B0B0B0") : Color(hex: "5A5A5A")
    }

    public var textTertiary: Color {
        isDark ? Color(hex: "707070") : Color(hex: "8A8A8A")
    }

    public var textPlaceholder: Color {
        isDark ? Color(hex: "5A5A5A") : Color(hex: "A0A0A0")
    }

    // MARK: - Accent Colors

    public var accent: Color {
        Color(hex: "0070F3") // Vercel blue
    }

    public var accentGlow: Color {
        Color(hex: "0084FF")
    }

    // MARK: - Semantic Colors

    public var success: Color { Color(hex: "30D158") }
    public var warning: Color { Color(hex: "FF9F0A") }
    public var error: Color { Color(hex: "FF453A") }
    public var info: Color { Color(hex: "64D2FF") }

    // MARK: - Connection Colors

    public var connectionDefault: Color {
        isDark ? Color(hex: "9A9A9A") : Color(hex: "6A6A6A")
    }

    public var connectionActive: Color { accent }
    public var connectionHover: Color { accentGlow }
}

// MARK: - Environment Key

private struct WFThemeManagerKey: EnvironmentKey {
    static let defaultValue = WFThemeManager()
}

public extension EnvironmentValues {
    var wfTheme: WFThemeManager {
        get { self[WFThemeManagerKey.self] }
        set { self[WFThemeManagerKey.self] = newValue }
    }
}

public extension View {
    func wfTheme(_ manager: WFThemeManager) -> some View {
        environment(\.wfTheme, manager)
    }
}

// MARK: - Design Constants

public enum WFDesign {
    // MARK: - Spacing

    public static let spacingXXS: CGFloat = 2
    public static let spacingXS: CGFloat = 6
    public static let spacingSM: CGFloat = 10
    public static let spacingMD: CGFloat = 14
    public static let spacingLG: CGFloat = 20
    public static let spacingXL: CGFloat = 28
    public static let spacingXXL: CGFloat = 40

    // MARK: - Node Layout

    public static let nodePadding: CGFloat = 12
    public static let nodeHandleSize: CGFloat = 10
    public static let nodeMinWidth: CGFloat = 180
    public static let nodeMinHeight: CGFloat = 60

    // MARK: - Grid

    public static let gridSize: CGFloat = 20
    public static let gridDotSize: CGFloat = 1.5

    // MARK: - Corner Radius

    public static let radiusXS: CGFloat = 4
    public static let radiusSM: CGFloat = 6
    public static let radiusMD: CGFloat = 8
    public static let radiusLG: CGFloat = 12
    public static let radiusXL: CGFloat = 16

    public static let nodeRadius: CGFloat = 10
    public static let nodeHandleRadius: CGFloat = 5

    // MARK: - Borders

    public static let borderThin: CGFloat = 1
    public static let borderMedium: CGFloat = 1.5
    public static let borderThick: CGFloat = 2
    public static let borderFocus: CGFloat = 2.5

    // MARK: - Input Fields

    public static let inputPadding: CGFloat = 10
    public static let sectionSpacing: CGFloat = 16
    public static let fieldSpacing: CGFloat = 12

    // MARK: - Animation Durations

    public static let animationFast: Double = 0.15
    public static let animationNormal: Double = 0.25
    public static let animationSlow: Double = 0.4

    // MARK: - Z-Index

    public static let zCanvas: Double = 0
    public static let zGrid: Double = 1
    public static let zConnections: Double = 10
    public static let zNodes: Double = 20
    public static let zNodeSelected: Double = 30
    public static let zPanels: Double = 40
    public static let zModals: Double = 50
}

// MARK: - Typography

public enum WFTypography {
    // Display
    public static let displayLarge = Font.system(size: 32, weight: .bold)
    public static let displayMedium = Font.system(size: 24, weight: .semibold)
    public static let displaySmall = Font.system(size: 20, weight: .semibold)

    // Body
    public static let bodyLarge = Font.system(size: 15, weight: .regular)
    public static let bodyMedium = Font.system(size: 13, weight: .regular)
    public static let bodySmall = Font.system(size: 11, weight: .regular)

    // Monospace
    public static let monoLarge = Font.system(size: 14, weight: .regular, design: .monospaced)
    public static let monoMedium = Font.system(size: 12, weight: .regular, design: .monospaced)
    public static let monoSmall = Font.system(size: 10, weight: .regular, design: .monospaced)

    // Labels
    public static let labelLarge = Font.system(size: 13, weight: .medium)
    public static let labelMedium = Font.system(size: 11, weight: .medium)
    public static let labelSmall = Font.system(size: 9, weight: .semibold)

    // Node
    public static let nodeTitle = Font.system(size: 13, weight: .semibold)
    public static let nodeSubtitle = Font.system(size: 11, weight: .regular)
    public static let nodeData = Font.system(size: 11, weight: .regular, design: .monospaced)
}

// MARK: - Color Presets

public enum WFColorPresets {
    public static let all = [
        "#FF9F0A", // Orange
        "#FFD60A", // Yellow
        "#30D158", // Green
        "#64D2FF", // Cyan
        "#0A84FF", // Blue
        "#BF5AF2", // Purple
        "#FF375F", // Pink
        "#FF453A", // Red
        "#AC8E68", // Brown
        "#98989D"  // Gray
    ]
}
