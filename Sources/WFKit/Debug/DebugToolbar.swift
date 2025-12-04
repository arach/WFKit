//
//  DebugToolbar.swift
//  WFKit
//
//  Generic debug toolbar - available in DEBUG builds only
//

import SwiftUI
import AppKit

#if DEBUG

// MARK: - Data Types

public struct DebugSection: Identifiable {
    public let id = UUID()
    public let title: String
    public let rows: [(key: String, value: String)]

    public init(_ title: String, _ rows: [(String, String)]) {
        self.title = title
        self.rows = rows.map { (key: $0.0, value: $0.1) }
    }
}

public struct DebugAction: Identifiable {
    public let id = UUID()
    public let icon: String
    public let label: String
    public let destructive: Bool
    public let action: () -> Void

    public init(_ label: String, icon: String, destructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.destructive = destructive
        self.action = action
    }
}

/// A group of actions displayed horizontally on the same row
public struct DebugActionGroup: Identifiable {
    public let id = UUID()
    public let actions: [DebugAction]

    public init(_ actions: [DebugAction]) {
        self.actions = actions
    }

    public init(_ actions: DebugAction...) {
        self.actions = actions
    }
}

/// Wrapper enum for actions that can be single or grouped
public enum DebugActionItem: Identifiable {
    case single(DebugAction)
    case group(DebugActionGroup)

    public var id: UUID {
        switch self {
        case .single(let action): return action.id
        case .group(let group): return group.id
        }
    }
}

// MARK: - Debug Toolbar

public struct DebugToolbar: View {
    @State private var isExpanded = false
    @State private var showCopiedFeedback = false

    let title: String
    let icon: String
    let sections: [DebugSection]
    let actionItems: [DebugActionItem]
    let copyHandler: (() -> String)?

    /// Initialize with action items (supports grouping)
    public init(
        title: String = "DEV",
        icon: String = "ant.fill",
        sections: [DebugSection],
        actionItems: [DebugActionItem] = [],
        onCopy copyHandler: (() -> String)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.sections = sections
        self.actionItems = actionItems
        self.copyHandler = copyHandler
    }

    /// Backwards-compatible initializer with plain actions array
    public init(
        title: String = "DEV",
        icon: String = "ant.fill",
        sections: [DebugSection],
        actions: [DebugAction] = [],
        onCopy copyHandler: (() -> String)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.sections = sections
        self.actionItems = actions.map { .single($0) }
        self.copyHandler = copyHandler
    }

    /// Initialize with both plain actions and grouped action items
    public init(
        title: String = "DEV",
        icon: String = "ant.fill",
        sections: [DebugSection],
        actions: [DebugAction],
        actionItems: [DebugActionItem],
        onCopy copyHandler: (() -> String)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.sections = sections
        // Combine: single actions first, then grouped items
        self.actionItems = actions.map { .single($0) } + actionItems
        self.copyHandler = copyHandler
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isExpanded {
                expandedPanel
                    .transition(.scale(scale: 0.9, anchor: .bottomTrailing).combined(with: .opacity))
            }

            toggleButton
        }
        .padding(.trailing, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }

    // MARK: - Toggle Button

    private var toggleButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isExpanded ? .orange : .secondary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded Panel

    private var expandedPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Content
            VStack(alignment: .leading, spacing: 10) {
                ForEach(sections) { section in
                    SectionView(section: section)
                }

                if !actionItems.isEmpty || copyHandler != nil {
                    ActionsView(
                        actionItems: actionItems,
                        copyHandler: copyHandler,
                        showCopiedFeedback: $showCopiedFeedback
                    )
                }
            }
            .padding(10)
            .padding(.bottom, 6)
        }
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}

// MARK: - Section View

private struct SectionView: View {
    let section: DebugSection

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(section.title)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(1)
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                ForEach(Array(section.rows.enumerated()), id: \.offset) { index, row in
                    HStack {
                        Text(row.key)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(row.value)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(index % 2 == 0 ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.clear)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
            )
        }
    }
}

// MARK: - Actions View

private struct ActionsView: View {
    let actionItems: [DebugActionItem]
    let copyHandler: (() -> String)?
    @Binding var showCopiedFeedback: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ACTIONS")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(1)
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                ForEach(actionItems) { item in
                    switch item {
                    case .single(let action):
                        ActionButton(
                            icon: action.icon,
                            label: action.label,
                            destructive: action.destructive,
                            action: action.action
                        )
                    case .group(let group):
                        HStack(spacing: 4) {
                            ForEach(group.actions) { action in
                                ActionButton(
                                    icon: action.icon,
                                    label: action.label,
                                    destructive: action.destructive,
                                    compact: true,
                                    action: action.action
                                )
                            }
                        }
                    }
                }

                if let copyHandler = copyHandler {
                    ActionButton(
                        icon: showCopiedFeedback ? "checkmark" : "doc.on.clipboard",
                        label: showCopiedFeedback ? "Copied!" : "Copy Debug Info",
                        action: {
                            let text = copyHandler()
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(text, forType: .string)

                            withAnimation {
                                showCopiedFeedback = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    showCopiedFeedback = false
                                }
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let icon: String
    let label: String
    var destructive: Bool = false
    var compact: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if compact {
                // Compact mode: icon + short label, equal width for grouping
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(destructive ? .red : .accentColor)

                    Text(label)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(destructive ? .red : .primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .padding(.horizontal, 6)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(4)
            } else {
                // Full mode: icon + label + spacer
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(destructive ? .red : .accentColor)
                        .frame(width: 14)

                    Text(label)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(destructive ? .red : .primary)

                    Spacer()
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(4)
            }
        }
        .buttonStyle(.plain)
    }
}

#endif
