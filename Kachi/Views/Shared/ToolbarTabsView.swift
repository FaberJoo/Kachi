import SwiftUI

struct ToolbarTabsView: View {
    let tabs: [EditorDocumentTab]
    let activeTabID: UUID?
    let editorBackgroundColor: Color
    let onSelect: (UUID) -> Void
    let onClose: (UUID) -> Void
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tabs) { tab in
                        tabChip(tab)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxWidth: 520)

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 30)
        .offset(y: 4)
    }

    @ViewBuilder
    private func tabChip(_ tab: EditorDocumentTab) -> some View {
        let isActive = tab.id == activeTabID
        HStack(spacing: 6) {
            Button(action: { onSelect(tab.id) }) {
                HStack(spacing: 5) {
                    Text(tab.title)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    if tab.isDirty {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 5, height: 5)
                    }
                }
            }
            .buttonStyle(.plain)

            Button(action: { onClose(tab.id) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(isActive ? editorBackgroundColor : Color.primary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(isActive ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.12), lineWidth: 1)
        )
    }
}
