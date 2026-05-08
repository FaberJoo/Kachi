import SwiftUI

struct MarkdownBlockViewerView: View {
    let blocks: [MarkdownBlock]
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.backgroundPrimary)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case let .heading(level, text):
            inlineText(text)
                .font(fontForHeading(level))
                .fontWeight(.semibold)
                .foregroundStyle(theme.textPrimary)
        case let .paragraph(text):
            inlineText(text)
                .font(.body)
                .foregroundStyle(theme.textPrimary)
        case let .bulletItem(text):
            HStack(alignment: .top, spacing: 8) {
                Text("•").foregroundStyle(theme.textSecondary)
                inlineText(text).foregroundStyle(theme.textPrimary)
            }
        case let .orderedItem(number, text):
            HStack(alignment: .top, spacing: 8) {
                Text("\(number).").foregroundStyle(theme.textSecondary)
                inlineText(text).foregroundStyle(theme.textPrimary)
            }
        case let .taskItem(checked, text):
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(checked ? theme.statusSuccess : theme.textTertiary)
                inlineText(text).foregroundStyle(theme.textPrimary)
            }
        case let .quote(text):
            HStack(alignment: .top, spacing: 10) {
                Rectangle()
                    .fill(theme.borderStrong)
                    .frame(width: 3)
                inlineText(text)
                    .foregroundStyle(theme.textSecondary)
                    .italic()
            }
        case let .codeFence(language, code):
            VStack(alignment: .leading, spacing: 8) {
                if let language {
                    Text(language.uppercased())
                        .font(.caption2)
                        .foregroundStyle(theme.textTertiary)
                }
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .foregroundStyle(theme.textPrimary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func inlineText(_ raw: String) -> Text {
        if let value = try? AttributedString(markdown: raw) {
            return Text(value)
        }
        return Text(raw)
    }

    private func fontForHeading(_ level: Int) -> Font {
        switch level {
        case 1: return .largeTitle
        case 2: return .title
        case 3: return .title2
        case 4: return .title3
        default: return .headline
        }
    }
}
