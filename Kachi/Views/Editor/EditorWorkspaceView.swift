import SwiftUI
import AppKit

private let editorCanvasHorizontalPadding: CGFloat = 24
private let blockGutterWidth: CGFloat = 44
private let blockContentInnerPadding: CGFloat = 8

struct EditorWorkspaceView: View {
    let activeTitle: String
    let onCommitTitle: (String) -> Void
    let onChangeContent: (String) -> Void
    let content: String
    let titleFocusRequestID: Int
    let titleWarningMessage: (String) -> String?

    @State private var blocks: [EditableMarkdownBlock] = []
    @State private var focusedBlockID: UUID?
    @State private var focusAtStartBlockID: UUID?
    @State private var hoveredBlockID: UUID?
    @State private var titleDraft: String = ""
    @State private var titleWarning: String?
    @FocusState private var isTitleFocused: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            titleBar

            ScrollView {
                ZStack(alignment: .topLeading) {
                    canvasTapLayer

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach($blocks) { $block in
                            blockRow(block: $block)
                        }

                        editorClickZone
                    }
                    .padding(.horizontal, editorCanvasHorizontalPadding)
                    .padding(.vertical, 16)
                }
                .frame(maxWidth: .infinity, minHeight: 520, alignment: .topLeading)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard focusedBlockID != nil else { return }
                    // Dismiss raw editing only when tapping outside block hover area.
                    if hoveredBlockID == nil {
                        dismissRawEditing()
                    }
                }
            }
        }
        .background(theme.backgroundPrimary)
        .onAppear {
            loadBlocksFromContent()
            titleDraft = activeTitle
        }
        .onChange(of: content) { _, newValue in
            let localComposed = MarkdownBlockParser.markdown(from: blocks)
            if newValue != localComposed {
                loadBlocksFromContent()
            }
        }
        .onChange(of: activeTitle) { _, newValue in
            if !isTitleFocused {
                titleDraft = newValue
            }
        }
        .onChange(of: titleFocusRequestID) { _, _ in
            titleDraft = activeTitle
            titleWarning = nil
            DispatchQueue.main.async {
                isTitleFocused = true
            }
        }
    }

    private var titleBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("Document title", text: $titleDraft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                    .focused($isTitleFocused)
                    .onChange(of: titleDraft) { _, newValue in
                        guard isTitleFocused else { return }
                        _ = evaluateAndCommitTitle(newValue)
                    }
                    .onSubmit {
                        if commitTitle() {
                            focusLastBlockForEditing()
                        }
                    }
                    .onChange(of: isTitleFocused) { _, focused in
                        if !focused {
                            _ = commitTitle()
                        }
                    }
                Spacer()
            }

            if let titleWarning {
                Text(titleWarning)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.statusWarning)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                }
        }
        .padding(.leading, editorCanvasHorizontalPadding + blockGutterWidth + blockContentInnerPadding)
        .padding(.trailing, editorCanvasHorizontalPadding)
        .padding(.vertical, 14)
        .background(theme.backgroundPrimary)
    }

    @ViewBuilder
    private func blockRow(block: Binding<EditableMarkdownBlock>) -> some View {
        let blockID = block.wrappedValue.id
        let isFocused = focusedBlockID == blockID
        let isHovered = hoveredBlockID == blockID

        HStack(alignment: .top, spacing: 8) {
            blockGutter(for: blockID, isVisible: isHovered || isFocused)

            Group {
                if isFocused {
                    BlockRawTextEditor(
                        text: block.raw,
                        isFocused: true,
                        placeCursorAtStart: focusAtStartBlockID == blockID,
                        onInsertBlockBelow: {
                            insertNewBlockBelow(blockID: blockID, focusAtStart: true)
                        },
                        onDeleteEmptyBlock: {
                            deleteEmptyBlockAndFocusPrevious(blockID: blockID)
                        },
                        onEscape: {
                            dismissRawEditing()
                        },
                        onBlur: {
                            if focusedBlockID == blockID {
                                dismissRawEditing()
                            }
                        }
                    )
                    .frame(height: blockEditorHeight(for: block.wrappedValue.raw))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(theme.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onChange(of: block.wrappedValue.raw) { _, _ in
                        persistBlocks()
                    }
                } else {
                    MarkdownBlockViewerView(blocks: MarkdownBlockParser.parse(block.wrappedValue.raw))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    .background(theme.backgroundPrimary)
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        focusedBlockID = blockID
                        focusAtStartBlockID = nil
                    }
            }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke((isFocused || isHovered) ? theme.borderStrong : Color.clear, lineWidth: 1)
            )
        }
        .onHover { hovering in
            if hovering {
                hoveredBlockID = blockID
            } else if hoveredBlockID == blockID {
                hoveredBlockID = nil
            }
        }
        .modifier(IBeamHoverCursor())
    }

    @ViewBuilder
    private func blockGutter(for blockID: UUID, isVisible: Bool) -> some View {
        HStack(spacing: 4) {
            Button(action: {
                insertNewBlockBelow(blockID: blockID, focusAtStart: true)
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)

            Menu {
                Button("Insert Block Below") {
                    insertNewBlockBelow(blockID: blockID, focusAtStart: true)
                }
                Button("Duplicate Block") {
                    duplicateBlock(blockID: blockID)
                }
                Divider()
                Button("Delete Block", role: .destructive) {
                    deleteBlock(blockID: blockID)
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 18, height: 18)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
        .opacity(isVisible ? 1 : 0)
        .frame(width: 44, alignment: .leading)
    }

    private var editorClickZone: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(maxWidth: .infinity)
            .frame(minHeight: blocks.isEmpty ? 220 : 40)
            .contentShape(Rectangle())
            .onTapGesture {
                if focusedBlockID != nil {
                    dismissRawEditing()
                    return
                }
                appendBlockAtEndAndFocus()
            }
            .modifier(IBeamHoverCursor())
    }

    private var canvasTapLayer: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                if focusedBlockID != nil {
                    dismissRawEditing()
                }
            }
            .allowsHitTesting(focusedBlockID != nil)
            .modifier(IBeamHoverCursor())
    }

    private func loadBlocksFromContent() {
        blocks = MarkdownBlockParser.editableBlocks(from: content)
        focusedBlockID = nil
        focusAtStartBlockID = nil
        hoveredBlockID = nil
    }

    private func persistBlocks() {
        onChangeContent(MarkdownBlockParser.markdown(from: blocks))
    }

    private func insertNewBlockBelow(blockID: UUID, focusAtStart: Bool) {
        guard let index = blocks.firstIndex(where: { $0.id == blockID }) else { return }
        let currentIsEmpty = blocks[index].raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if currentIsEmpty {
            focusedBlockID = blockID
            focusAtStartBlockID = nil
            return
        }
        let newBlock = EditableMarkdownBlock(raw: "")
        blocks.insert(newBlock, at: index + 1)
        focusedBlockID = newBlock.id
        focusAtStartBlockID = focusAtStart ? newBlock.id : nil
        persistBlocks()
    }

    private func deleteEmptyBlockAndFocusPrevious(blockID: UUID) {
        guard let index = blocks.firstIndex(where: { $0.id == blockID }) else { return }
        blocks.remove(at: index)

        if blocks.isEmpty {
            focusedBlockID = nil
            focusAtStartBlockID = nil
            hoveredBlockID = nil
            persistBlocks()
            return
        }

        let previousIndex = max(index - 1, 0)
        focusedBlockID = blocks[previousIndex].id
        focusAtStartBlockID = nil
        persistBlocks()
    }

    private func appendBlockAtEndAndFocus() {
        if let last = blocks.last,
           last.raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            focusedBlockID = last.id
            focusAtStartBlockID = nil
            return
        }
        let newBlock = EditableMarkdownBlock(raw: "")
        blocks.append(newBlock)
        focusedBlockID = newBlock.id
        focusAtStartBlockID = newBlock.id
        persistBlocks()
    }

    private func duplicateBlock(blockID: UUID) {
        guard let index = blocks.firstIndex(where: { $0.id == blockID }) else { return }
        let duplicate = EditableMarkdownBlock(raw: blocks[index].raw)
        blocks.insert(duplicate, at: index + 1)
        focusedBlockID = duplicate.id
        focusAtStartBlockID = duplicate.id
        persistBlocks()
    }

    private func deleteBlock(blockID: UUID) {
        guard let index = blocks.firstIndex(where: { $0.id == blockID }) else { return }
        blocks.remove(at: index)

        if blocks.isEmpty {
            focusedBlockID = nil
            focusAtStartBlockID = nil
            hoveredBlockID = nil
        } else {
            let nextIndex = min(index, blocks.count - 1)
            focusedBlockID = blocks[nextIndex].id
            focusAtStartBlockID = blocks[nextIndex].id
        }

        persistBlocks()
    }

    private func dismissRawEditing() {
        focusedBlockID = nil
        focusAtStartBlockID = nil
    }

    private func evaluateAndCommitTitle(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            titleWarning = nil
            return false
        }

        if let warning = titleWarningMessage(trimmed) {
            titleWarning = warning
            return false
        }

        titleWarning = nil
        onCommitTitle(trimmed)
        return true
    }

    private func commitTitle() -> Bool {
        let trimmed = titleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            titleDraft = activeTitle
            titleWarning = nil
            return false
        }

        let didCommit = evaluateAndCommitTitle(trimmed)
        if didCommit {
            titleDraft = trimmed
        }
        return didCommit
    }

    private func focusLastBlockForEditing() {
        if blocks.isEmpty {
            let newBlock = EditableMarkdownBlock(raw: "")
            blocks.append(newBlock)
            persistBlocks()
        }

        guard let last = blocks.last else { return }
        focusedBlockID = last.id
        focusAtStartBlockID = nil
        isTitleFocused = false
    }

    private func blockEditorHeight(for raw: String) -> CGFloat {
        let lineCount = max(raw.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).count, 1)
        let lineHeight: CGFloat = 22
        let verticalPadding: CGFloat = 14
        return max(44, CGFloat(lineCount) * lineHeight + verticalPadding)
    }
}

private struct IBeamHoverCursor: ViewModifier {
    @State private var cursorPushed = false

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                if hovering && !cursorPushed {
                    NSCursor.iBeam.push()
                    cursorPushed = true
                } else if !hovering && cursorPushed {
                    NSCursor.pop()
                    cursorPushed = false
                }
            }
            .onDisappear {
                if cursorPushed {
                    NSCursor.pop()
                    cursorPushed = false
                }
            }
    }
}
