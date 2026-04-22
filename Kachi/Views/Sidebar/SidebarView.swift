import SwiftUI

struct SidebarView: View {

    var appState: AppState
    @Environment(\.theme) private var theme
    @Environment(\.vaultManager) private var vaultManager

    var body: some View {
        VStack(spacing: 0) {
            topToolbar
            Divider()
            fileTree
            Divider()
            bottomToolbar
        }
        .background(theme.backgroundSecondary)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Top toolbar

    private var topToolbar: some View {
        HStack(spacing: 2) {
            SidebarToolButton(icon: "magnifyingglass", help: "Search")
            SidebarToolButton(icon: "folder.badge.plus", help: "Open Vault") {
                vaultManager.addVaultWithPicker()
            }
            SidebarToolButton(icon: "doc.badge.plus", help: "New Document")
            Spacer()
            SidebarToolButton(icon: "line.3.horizontal.decrease", help: "Sort")
        }
        .padding(.horizontal, 8)
        .frame(height: 36)
    }

    // MARK: - File tree

    private var fileTree: some View {
        Group {
            if vaultManager.activeVault == nil {
                EmptyVaultView()
            } else if vaultManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vaultManager.rootNodes.isEmpty {
                Text("No files")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.textTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Vault header
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(theme.textTertiary)
                            Text(vaultManager.activeVault?.name ?? "")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(theme.textTertiary)
                                .textCase(.uppercase)
                                .kerning(0.5)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)

                        FileTreeView(nodes: vaultManager.rootNodes)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Bottom toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 2) {
            SidebarToolButton(icon: "magnifyingglass", help: "Search")
            Spacer()
            Text(vaultManager.activeVault?.name ?? "No Vault")
                .font(.system(size: 11))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(1)
            Spacer()
            SidebarToolButton(icon: "questionmark.circle", help: "Help")
            SidebarToolButton(icon: "gearshape", help: "Settings")
        }
        .padding(.horizontal, 8)
        .frame(height: 34)
    }
}

// MARK: - Sub-components

private struct SidebarToolButton: View {
    let icon: String
    let help: String
    var action: (() -> Void)? = nil
    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        Button {
            action?()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(isHovered ? theme.textPrimary : theme.textSecondary)
                .frame(width: 28, height: 28)
                .background(isHovered ? theme.surfaceHover : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    let state = AppState()
    SidebarView(appState: state)
        .frame(width: 240, height: 600)
        .environment(\.theme, AppTheme.dark)
        .environment(\.vaultManager, VaultManager())
}
