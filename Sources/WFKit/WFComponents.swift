//
//  WFComponents.swift
//  WFKit
//
//  Reusable form components for inspector/detail panels.
//  Clean, minimal styling. Uses WFTheme from environment.
//

import SwiftUI

// MARK: - Panel Container

/// Main container for detail/inspector panels
public struct WFPanel<Content: View>: View {
    @Environment(\.wfTheme) private var theme
    let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WFDesign.sectionSpacing) {
                content()
            }
            .padding(WFDesign.spacingLG)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.panelBackground)
    }
}

// MARK: - Collapsible Section

/// Collapsible section with header and icon
public struct WFSection<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    let content: () -> Content

    @Environment(\.wfTheme) private var theme

    public init(
        _ title: String,
        icon: String = "folder",
        isExpanded: Binding<Bool> = .constant(true),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self._isExpanded = isExpanded
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: WFDesign.spacingSM) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 16)

                    Text(title.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(theme.textSecondary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(theme.textSecondary.opacity(0.6))
                }
                .padding(.vertical, WFDesign.spacingSM)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Content
            if isExpanded {
                VStack(alignment: .leading, spacing: WFDesign.fieldSpacing) {
                    content()
                }
                .padding(.top, WFDesign.spacingSM)
                .padding(.bottom, WFDesign.spacingMD)
            }
        }
        .padding(.horizontal, WFDesign.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.sectionBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .strokeBorder(theme.border, lineWidth: theme.borderWidth)
        )
    }
}

// MARK: - Labeled Form Field

/// Horizontal label + field layout
public struct WFField<Content: View>: View {
    let label: String
    let labelWidth: CGFloat
    let content: () -> Content

    @Environment(\.wfTheme) private var theme

    public init(_ label: String, labelWidth: CGFloat = 65, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.labelWidth = labelWidth
        self.content = content
    }

    public var body: some View {
        HStack(alignment: .center, spacing: WFDesign.spacingMD) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.labelColor)
                .frame(width: labelWidth, alignment: .trailing)

            content()
        }
    }
}

// MARK: - Text Field Style

/// Clean text field style
public struct WFTextFieldStyle: TextFieldStyle {
    @Environment(\.wfTheme) private var theme

    public init() {}

    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .padding(.horizontal, WFDesign.inputPadding)
            .padding(.vertical, 8)
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(theme.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(theme.inputBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .strokeBorder(theme.border, lineWidth: theme.borderWidth)
            )
    }
}

// MARK: - Text Editor

/// Clean multiline text editor
public struct WFTextEditor: View {
    @Binding var text: String
    var placeholder: String
    var minHeight: CGFloat

    @Environment(\.wfTheme) private var theme

    public init(text: Binding<String>, placeholder: String = "", minHeight: CGFloat = 80) {
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty && !placeholder.isEmpty {
                Text(placeholder)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(theme.textSecondary.opacity(0.6))
                    .padding(.horizontal, WFDesign.inputPadding + 4)
                    .padding(.vertical, 10)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(theme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, WFDesign.inputPadding - 4)
                .padding(.vertical, 6)
        }
        .frame(minHeight: minHeight)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.inputBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .strokeBorder(theme.border, lineWidth: theme.borderWidth)
        )
    }
}

// MARK: - Picker

/// Clean picker/dropdown style
public struct WFPicker<SelectionValue: Hashable, Content: View>: View {
    let label: String
    @Binding var selection: SelectionValue
    let content: () -> Content

    @Environment(\.wfTheme) private var theme

    public init(_ label: String, selection: Binding<SelectionValue>, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self._selection = selection
        self.content = content
    }

    public var body: some View {
        Picker(label, selection: $selection) {
            content()
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .padding(.horizontal, WFDesign.inputPadding)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.inputBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .strokeBorder(theme.border, lineWidth: theme.borderWidth)
        )
    }
}

// MARK: - Info Row

/// Read-only info display row
public struct WFInfoRow: View {
    let label: String
    let value: String
    var icon: String?

    @Environment(\.wfTheme) private var theme

    public init(label: String, value: String, icon: String? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: WFDesign.spacingSM) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textSecondary)
                    .frame(width: 16)
            }

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.labelColor)

            Spacer()

            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(theme.textPrimary)
        }
        .padding(.horizontal, WFDesign.inputPadding)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.sectionBackground)
        )
    }
}

// MARK: - Action Button

/// Compact action button for panels
public struct WFActionButton: View {
    let title: String
    let icon: String
    var style: Style
    let action: () -> Void

    @Environment(\.wfTheme) private var theme

    public enum Style {
        case `default`
        case destructive
        case primary
    }

    public init(_ title: String, icon: String, style: Style = .default, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    private var foregroundColor: Color {
        switch style {
        case .default: return theme.textSecondary
        case .destructive: return .red.opacity(0.8)
        case .primary: return .accentColor
        }
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: WFDesign.spacingXS) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(1)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, WFDesign.spacingSM)
            .padding(.vertical, WFDesign.spacingXS)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(theme.sectionBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .strokeBorder(theme.border, lineWidth: theme.borderWidth)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Divider

/// Subtle horizontal divider
public struct WFDivider: View {
    @Environment(\.wfTheme) private var theme

    public init() {}

    public var body: some View {
        Rectangle()
            .fill(theme.border)
            .frame(height: 0.5)
            .padding(.vertical, WFDesign.spacingXS)
    }
}
