//
//  WFDesign.swift
//  WFKit
//
//  Design tokens for WFKit components.
//  Injectable theming allows each app to customize appearance.
//

import SwiftUI

// MARK: - Theme Protocol

/// Protocol for providing theme colors to WFKit components.
/// Implement this in your app to customize the appearance.
public protocol WFTheme {
    var inputBackground: Color { get }
    var border: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var sectionBackground: Color { get }
    var labelColor: Color { get }
    var panelBackground: Color { get }

    // Geometry
    var cornerRadius: CGFloat { get }
    var borderWidth: CGFloat { get }
}

// Default implementations
public extension WFTheme {
    var cornerRadius: CGFloat { 6 }
    var borderWidth: CGFloat { 1 }
}

// MARK: - Default Themes

/// Default dark theme
public struct WFDarkTheme: WFTheme {
    public init() {}

    public var inputBackground: Color { Color(white: 0.1) }
    public var border: Color { Color(white: 0.2) }
    public var textPrimary: Color { Color(white: 0.95) }
    public var textSecondary: Color { Color(white: 0.55) }
    public var sectionBackground: Color { Color(white: 0.08) }
    public var labelColor: Color { Color(white: 0.5) }
    public var panelBackground: Color { Color(white: 0.05) }
}

/// Default light theme
public struct WFLightTheme: WFTheme {
    public init() {}

    public var inputBackground: Color { Color(white: 0.98) }
    public var border: Color { Color(white: 0.85) }
    public var textPrimary: Color { Color(white: 0.1) }
    public var textSecondary: Color { Color(white: 0.45) }
    public var sectionBackground: Color { Color(white: 0.96) }
    public var labelColor: Color { Color(white: 0.4) }
    public var panelBackground: Color { Color(white: 0.98) }
}

/// Sharp minimal dark theme - thin lines, sharp corners, high contrast grays
public struct WFSharpDarkTheme: WFTheme {
    public init() {}

    public var inputBackground: Color { Color(white: 0.06) }
    public var border: Color { Color(white: 0.15) }
    public var textPrimary: Color { Color(white: 0.92) }
    public var textSecondary: Color { Color(white: 0.5) }
    public var sectionBackground: Color { Color(white: 0.04) }
    public var labelColor: Color { Color(white: 0.45) }
    public var panelBackground: Color { Color.black }

    // Sharp geometry
    public var cornerRadius: CGFloat { 0 }
    public var borderWidth: CGFloat { 0.5 }
}

/// Sharp minimal light theme - thin lines, sharp corners, crisp grays
public struct WFSharpLightTheme: WFTheme {
    public init() {}

    public var inputBackground: Color { Color.white }
    public var border: Color { Color(white: 0.8) }
    public var textPrimary: Color { Color(white: 0.08) }
    public var textSecondary: Color { Color(white: 0.5) }
    public var sectionBackground: Color { Color(white: 0.97) }
    public var labelColor: Color { Color(white: 0.45) }
    public var panelBackground: Color { Color(white: 0.95) }

    // Sharp geometry
    public var cornerRadius: CGFloat { 0 }
    public var borderWidth: CGFloat { 0.5 }
}

// MARK: - Theme Environment

/// Environment key for WFKit theme
private struct WFThemeKey: EnvironmentKey {
    static let defaultValue: WFTheme = WFDarkTheme()
}

public extension EnvironmentValues {
    var wfTheme: WFTheme {
        get { self[WFThemeKey.self] }
        set { self[WFThemeKey.self] = newValue }
    }
}

public extension View {
    /// Apply a WFKit theme to this view hierarchy
    func wfTheme(_ theme: WFTheme) -> some View {
        environment(\.wfTheme, theme)
    }
}

// MARK: - Adaptive Theme

/// Theme that automatically switches based on color scheme
public struct WFAdaptiveTheme: WFTheme {
    private let isDark: Bool

    public init(colorScheme: ColorScheme) {
        self.isDark = colorScheme == .dark
    }

    public var inputBackground: Color {
        isDark ? Color(white: 0.1) : Color(white: 0.98)
    }
    public var border: Color {
        isDark ? Color(white: 0.2) : Color(white: 0.85)
    }
    public var textPrimary: Color {
        isDark ? Color(white: 0.95) : Color(white: 0.1)
    }
    public var textSecondary: Color {
        isDark ? Color(white: 0.55) : Color(white: 0.45)
    }
    public var sectionBackground: Color {
        isDark ? Color(white: 0.08) : Color(white: 0.96)
    }
    public var labelColor: Color {
        isDark ? Color(white: 0.5) : Color(white: 0.4)
    }
    public var panelBackground: Color {
        isDark ? Color(white: 0.05) : Color(white: 0.98)
    }
}

// MARK: - Theme Presets

/// Predefined theme options
public enum WFThemePreset: String, CaseIterable, Identifiable {
    case dark = "Dark"
    case light = "Light"
    case sharpDark = "Sharp Dark"
    case sharpLight = "Sharp Light"

    public var id: String { rawValue }

    public var theme: WFTheme {
        switch self {
        case .dark: return WFDarkTheme()
        case .light: return WFLightTheme()
        case .sharpDark: return WFSharpDarkTheme()
        case .sharpLight: return WFSharpLightTheme()
        }
    }

    public var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .sharpDark: return "square.fill"
        case .sharpLight: return "square"
        }
    }
}

// MARK: - Design Constants

public enum WFDesign {
    public static let inputPadding: CGFloat = 10
    public static let sectionSpacing: CGFloat = 16
    public static let fieldSpacing: CGFloat = 12

    // Spacing
    public static let spacingXS: CGFloat = 6
    public static let spacingSM: CGFloat = 10
    public static let spacingMD: CGFloat = 14
    public static let spacingLG: CGFloat = 20
}
