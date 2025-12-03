import SwiftUI

// MARK: - Toolbar View

struct ToolbarView: View {
    @Bindable var state: CanvasState
    @Binding var showNodePalette: Bool
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        HStack(spacing: 12) {
            // Add node button with accent color
            Button(action: { showNodePalette.toggle() }) {
                Label("Add Node", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0x00/255.0, green: 0x70/255.0, blue: 0xF3/255.0))
            .popover(isPresented: $showNodePalette) {
                NodePaletteView(state: state, isPresented: $showNodePalette)
            }

            Divider()
                .frame(height: 20)
                .background(Color.gray.opacity(0.3))

            // Zoom controls
            HStack(spacing: 4) {
                Button(action: { state.zoomOut() }) {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.borderless)

                Text("\(Int(state.scale * 100))%")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                    .frame(width: 45)

                Button(action: { state.zoomIn() }) {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.borderless)

                Button(action: { state.resetView() }) {
                    Image(systemName: "1.magnifyingglass")
                }
                .buttonStyle(.borderless)
                .help("Reset to 100%")
            }

            Divider()
                .frame(height: 20)
                .background(Color.gray.opacity(0.3))

            // Selection info
            if state.hasSelection {
                HStack(spacing: 8) {
                    Text("\(state.selectedNodeIds.count) selected")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(DesignSystem.Colors.textSecondary(isDark: themeManager.isDarkMode))

                    Button(action: { state.removeSelectedNodes() }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }
            }

            Spacer()

            // Theme toggle button
            Menu {
                ForEach(AppTheme.allCases) { theme in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            themeManager.currentTheme = theme
                        }
                    }) {
                        HStack {
                            Image(systemName: theme.icon)
                            Text(theme.displayName)
                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: themeManager.currentTheme.icon)
                    .font(.system(size: 13))
                    .foregroundColor(DesignSystem.Colors.textSecondary(isDark: themeManager.isDarkMode))
            }
            .buttonStyle(.borderless)
            .help("Change Appearance")

            Divider()
                .frame(height: 20)
                .background(DesignSystem.Colors.divider(isDark: themeManager.isDarkMode).opacity(0.3))

            // Stats with monospace
            HStack(spacing: 16) {
                Label("\(state.nodes.count)", systemImage: "square.stack.3d.up")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textSecondary(isDark: themeManager.isDarkMode))

                Label("\(state.connections.count)", systemImage: "arrow.right")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textSecondary(isDark: themeManager.isDarkMode))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(DesignSystem.Colors.toolbarBackground(isDark: themeManager.isDarkMode))
    }
}

// MARK: - Node Palette View

struct NodePaletteView: View {
    @Bindable var state: CanvasState
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Node")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(NodeType.allCases) { type in
                    NodeTypeButton(type: type) {
                        addNode(type: type)
                    }
                }
            }
        }
        .padding()
        .frame(width: 280)
    }

    private func addNode(type: NodeType) {
        // Add node at center of visible canvas
        let centerPosition = CGPoint(
            x: 300 - state.offset.width / state.scale,
            y: 300 - state.offset.height / state.scale
        )
        state.addNode(type: type, at: centerPosition)
        isPresented = false
    }
}

// MARK: - Node Type Button

struct NodeTypeButton: View {
    let type: NodeType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(type.color)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Text(type.rawValue)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Toolbar") {
    VStack {
        ToolbarView(
            state: CanvasState.sampleState(),
            showNodePalette: .constant(false)
        )
        Spacer()
    }
}
