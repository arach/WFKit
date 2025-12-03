import SwiftUI
import AppKit

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case dark
    case light
    case system

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .system: return "System"
        }
    }

    var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Theme Manager

@Observable
class ThemeManager {
    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        }
    }

    init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .dark
        }
    }

    var isDarkMode: Bool {
        switch currentTheme {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            return NSApp.effectiveAppearance.name == .darkAqua
        }
    }
}

/// Design System for Workflow - Tactical, dev-tool oriented aesthetic
/// Based on Talkie design principles adapted for node/workflow editors
enum DesignSystem {

    // MARK: - Colors

    enum Colors {
        // MARK: Theme-adaptive colors
        static func canvasBackground(isDark: Bool) -> Color {
            isDark ? Color(hex: "0A0A0A") : Color(hex: "F5F5F5")
        }

        static func nodeBackground(isDark: Bool) -> Color {
            isDark ? Color(hex: "1A1A1A") : Color(hex: "FFFFFF")
        }

        static func nodeBackgroundHover(isDark: Bool) -> Color {
            isDark ? Color(hex: "2A2A2A") : Color(hex: "F0F0F0")
        }

        static func panelBackground(isDark: Bool) -> Color {
            isDark ? Color(hex: "12121200") : Color(hex: "FAFAFA")
        }

        static func borderDefault(isDark: Bool) -> Color {
            isDark ? Color(hex: "2A2A2A") : Color(hex: "D0D0D0")
        }

        static func borderHover(isDark: Bool) -> Color {
            isDark ? Color(hex: "3A3A3A") : Color(hex: "B0B0B0")
        }

        static func textPrimary(isDark: Bool) -> Color {
            isDark ? Color(hex: "E5E5E5") : Color(hex: "1A1A1A")
        }

        static func textSecondary(isDark: Bool) -> Color {
            isDark ? Color(hex: "9A9A9A") : Color(hex: "6A6A6A")
        }

        static func textTertiary(isDark: Bool) -> Color {
            isDark ? Color(hex: "6A6A6A") : Color(hex: "9A9A9A")
        }

        static func gridDot(isDark: Bool) -> Color {
            isDark ? Color(hex: "2A2A2A") : Color(hex: "D5D5D5")
        }

        static func inspectorBackground(isDark: Bool) -> Color {
            isDark ? Color(hex: "12121200") : Color(hex: "F8F8F8")
        }

        static func toolbarBackground(isDark: Bool) -> Color {
            isDark ? Color(hex: "1A1A1A") : Color(hex: "FFFFFF")
        }

        static func sectionBackground(isDark: Bool) -> Color {
            isDark ? Color(hex: "1A1A1A") : Color(hex: "FFFFFF")
        }

        static func editorBackground(isDark: Bool) -> Color {
            isDark ? Color(hex: "0A0A0A") : Color(hex: "FAFAFA")
        }

        static func divider(isDark: Bool) -> Color {
            isDark ? Color(hex: "2A2A2A") : Color(hex: "E0E0E0")
        }

        // MARK: Tactical Grays (legacy, still available)
        static let tactical900 = Color(hex: "0A0A0A")  // Deep black
        static let tactical800 = Color(hex: "1A1A1A")  // Canvas background
        static let tactical700 = Color(hex: "2A2A2A")  // Card background
        static let tactical600 = Color(hex: "3A3A3A")  // Elevated elements
        static let tactical500 = Color(hex: "6A6A6A")  // Disabled/subdued
        static let tactical400 = Color(hex: "9A9A9A")  // Secondary text
        static let tactical300 = Color(hex: "CACACA")  // Primary text
        static let tactical200 = Color(hex: "E5E5E5")  // Bright text
        static let tactical100 = Color(hex: "F5F5F5")  // Highlights

        // MARK: Accent
        static let accent = Color(hex: "0070F3")       // Vercel blue
        static let accentGlow = Color(hex: "0084FF")   // Brighter glow state
        static let accentDark = Color(hex: "0058C2")   // Pressed state

        // MARK: Node Type Colors (Vibrant but tactical)
        static let nodeTypeTrigger = Color(hex: "FF9F0A")    // Orange - initiates flow
        static let nodeTypeLLM = Color(hex: "BF5AF2")        // Purple - AI/intelligence
        static let nodeTypeTransform = Color(hex: "0A84FF")  // Blue - data manipulation
        static let nodeTypeCondition = Color(hex: "FFD60A")  // Yellow - decision points
        static let nodeTypeAction = Color(hex: "30D158")     // Green - executes actions
        static let nodeTypeOutput = Color(hex: "FF375F")     // Pink/Red - final output

        // MARK: Semantic
        static let success = Color(hex: "30D158")      // Green
        static let warning = Color(hex: "FF9F0A")      // Orange
        static let error = Color(hex: "FF453A")        // Red
        static let info = Color(hex: "64D2FF")         // Cyan

        // MARK: Connection Lines
        static let connectionDefault = tactical400
        static let connectionActive = accent
        static let connectionHover = accentGlow
        static let connectionError = error

        // MARK: Semantic Surface Colors
        static let canvasBackground = tactical900
        static let nodeBackground = tactical700
        static let nodeBackgroundHover = tactical600
        static let panelBackground = tactical800
        static let borderDefault = tactical600
        static let borderFocus = accent
        static let borderHover = tactical500

        // MARK: Text Colors
        static let textPrimary = tactical200
        static let textSecondary = tactical400
        static let textTertiary = tactical500
        static let textOnAccent = tactical100

        // MARK: Node Type Background Tints (subtle overlays)
        static func nodeTypeBackgroundTint(_ nodeType: Color) -> Color {
            nodeType.opacity(0.08)
        }

        static func nodeTypeBorderTint(_ nodeType: Color) -> Color {
            nodeType.opacity(0.3)
        }
    }

    // MARK: - Typography

    enum Typography {
        // MARK: Display (Headers)
        static let displayLarge = Font.system(size: 32, weight: .bold, design: .default)
        static let displayMedium = Font.system(size: 24, weight: .semibold, design: .default)
        static let displaySmall = Font.system(size: 20, weight: .semibold, design: .default)

        // MARK: Body (UI Text)
        static let bodyLarge = Font.system(size: 15, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 13, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 11, weight: .regular, design: .default)

        // MARK: Monospace (Technical Data)
        static let monoLarge = Font.system(size: 14, weight: .regular, design: .monospaced)
        static let monoMedium = Font.system(size: 12, weight: .regular, design: .monospaced)
        static let monoSmall = Font.system(size: 10, weight: .regular, design: .monospaced)

        // MARK: Labels (Tactical/Tech Feel)
        static let labelLarge = Font.system(size: 13, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 11, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 9, weight: .semibold, design: .default)

        // MARK: Node Specific
        static let nodeTitle = Font.system(size: 13, weight: .semibold, design: .default)
        static let nodeSubtitle = Font.system(size: 11, weight: .regular, design: .default)
        static let nodeData = Font.system(size: 11, weight: .regular, design: .monospaced)

        // MARK: Tracking (Letter Spacing)
        static let trackingTight: CGFloat = -0.3
        static let trackingNormal: CGFloat = 0
        static let trackingWide: CGFloat = 0.6
        static let trackingTech: CGFloat = 1.2  // For uppercase labels
    }

    // MARK: - Spacing

    enum Spacing: CGFloat {
        case xxs = 2
        case xs = 6
        case sm = 10
        case md = 14
        case lg = 20
        case xl = 28
        case xxl = 40

        // Node specific spacing
        static let nodePadding: CGFloat = 12
        static let nodeHandleSize: CGFloat = 10
        static let nodeMinWidth: CGFloat = 180
        static let nodeMinHeight: CGFloat = 60

        // Grid spacing
        static let gridSize: CGFloat = 20
        static let gridDotSize: CGFloat = 1.5
    }

    // MARK: - Corner Radius

    enum CornerRadius: CGFloat {
        case xs = 4
        case sm = 8
        case md = 12
        case lg = 16
        case xl = 24

        // Node specific
        static let node: CGFloat = 10
        static let nodeHandle: CGFloat = 5
        static let panel: CGFloat = 12
    }

    // MARK: - Animations

    enum Animations {
        static let fast: TimeInterval = 0.15
        static let normal: TimeInterval = 0.25
        static let slow: TimeInterval = 0.4

        // Spring presets
        static let springDefault = Animation.spring(response: 0.35, dampingFraction: 0.75)
        static let springSnappy = Animation.spring(response: 0.25, dampingFraction: 0.8)
        static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.65)

        // Easing curves
        static let easeInOut = Animation.easeInOut(duration: normal)
        static let easeOut = Animation.easeOut(duration: fast)
        static let linear = Animation.linear(duration: fast)

        // Node specific
        static let nodeSelect = springSnappy
        static let nodeMove = linear
        static let connectionDraw = easeOut
    }

    // MARK: - Shadows

    enum Shadows {
        // Small shadow (buttons, small cards)
        static let small: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            color: Color.black.opacity(0.15),
            radius: 4,
            x: 0,
            y: 2
        )

        // Medium shadow (nodes, panels)
        static let medium: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            color: Color.black.opacity(0.25),
            radius: 8,
            x: 0,
            y: 4
        )

        // Large shadow (modals, popovers)
        static let large: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            color: Color.black.opacity(0.35),
            radius: 16,
            x: 0,
            y: 8
        )

        // Glow effects
        static func glow(color: Color, radius: CGFloat = 12) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color: color.opacity(0.5), radius: radius, x: 0, y: 0)
        }

        // Node states
        static let nodeDefault = medium
        static let nodeHover = large
        static let nodeSelected = glow(color: Colors.accent, radius: 16)
    }

    // MARK: - Borders

    enum Borders {
        static let thin: CGFloat = 1
        static let medium: CGFloat = 1.5
        static let thick: CGFloat = 2
        static let focus: CGFloat = 2.5

        // Node borders
        static let node: CGFloat = 1.5
        static let nodeSelected: CGFloat = 2
        static let connection: CGFloat = 2
    }

    // MARK: - Opacity

    enum Opacity {
        static let disabled: Double = 0.4
        static let muted: Double = 0.6
        static let subtle: Double = 0.8
        static let full: Double = 1.0

        // Effects
        static let overlay: Double = 0.9
        static let backdrop: Double = 0.7
        static let tint: Double = 0.12
    }

    // MARK: - Z-Index (Layers)

    enum ZIndex {
        static let canvas: Double = 0
        static let gridDots: Double = 1
        static let connections: Double = 10
        static let nodes: Double = 20
        static let nodeSelected: Double = 30
        static let panels: Double = 40
        static let modals: Double = 50
        static let tooltips: Double = 60
    }
}

// MARK: - Color Utilities

extension Color {
    /// Convert Color to NSColor for macOS compatibility
    var nsColor: NSColor {
        NSColor(self)
    }

    /// Adjust color brightness
    func adjustedBrightness(by factor: Double) -> Color {
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else { return self }

        let newBrightness = min(max(rgbColor.brightnessComponent + CGFloat(factor), 0), 1)
        return Color(
            hue: Double(rgbColor.hueComponent),
            saturation: Double(rgbColor.saturationComponent),
            brightness: Double(newBrightness)
        )
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply tactical card style
    func tacticalCard(isHovered: Bool = false, isSelected: Bool = false) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md.rawValue)
                    .fill(isHovered ? DesignSystem.Colors.nodeBackgroundHover : DesignSystem.Colors.nodeBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md.rawValue)
                    .stroke(
                        isSelected ? DesignSystem.Colors.borderFocus : DesignSystem.Colors.borderDefault,
                        lineWidth: isSelected ? DesignSystem.Borders.focus : DesignSystem.Borders.thin
                    )
            )
            .shadow(
                color: isSelected ? DesignSystem.Shadows.nodeSelected.color : DesignSystem.Shadows.medium.color,
                radius: isSelected ? DesignSystem.Shadows.nodeSelected.radius : DesignSystem.Shadows.medium.radius,
                x: 0,
                y: isSelected ? 0 : DesignSystem.Shadows.medium.y
            )
    }

    /// Apply tactical text style with tracking
    func tacticalText(tracking: CGFloat = DesignSystem.Typography.trackingNormal) -> some View {
        self
            .kerning(tracking)
            .foregroundColor(DesignSystem.Colors.textPrimary)
    }

    /// Apply mono text style
    func monoText(size: Font = DesignSystem.Typography.monoMedium) -> some View {
        self
            .font(size)
            .foregroundColor(DesignSystem.Colors.textSecondary)
    }
}
