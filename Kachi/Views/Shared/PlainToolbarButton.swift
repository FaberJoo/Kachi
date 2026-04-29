import SwiftUI
import AppKit

/// A borderless toolbar button backed by NSButton.
/// SwiftUI's ToolbarItem on macOS 14+ forces a capsule/glass background on all
/// child views, including plain Buttons and raw Images. Wrapping NSButton directly
/// with isBordered = false is the only reliable way to suppress that appearance.
struct PlainToolbarButton: NSViewRepresentable {
    let systemImage: String
    let tintColor: Color
    let action: () -> Void

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton()
        button.isBordered = false
        button.bezelStyle = .smallSquare
        button.imagePosition = .imageOnly
        button.image = NSImage(
            systemSymbolName: systemImage,
            accessibilityDescription: nil
        )
        button.contentTintColor = NSColor(tintColor)
        button.target = context.coordinator
        button.action = #selector(Coordinator.tapped)
        return button
    }

    func updateNSView(_ button: NSButton, context: Context) {
        button.image = NSImage(
            systemSymbolName: systemImage,
            accessibilityDescription: nil
        )
        button.contentTintColor = NSColor(tintColor)
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    final class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tapped() { action() }
    }
}
