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

    private var indentWidth: CGFloat { CGFloat(depth) * 14 }

    var body: some View {
        HStack(spacing: 4) {
            Spacer().frame(width: indentWidth)

            // Chevron (directories only)
            if node.isDirectory {
                Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(theme.textTertiary)
                    .frame(width: 12)
            } else {
                Spacer().frame(width: 12)
            }

            Image(systemName: node.isDirectory ? "folder" : "doc.text")
                .font(.system(size: 12))
                .foregroundStyle(node.isDirectory ? theme.accentPrimary : theme.textTertiary)

            Text(node.name)
                .font(.system(size: 13))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isHovered ? theme.surfaceHover : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            guard node.isDirectory else { return }
            if node.isExpanded {
                vaultManager.collapse(node: node)
            } else {
                Task { await vaultManager.expand(node: node) }
            }
        }
    }
}

#Preview {
    let nodes: [FileNode] = {
        let folder = FileNode(url: URL(filePath: "/tmp/Notes"), isDirectory: true)
        folder.children = [
            FileNode(url: URL(filePath: "/tmp/Notes/ideas.md"), isDirectory: false),
            FileNode(url: URL(filePath: "/tmp/Notes/journal.md"), isDirectory: false)
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
