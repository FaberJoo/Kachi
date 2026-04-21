import SwiftUI

struct SidebarView: View {

    var appState: AppState
    var theme: AppTheme

    var body: some View {
        VStack(spacing: 0) {
            topToolbar
            Divider().background(theme.border)
            fileTree
            Spacer(minLength: 0)
            Divider().background(theme.border)
            bottomToolbar
        }
        .background(theme.sidebarBg)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Top toolbar

    private var topToolbar: some View {
        HStack(spacing: 2) {
            SidebarToolButton(icon: "magnifyingglass", help: "Search", theme: theme)
            SidebarToolButton(icon: "folder.badge.plus", help: "New Folder", theme: theme)
            SidebarToolButton(icon: "doc.badge.plus", help: "New Document", theme: theme)
            Spacer()
            SidebarToolButton(icon: "line.3.horizontal.decrease", help: "Sort", theme: theme)
        }
        .padding(.horizontal, 8)
        .frame(height: 36)
    }

    // MARK: - File tree (placeholder)

    private var fileTree: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Vault section header
                HStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(theme.textMuted)
                    Text("MyVault")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(theme.textMuted)
                        .textCase(.uppercase)
                        .kerning(0.5)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

                // Placeholder items
                ForEach(["Project Notes", "Ideas", "Journal", "References"], id: \.self) { name in
                    SidebarFileRow(name: name, theme: theme)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Bottom toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 2) {
            SidebarToolButton(icon: "magnifyingglass", help: "Search", theme: theme)
            Spacer()
            Text("MyVault")
                .font(.system(size: 11))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(1)
            Spacer()
            SidebarToolButton(icon: "questionmark.circle", help: "Help", theme: theme)
            SidebarToolButton(icon: "gearshape", help: "Settings", theme: theme)
        }
        .padding(.horizontal, 8)
        .frame(height: 34)
    }
}

// MARK: - Sub-components

private struct SidebarToolButton: View {
    let icon: String
    let help: String
    let theme: AppTheme
    @State private var isHovered = false

    var body: some View {
        Button {
            // TODO: implement individual actions
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(isHovered ? theme.textPrimary : theme.textSecondary)
                .frame(width: 28, height: 28)
                .background(isHovered ? theme.sidebarItemHover : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { isHovered = $0 }
    }
}

private struct SidebarFileRow: View {
    let name: String
    let theme: AppTheme
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .font(.system(size: 12))
                .foregroundStyle(theme.textMuted)
            Text(name)
                .font(.system(size: 13))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(isHovered ? theme.sidebarItemHover : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}

#Preview {
    let state = AppState()
    SidebarView(appState: state, theme: AppTheme(colorScheme: .dark))
        .frame(width: 240, height: 600)
}
