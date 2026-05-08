import SwiftUI
import AppKit

struct BlockRawTextEditor: NSViewRepresentable {
    @Binding var text: String
    var isFocused: Bool
    var placeCursorAtStart: Bool
    let onInsertBlockBelow: () -> Void
    let onDeleteEmptyBlock: () -> Void
    let onEscape: () -> Void
    let onBlur: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.isRichText = false
        textView.usesFontPanel = false
        textView.importsGraphics = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.backgroundColor = .clear
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = .labelColor
        textView.delegate = context.coordinator
        textView.string = text
        textView.textContainerInset = NSSize(width: 0, height: 4)

        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        context.coordinator.parent = self

        if textView.string != text {
            textView.string = text
        }

        if isFocused, textView.window?.firstResponder !== textView {
            DispatchQueue.main.async {
                guard textView.window != nil else { return }
                textView.window?.makeFirstResponder(textView)
                let location = placeCursorAtStart ? 0 : textView.string.utf16.count
                textView.setSelectedRange(NSRange(location: location, length: 0))
            }
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: BlockRawTextEditor
        weak var textView: NSTextView?

        init(_ parent: BlockRawTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView else { return }
            parent.text = textView.string
        }

        func textDidEndEditing(_ notification: Notification) {
            parent.onBlur()
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            let isShiftPressed = NSApp.currentEvent?.modifierFlags.contains(.shift) == true

            if commandSelector == #selector(NSResponder.insertLineBreak(_:)) ||
                (commandSelector == #selector(NSResponder.insertNewline(_:)) && isShiftPressed) {
                insertMarkdownHardBreak(in: textView)
                return true
            }

            if commandSelector == #selector(NSResponder.insertNewline(_:)) ||
                commandSelector == #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)) {
                parent.onInsertBlockBelow()
                return true
            }

            if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                let selectedRange = textView.selectedRange()
                let isAtStart = selectedRange.location == 0 && selectedRange.length == 0
                let isEmpty = textView.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                if isAtStart && isEmpty {
                    parent.onDeleteEmptyBlock()
                    return true
                }
            }

            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onEscape()
                return true
            }

            return false
        }

        private func insertMarkdownHardBreak(in textView: NSTextView) {
            let insertion = "\\\n"
            let selectedRange = textView.selectedRange()
            guard let range = Range(selectedRange, in: textView.string) else { return }

            let updated = textView.string.replacingCharacters(in: range, with: insertion)
            textView.string = updated
            parent.text = updated

            let cursor = selectedRange.location + insertion.utf16.count
            textView.setSelectedRange(NSRange(location: cursor, length: 0))
        }

    }
}
