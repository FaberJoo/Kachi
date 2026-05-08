//
//  ContentView.swift
//  Kachi
//
//  Created by FaberJoo on 4/15/26.
//

import SwiftUI

private let sidebarWidth: CGFloat = 240
/// Width of the invisible hit zone at the leading edge that triggers the auto-hide sidebar
private let hoverZoneWidth: CGFloat = 24

struct ContentView: View {

    @State private var appState = AppState()
    @State private var toolbarDelegate = MainToolbarDelegate()
    @State private var editorTabs: [EditorDocumentTab] = []
    @State private var activeEditorTabID: UUID?
    @State private var titleFocusRequestID: Int = 0
    @State private var recentDocumentURLs: [URL] = []
    @Environment(\.vaultManager) private var vaultManager
    @Environment(\.colorScheme) private var systemColorScheme

    /// Resolves the active theme: respects AppState override, falls back to system.
    private var currentTheme: SemanticColor {
        let scheme = appState.colorScheme ?? systemColorScheme
        return scheme == .dark ? AppTheme.dark : AppTheme.light
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // ── Main layout ────────────────────────────────
            HStack(spacing: 0) {
                // Sidebar is part of the layout only in pinned mode
                if appState.sidebarPinned {
                    SidebarView(appState: appState)
                        .frame(width: sidebarWidth)
                }

                if editorTabs.isEmpty {
                    emptyTabsView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(currentTheme.backgroundPrimary)
                } else if isActiveScratchTab {
                    newTabLandingView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(currentTheme.backgroundPrimary)
                } else {
                    EditorWorkspaceView(
                        activeTitle: activeEditorTitle,
                        onCommitTitle: renameActiveDocumentTitle,
                        onChangeContent: updateActiveTabContent,
                        content: activeEditorContent,
                        titleFocusRequestID: titleFocusRequestID,
                        titleWarningMessage: validateActiveDocumentTitle
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            // ── Auto-hide overlay ──────────────────────────
            if !appState.sidebarPinned {
                autoHideOverlay
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .preferredColorScheme(appState.colorScheme)
        // Install the AppKit toolbar via a zero-size background view.
        // SwiftUI's ToolbarItem forces a capsule/glass background on macOS 14+
        // which cannot be removed; bypassing it with NSToolbar + NSToolbarItem.isBordered = false
        // is the only reliable fix.
        .background(WindowToolbarSetup(delegate: toolbarDelegate))
        .environment(appState)
        .environment(\.theme, currentTheme)
        .onAppear {
            configureToolbar()
            toolbarDelegate.updateTabs(
                editorTabs,
                activeTabID: activeEditorTabID,
                editorBackgroundColor: NSColor(currentTheme.backgroundPrimary)
            )
        }
        .onChange(of: appState.sidebarPinned) { refreshToolbarButton() }
        .onChange(of: vaultManager.selectedNode?.id) { _, _ in
            openSelectedMarkdownFileIfNeeded()
        }
        .onChange(of: editorTabs) { _, newTabs in
            if !newTabs.isEmpty,
               activeEditorTabID == nil || !newTabs.contains(where: { $0.id == activeEditorTabID }) {
                activeEditorTabID = newTabs[0].id
            }
            toolbarDelegate.updateTabs(
                newTabs,
                activeTabID: activeEditorTabID,
                editorBackgroundColor: NSColor(currentTheme.backgroundPrimary)
            )
        }
        .onChange(of: activeEditorTabID) { _, newActiveID in
            toolbarDelegate.updateTabs(
                editorTabs,
                activeTabID: newActiveID,
                editorBackgroundColor: NSColor(currentTheme.backgroundPrimary)
            )
        }
        .onChange(of: vaultManager.deleteEventID) { _, _ in
            handleDeletedNodeEvent()
        }
    }

    // MARK: - Toolbar setup

    private func configureToolbar() {
        toolbarDelegate.onToggleSidebar = {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.sidebarPinned.toggle()
                if appState.sidebarPinned {
                    appState.sidebarHovered = false
                }
            }
        }
        toolbarDelegate.onSelectTab = { tabID in
            activeEditorTabID = tabID
        }
        toolbarDelegate.onCloseTab = { tabID in
            closeTab(tabID)
        }
        toolbarDelegate.onAddTab = {
            addScratchTab()
        }
        refreshToolbarButton()
        toolbarDelegate.updateTabs(
            editorTabs,
            activeTabID: activeEditorTabID,
            editorBackgroundColor: NSColor(currentTheme.backgroundPrimary)
        )
    }

    private func refreshToolbarButton() {
        let tintColor = appState.sidebarPinned
            ? NSColor(currentTheme.accentPrimary)
            : NSColor(currentTheme.textSecondary)
        toolbarDelegate.update(
            isPinned: appState.sidebarPinned,
            tintColor: tintColor,
            hoverColor: NSColor(currentTheme.surfaceHover)
        )
    }

    // MARK: - Editor actions

    private func addScratchTab() {
        let tab = EditorDocumentTab(
            sourceURL: nil,
            title: "New Tab",
            content: ""
        )
        editorTabs.append(tab)
        activeEditorTabID = tab.id
    }

    private func closeTab(_ tabID: UUID) {
        guard let closingIndex = editorTabs.firstIndex(where: { $0.id == tabID }) else { return }
        editorTabs.remove(at: closingIndex)
        if editorTabs.isEmpty {
            activeEditorTabID = nil
            return
        }

        if activeEditorTabID == tabID {
            let nextIndex = min(closingIndex, editorTabs.count - 1)
            activeEditorTabID = editorTabs[nextIndex].id
        }
    }

    private func updateActiveTabContent(_ newValue: String) {
        guard let index = activeTabIndex else { return }
        editorTabs[index].content = newValue

        guard let sourceURL = editorTabs[index].sourceURL else { return }
        let didSave = vaultManager.writeMarkdown(at: sourceURL, content: newValue)
        if didSave {
            editorTabs[index].lastSavedContent = newValue
        }
    }

    private var activeTabIndex: Int? {
        guard let activeEditorTabID else { return nil }
        return editorTabs.firstIndex(where: { $0.id == activeEditorTabID })
    }

    private var activeEditorContent: String {
        guard let index = activeTabIndex else { return "" }
        return editorTabs[index].content
    }

    private var activeEditorTitle: String {
        guard let index = activeTabIndex else { return "Untitled" }
        return displayTitle(for: editorTabs[index])
    }

    private func openSelectedMarkdownFileIfNeeded() {
        guard let node = vaultManager.selectedNode else { return }
        openDocumentInActiveTab(documentURL: node.url)
    }

    private func renameActiveDocumentTitle(_ newTitle: String) {
        guard let index = activeTabIndex else { return }
        let sanitizedStem = sanitizeDocumentTitle(newTitle)

        guard let sourceURL = editorTabs[index].sourceURL else {
            editorTabs[index].title = sanitizedStem
            return
        }

        let ext = sourceURL.pathExtension
        let nextFileName: String
        if ext.isEmpty {
            nextFileName = sanitizedStem
        } else {
            nextFileName = "\(sanitizedStem).\(ext)"
        }

        if let newURL = vaultManager.renameFile(at: sourceURL, to: nextFileName) {
            editorTabs[index].sourceURL = newURL
            editorTabs[index].title = newURL.deletingPathExtension().lastPathComponent
            return
        }

        editorTabs[index].title = sanitizedStem
    }

    private func sanitizeDocumentTitle(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let cleaned = trimmed.components(separatedBy: invalid).joined(separator: " ")
        let collapsed = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return collapsed.isEmpty ? "Untitled" : collapsed
    }

    private func validateActiveDocumentTitle(_ newTitle: String) -> String? {
        guard let index = activeTabIndex else { return nil }
        guard let sourceURL = editorTabs[index].sourceURL else { return nil }

        let sanitizedStem = sanitizeDocumentTitle(newTitle)
        let ext = sourceURL.pathExtension
        let candidateFileName = ext.isEmpty ? sanitizedStem : "\(sanitizedStem).\(ext)"

        if vaultManager.hasSiblingFileConflict(at: sourceURL, withFileName: candidateFileName) {
            return "A document with this name already exists in this folder."
        }
        return nil
    }

    private func displayTitle(for tab: EditorDocumentTab) -> String {
        if let sourceURL = tab.sourceURL {
            return sourceURL.deletingPathExtension().lastPathComponent
        }
        return tab.title
    }

    private func findNode(url: URL, in nodes: [FileNode]) -> FileNode? {
        for node in nodes {
            if node.url == url {
                return node
            }
            if let children = node.children, let found = findNode(url: url, in: children) {
                return found
            }
        }
        return nil
    }

    // MARK: - Auto-hide overlay
    //
    // Flicker-free strategy:
    //   - Separate the trigger zone (24 px) from the sidebar's own hover detection
    //   - Trigger zone: opens the sidebar only (handles onHover true)
    //   - Sidebar: closes itself when the mouse leaves its bounds (handles onHover false)
    //   - This way, a momentary layout reflow while the sidebar is sliding in
    //     cannot fire a spurious close event on the trigger zone

    @ViewBuilder
    private var autoHideOverlay: some View {
        ZStack(alignment: .leading) {
            // Trigger zone: exists only while sidebar is closed, open-only
            if !appState.sidebarHovered {
                Color.clear
                    .frame(width: hoverZoneWidth)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        if hovering {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.sidebarHovered = true
                            }
                        }
                    }
            }

            // Sidebar: handles its own close via onHover when open
            if appState.sidebarHovered {
                SidebarView(appState: appState)
                    .frame(width: sidebarWidth)
                    .frame(maxHeight: .infinity)
                    .shadow(color: currentTheme.shadow, radius: 16, x: 4)
                    .onHover { hovering in
                        if !hovering {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.sidebarHovered = false
                            }
                        }
                    }
                    .transition(.move(edge: .leading))
            }
        }
    }

    private func handleDeletedNodeEvent() {
        guard let deletedURL = vaultManager.deletedNodeURL else { return }
        let wasDirectory = vaultManager.deletedNodeWasDirectory
        let pathPrefix = deletedURL.path + "/"

        if wasDirectory {
            recentDocumentURLs.removeAll {
                $0.path == deletedURL.path || $0.path.hasPrefix(pathPrefix)
            }
        } else {
            recentDocumentURLs.removeAll { $0 == deletedURL }
        }

        let removedTabIDs: Set<UUID> = Set(
            editorTabs.compactMap { tab -> UUID? in
                guard let url = tab.sourceURL else { return nil }
                if wasDirectory {
                    let path = url.path
                    return (path == deletedURL.path || path.hasPrefix(pathPrefix)) ? tab.id : nil
                }
                return url == deletedURL ? tab.id : nil
            }
        )

        guard !removedTabIDs.isEmpty else { return }
        let previousActiveTabID = activeEditorTabID
        editorTabs.removeAll { removedTabIDs.contains($0.id) }

        guard let previousActiveTabID, removedTabIDs.contains(previousActiveTabID) else {
            if editorTabs.isEmpty {
                activeEditorTabID = nil
            }
            return
        }

        activeEditorTabID = editorTabs.last?.id
    }

    private var emptyTabsView: some View {
        VStack {
            Spacer()
            Text("There are currently no open tabs.")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(currentTheme.textSecondary)
            Spacer()
        }
    }

    private var newTabLandingView: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Button("Create new document") {
                            vaultManager.createDocument()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(currentTheme.textPrimary)

                        Button("Go to file") {
                            openDocumentFromPicker()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(currentTheme.textPrimary)

                        Button("Close") {
                            closeActiveTab()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(currentTheme.textPrimary)
                    }

                    Divider()
                        .overlay(currentTheme.borderSubtle)

                    Text("Recently Opend Document")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(currentTheme.textSecondary)

                    if !recentOpenedDocumentURLs.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recentOpenedDocumentURLs, id: \.self) { documentURL in
                                Button(displayName(for: documentURL)) {
                                    openDocumentInActiveTab(documentURL: documentURL)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(currentTheme.textSecondary)
                    }
                }
                .frame(maxWidth: 520, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 42)
        .padding(.top, 56)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var isActiveScratchTab: Bool {
        guard let index = activeTabIndex else { return false }
        return editorTabs[index].sourceURL == nil
    }

    private var recentOpenedDocumentURLs: [URL] {
        recentDocumentURLs.filter { url in
            url.pathExtension.lowercased() == "md" &&
            FileManager.default.fileExists(atPath: url.path)
        }
    }

    private func openDocumentFromPicker() {
        if let selectedURL = vaultManager.pickMarkdownDocumentURLInActiveVault() {
            openDocumentInActiveTab(documentURL: selectedURL)
        }
    }

    private func closeActiveTab() {
        guard let activeEditorTabID else { return }
        closeTab(activeEditorTabID)
    }

    private func openDocumentInActiveTab(documentURL: URL) {
        guard documentURL.pathExtension.lowercased() == "md" else { return }

        if let existing = editorTabs.firstIndex(where: { $0.sourceURL == documentURL }) {
            activeEditorTabID = editorTabs[existing].id
            recordRecentDocument(url: documentURL)
            return
        }

        let content = vaultManager.readMarkdown(at: documentURL) ?? ""
        let opened = EditorDocumentTab(
            sourceURL: documentURL,
            title: documentURL.deletingPathExtension().lastPathComponent,
            content: content
        )

        if let activeIndex = activeTabIndex {
            editorTabs[activeIndex].sourceURL = opened.sourceURL
            editorTabs[activeIndex].title = opened.title
            editorTabs[activeIndex].content = opened.content
            editorTabs[activeIndex].lastSavedContent = opened.lastSavedContent
        } else {
            editorTabs.append(opened)
            activeEditorTabID = opened.id
        }

        recordRecentDocument(url: documentURL)

        if vaultManager.consumeTitleFocusRequest(for: documentURL) {
            titleFocusRequestID += 1
        }
    }

    private func recordRecentDocument(url: URL) {
        recentDocumentURLs.removeAll { $0 == url }
        recentDocumentURLs.insert(url, at: 0)
        if recentDocumentURLs.count > 5 {
            recentDocumentURLs = Array(recentDocumentURLs.prefix(5))
        }
    }

    private func displayName(for url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 600)
}
