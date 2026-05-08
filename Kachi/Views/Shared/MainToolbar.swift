import AppKit
import SwiftUI

// MARK: - Item identifier

extension NSToolbarItem.Identifier {
    static let sidebarToggle = NSToolbarItem.Identifier("com.kachi.sidebarToggle")
    static let centerTabs = NSToolbarItem.Identifier("com.kachi.centerTabs")
}

// MARK: - Hover-aware button

/// NSButton subclass that draws a rounded-rect hover background using NSTrackingArea.
/// Required because NSToolbarItem.isBordered = false removes the system bezel,
/// so we have to manage hover state ourselves.
private final class HoverButton: NSButton {

    var hoverBackgroundColor: NSColor = NSColor.labelColor.withAlphaComponent(0.08)

    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let old = trackingArea { removeTrackingArea(old) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        wantsLayer = true
        layer?.backgroundColor = hoverBackgroundColor.cgColor
        layer?.cornerRadius = 5
    }

    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = NSColor.clear.cgColor
    }
}

// MARK: - Toolbar delegate

/// Manages the app's main NSToolbar entirely in AppKit so we can set
/// NSToolbarItem.isBordered = false — the only way to suppress the
/// automatic capsule/glass background macOS 14 applies to all toolbar items.
@MainActor
final class MainToolbarDelegate: NSObject, NSToolbarDelegate {

    var onToggleSidebar: () -> Void = {}
    var onSelectTab: (UUID) -> Void = { _ in }
    var onCloseTab: (UUID) -> Void = { _ in }
    var onAddTab: () -> Void = {}

    private weak var sidebarButton: HoverButton?
    private weak var sidebarItem: NSToolbarItem?
    private weak var centerTabsHostingView: NSHostingView<AnyView>?
    private var tabs: [EditorDocumentTab] = []
    private var activeTabID: UUID?
    private var editorBackgroundColor: NSColor = .windowBackgroundColor

    // MARK: Update

    func update(isPinned: Bool, tintColor: NSColor, hoverColor: NSColor) {
        sidebarButton?.contentTintColor = tintColor
        sidebarButton?.hoverBackgroundColor = hoverColor
        sidebarItem?.toolTip = isPinned ? "Switch to auto-hide" : "Pin sidebar"
    }

    func updateTabs(_ tabs: [EditorDocumentTab], activeTabID: UUID?, editorBackgroundColor: NSColor? = nil) {
        self.tabs = tabs
        self.activeTabID = activeTabID
        if let editorBackgroundColor {
            self.editorBackgroundColor = editorBackgroundColor
        }
        centerTabsHostingView?.rootView = makeTabsView()
    }

    // MARK: NSToolbarDelegate

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.sidebarToggle, .flexibleSpace, .centerTabs, .flexibleSpace]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.sidebarToggle, .centerTabs, .flexibleSpace, .space]
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        if itemIdentifier == .centerTabs {
            let hostingView = NSHostingView(rootView: makeTabsView())
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingView.widthAnchor.constraint(equalToConstant: 560),
                hostingView.heightAnchor.constraint(equalToConstant: 36)
            ])
            centerTabsHostingView = hostingView

            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = ""
            item.paletteLabel = "Editor Tabs"
            item.view = hostingView
            if #available(macOS 14, *) {
                item.isBordered = false
            }
            return item
        }

        guard itemIdentifier == .sidebarToggle else { return nil }

        let button = HoverButton()
        button.isBordered = false
        button.bezelStyle = .smallSquare
        button.imagePosition = .imageOnly
        // Render the symbol at 15 pt so the icon itself is a bit larger
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        button.image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: "Toggle Sidebar")?
            .withSymbolConfiguration(symbolConfig)
        button.contentTintColor = .secondaryLabelColor
        button.target = self
        button.action = #selector(handleToggle)
        // Fix size via Auto Layout — minSize/maxSize are deprecated and may clip items
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 30),
            button.heightAnchor.constraint(equalToConstant: 24)
        ])
        button.wantsLayer = true
        sidebarButton = button

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = ""
        item.paletteLabel = "Toggle Sidebar"
        item.toolTip = "Pin sidebar"
        item.view = button
        // isBordered = false removes the macOS 14+ automatic capsule background
        if #available(macOS 14, *) {
            item.isBordered = false
        }
        sidebarItem = item
        return item
    }

    @objc private func handleToggle() {
        onToggleSidebar()
    }

    private func makeTabsView() -> AnyView {
        AnyView(
            ToolbarTabsView(
                tabs: tabs,
                activeTabID: activeTabID,
                editorBackgroundColor: Color(nsColor: editorBackgroundColor),
                onSelect: { [weak self] tabID in
                    self?.onSelectTab(tabID)
                },
                onClose: { [weak self] tabID in
                    self?.onCloseTab(tabID)
                },
                onAdd: { [weak self] in
                    self?.onAddTab()
                }
            )
        )
    }
}

// MARK: - Window toolbar installer

/// A zero-size NSView that installs the AppKit toolbar into the host window
/// on first appearance. Using a background NSViewRepresentable lets us hook
/// into the window lifecycle without an NSWindowController.
struct WindowToolbarSetup: NSViewRepresentable {
    let delegate: MainToolbarDelegate

    func makeNSView(context: Context) -> NSView {
        let proxy = NSView()
        DispatchQueue.main.async {
            guard let window = proxy.window else { return }
            let toolbar = NSToolbar(identifier: "KachiMainToolbar")
            toolbar.delegate = delegate
            toolbar.displayMode = .iconOnly
            toolbar.allowsUserCustomization = false
            window.toolbar = toolbar
            window.titleVisibility = .hidden   // compact unified look
        }
        return proxy
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
