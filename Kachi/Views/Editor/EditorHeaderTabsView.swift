import SwiftUI

struct EditorHeaderTabsView: View {
    let tabs: [EditorDocumentTab]
    let activeTabID: UUID?
    let onSelect: (UUID) -> Void
    let onClose: (UUID) -> Void
    let onAdd: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tabs) { tab in
                        tabItem(tab)
                    }
                }
                .padding(.vertical, 6)
            }

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(theme.surfaceHover)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 10)
        }
        .padding(.leading, 10)
        .frame(height: 42)
        .background(theme.backgroundPrimary)
    }

    @ViewBuilder
    private func tabItem(_ tab: EditorDocumentTab) -> some View {
        let isActive = tab.id == activeTabID
        HStack(spacing: 8) {
            Button(action: { onSelect(tab.id) }) {
                HStack(spacing: 6) {
                    Text(tab.title)
                        .lineLimit(1)
                    if tab.isDirty {
                        Circle()
                            .fill(theme.accentPrimary)
                            .frame(width: 6, height: 6)
                    }
                }
                .foregroundStyle(isActive ? theme.textPrimary : theme.textSecondary)
            }
            .buttonStyle(.plain)

            Button(action: { onClose(tab.id) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? theme.surfaceActive : theme.surfaceHover)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
    }
}

