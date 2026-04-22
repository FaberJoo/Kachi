import SwiftUI

struct FileTreeView: View {
    let nodes: [FileNode]
    var depth: Int = 0

    var body: some View {
        ForEach(nodes) { node in
            FileTreeRow(node: node, depth: depth)
            if node.isExpanded, let children = node.children {
                FileTreeView(nodes: children, depth: depth + 1)
            }
        }
    }
}

// MARK: - Row

private struct FileTreeRow: View {
    @Bindable var node: FileNode
    let depth: Int
    @Environment(\.theme) private var theme
    @Environment(\.vaultManager) private var vaultManager
    @State private var isHovered = false
    @State private var renameText: String = ""
    @FocusState private var renameFocused: Bool

    private var isSelected: Bool { vaultManager.selectedNode?.id == node.id }
    private var isRenaming: Bool { vaultManager.renamingNodeID == node.id }
    private var indentWidth: CGFloat { CGFloat(depth) * 14 }

    private var rowBackground: Color {
        if isSelected { return theme.surfaceActive }
        if isHovered { return theme.surfaceHover }
        return .clear
    }

    // The stem shown in normal display and in the rename field
    private var displayName: String {
        node.isDirectory ? node.name : node.url.deletingPathExtension().lastPathComponent
    }

    // Uppercase extension badge — nil for directories and .md files
    private var extensionBadge: String? {
        guard !node.isDirectory else { return nil }
        let ext = node.url.pathExtension.lowercased()
        guard !ext.isEmpty, ext != "md" else { return nil }
        return ext.uppercased()
    }

    // Background color used for the fade overlay (parent background when row is clear)
    private var fadeColor: Color {
        if isSelected { return theme.surfaceActive }
        if isHovered { return theme.surfaceHover }
        return theme.backgroundSecondary
    }

    var body: some View {
        HStack(spacing: 4) {
            Spacer().frame(width: indentWidth)

            if node.isDirectory {
                Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(isSelected ? theme.textPrimary : theme.textTertiary)
                    .frame(width: 12)
                    .onTapGesture { toggleExpand() }
            } else {
                Spacer().frame(width: 12)
            }

            Image(systemName: node.isDirectory ? "folder" : "doc.text")
                .font(.system(size: 12))
                .foregroundStyle(node.isDirectory ? theme.accentPrimary : theme.textTertiary)

            if isRenaming {
                TextField("", text: $renameText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.textPrimary)
                    .focused($renameFocused)
                    .onSubmit { commitRename() }
                    .onExitCommand { vaultManager.cancelRename() }
                    .onChange(of: renameFocused) { _, focused in
                        if !focused { vaultManager.cancelRename() }
                    }
            } else {
                nameContent
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(count: 2) {
            vaultManager.beginRenameSelected()
        }
        .onTapGesture {
            vaultManager.selectedNode = node
        }
        .onChange(of: vaultManager.renamingNodeID) { _, newID in
            if newID == node.id {
                renameText = displayName
                renameFocused = true
            }
        }
    }

    // MARK: - Name + badge

    @ViewBuilder
    private var nameContent: some View {
        HStack(spacing: 4) {
            Text(displayName)
                .font(.system(size: 13))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .trailing) {
                    LinearGradient(
                        colors: [fadeColor.opacity(0), fadeColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                    .allowsHitTesting(false)
                }

            if let badge = extensionBadge {
                Text(badge)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(theme.textTertiary)
                    .layoutPriority(1)
            }
        }
    }

    // MARK: - Actions

    private func toggleExpand() {
        if node.isExpanded {
            vaultManager.collapse(node: node)
        } else {
            Task { await vaultManager.expand(node: node) }
        }
    }

    private func commitRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            vaultManager.cancelRename()
            return
        }
        let newName: String
        if node.isDirectory {
            newName = trimmed
        } else {
            let ext = node.url.pathExtension
            newName = ext.isEmpty ? trimmed : "\(trimmed).\(ext)"
        }
        vaultManager.commitRename(node: node, to: newName)
    }
}

#Preview {
    let nodes: [FileNode] = {
        let folder = FileNode(url: URL(filePath: "/tmp/Notes"), isDirectory: true)
        folder.children = [
            FileNode(url: URL(filePath: "/tmp/Notes/ideas.md"), isDirectory: false),
            FileNode(url: URL(filePath: "/tmp/Notes/photo.png"), isDirectory: false),
            FileNode(url: URL(filePath: "/tmp/Notes/data.csv"), isDirectory: false)
        ]
        folder.isExpanded = true
        return [folder, FileNode(url: URL(filePath: "/tmp/todo.md"), isDirectory: false)]
    }()
    ScrollView {
        VStack(alignment: .leading, spacing: 0) {
            FileTreeView(nodes: nodes)
        }
    }
    .frame(width: 240, height: 300)
    .environment(\.theme, AppTheme.dark)
    .environment(\.vaultManager, VaultManager())
}
