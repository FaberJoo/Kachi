import Foundation

enum MarkdownBlock: Equatable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case bulletItem(String)
    case orderedItem(Int, String)
    case taskItem(checked: Bool, text: String)
    case quote(String)
    case codeFence(language: String?, code: String)
}

enum MarkdownBlockParser {
    static func editableBlocks(from markdown: String) -> [EditableMarkdownBlock] {
        var blocks: [EditableMarkdownBlock] = []
        var currentLines: [String] = []
        var inCodeFence = false

        let lines = markdown.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)

        func flushCurrentBlock() {
            let raw = currentLines.joined(separator: "\n")
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                blocks.append(EditableMarkdownBlock(raw: raw))
            }
            currentLines.removeAll(keepingCapacity: true)
        }

        for line in lines {
            if line.hasPrefix("```") {
                currentLines.append(line)
                inCodeFence.toggle()
                continue
            }

            if inCodeFence {
                currentLines.append(line)
                continue
            }

            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                flushCurrentBlock()
                continue
            }

            currentLines.append(line)
        }

        flushCurrentBlock()

        return blocks
    }

    static func markdown(from editableBlocks: [EditableMarkdownBlock]) -> String {
        let nonEmptyBlocks = editableBlocks
            .map { $0.raw.trimmingCharacters(in: .newlines) }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        if nonEmptyBlocks.isEmpty {
            return ""
        }

        return nonEmptyBlocks.joined(separator: "\n\n")
    }

    static func parse(_ markdown: String) -> [MarkdownBlock] {
        let lines = markdown.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
        var blocks: [MarkdownBlock] = []
        var paragraphBuffer: [String] = []
        var inCodeFence = false
        var codeLanguage: String?
        var codeLines: [String] = []

        func flushParagraph() {
            let text = paragraphBuffer.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                blocks.append(.paragraph(text))
            }
            paragraphBuffer.removeAll(keepingCapacity: true)
        }

        func flushCodeFence() {
            blocks.append(.codeFence(language: codeLanguage, code: codeLines.joined(separator: "\n")))
            codeLanguage = nil
            codeLines.removeAll(keepingCapacity: true)
        }

        for line in lines {
            if line.hasPrefix("```") {
                if inCodeFence {
                    flushCodeFence()
                    inCodeFence = false
                } else {
                    flushParagraph()
                    inCodeFence = true
                    let languageToken = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    codeLanguage = languageToken.isEmpty ? nil : languageToken
                }
                continue
            }

            if inCodeFence {
                codeLines.append(line)
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                flushParagraph()
                continue
            }

            if let heading = parseHeading(trimmed) {
                flushParagraph()
                blocks.append(heading)
                continue
            }

            if let task = parseTask(trimmed) {
                flushParagraph()
                blocks.append(task)
                continue
            }

            if let ordered = parseOrdered(trimmed) {
                flushParagraph()
                blocks.append(ordered)
                continue
            }

            if let bullet = parseBullet(trimmed) {
                flushParagraph()
                blocks.append(bullet)
                continue
            }

            if let quote = parseQuote(trimmed) {
                flushParagraph()
                blocks.append(quote)
                continue
            }

            paragraphBuffer.append(trimmed)
        }

        if inCodeFence {
            flushCodeFence()
        }

        flushParagraph()
        return blocks
    }

    private static func parseHeading(_ line: String) -> MarkdownBlock? {
        var level = 0
        for char in line {
            if char == "#" {
                level += 1
            } else {
                break
            }
        }

        guard level > 0, level <= 6 else { return nil }

        let content = String(line.dropFirst(level))
        guard content.first == " " else { return nil }

        return .heading(level: level, text: content.trimmingCharacters(in: .whitespaces))
    }

    private static func parseTask(_ line: String) -> MarkdownBlock? {
        guard line.count >= 6 else { return nil }
        guard line.hasPrefix("- [") || line.hasPrefix("* [") else { return nil }

        let markerIndex = line.index(line.startIndex, offsetBy: 3)
        let marker = line[markerIndex]
        guard marker == " " || marker == "x" || marker == "X" else { return nil }

        let closingIndex = line.index(line.startIndex, offsetBy: 4)
        guard line[closingIndex] == "]" else { return nil }

        let text = String(line.dropFirst(6))
        return .taskItem(checked: marker == "x" || marker == "X", text: text)
    }

    private static func parseOrdered(_ line: String) -> MarkdownBlock? {
        guard let dotIndex = line.firstIndex(of: ".") else { return nil }
        let prefix = line[..<dotIndex]
        guard let number = Int(prefix) else { return nil }

        let textStart = line.index(after: dotIndex)
        guard textStart < line.endIndex, line[textStart] == " " else { return nil }

        let content = String(line[textStart...]).trimmingCharacters(in: .whitespaces)
        return .orderedItem(number, content)
    }

    private static func parseBullet(_ line: String) -> MarkdownBlock? {
        guard line.count >= 2 else { return nil }
        guard line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") else { return nil }
        return .bulletItem(String(line.dropFirst(2)))
    }

    private static func parseQuote(_ line: String) -> MarkdownBlock? {
        guard line.hasPrefix(">") else { return nil }
        let content = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
        return .quote(content)
    }
}
