import Foundation
import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
final class VaultManager {
    private(set) var vaults: [Vault] = []
    private(set) var activeVault: Vault?
    private(set) var defaultVaultID: UUID?
    private(set) var rootNodes: [FileNode] = []
    private(set) var isLoading: Bool = false
    var selectedNode: FileNode?

    private let store = VaultStore()
    private var watcher: FileSystemWatcher?

    init() {
        let (saved, defaultID) = store.load()
        vaults = saved
        defaultVaultID = defaultID
        activeVault = saved.first { $0.id == defaultID } ?? saved.first
        if let vault = activeVault {
            Task { await self.loadTree(for: vault) }
        }
    }

    // MARK: - Vault management

    /// Opens NSOpenPanel, creates a security-scoped bookmark, and adds the vault.
    func addVaultWithPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open as Vault"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            let vault = Vault(bookmarkData: bookmark, resolvedURL: url)
            vaults.append(vault)
            if activeVault == nil {
                activeVault = vault
                defaultVaultID = vault.id
            }
            persist()
            Task { await self.loadTree(for: vault) }
        } catch {
            print("VaultManager: bookmark creation failed: \(error)")
        }
    }

    /// Switches the active vault without changing the default.
    func setActive(vault: Vault) {
        activeVault = vault
        watcher = nil
        Task { await self.loadTree(for: vault) }
    }

    /// Marks a vault as the default (opened on next launch).
    func setAsDefault(vault: Vault) {
        defaultVaultID = vault.id
        persist()
    }

    func rename(vault: Vault, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let index = vaults.firstIndex(where: { $0.id == vault.id }) else { return }
        vaults[index].name = trimmed
        if activeVault?.id == vault.id { activeVault = vaults[index] }
        persist()
    }

    func remove(vault: Vault) {
        vaults.removeAll { $0.id == vault.id }
        if defaultVaultID == vault.id { defaultVaultID = vaults.first?.id }
        if activeVault?.id == vault.id {
            activeVault = vaults.first
            rootNodes = []
            if let next = activeVault {
                Task { await self.loadTree(for: next) }
            }
        }
        persist()
    }

    // MARK: - File tree

    func expand(node: FileNode) async {
        guard node.isDirectory, node.children == nil else {
            node.isExpanded = true
            return
        }
        guard let vault = activeVault else { return }
        let vaultURL = resolveURL(vault: vault)
        _ = vaultURL.startAccessingSecurityScopedResource()
        node.children = Self.loadChildren(of: node.url)
        vaultURL.stopAccessingSecurityScopedResource()
        node.isExpanded = true
    }

    func collapse(node: FileNode) {
        node.isExpanded = false
    }

    // MARK: - Private

    private func loadTree(for vault: Vault) async {
        isLoading = true
        let url = resolveURL(vault: vault)
        _ = url.startAccessingSecurityScopedResource()
        rootNodes = Self.loadChildren(of: url)
        url.stopAccessingSecurityScopedResource()
        isLoading = false
        startWatching(url: url)
    }

    private func refreshTree() {
        guard let vault = activeVault else { return }
        let url = resolveURL(vault: vault)
        _ = url.startAccessingSecurityScopedResource()
        let fresh = Self.loadChildren(of: url)
        Self.mergeNodes(existing: &rootNodes, fresh: fresh)
        url.stopAccessingSecurityScopedResource()
    }

    private func startWatching(url: URL) {
        watcher = FileSystemWatcher(url: url) { [weak self] in
            self?.refreshTree()
        }
    }

    private func resolveURL(vault: Vault) -> URL {
        var isStale = false
        return (try? URL(
            resolvingBookmarkData: vault.bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )) ?? URL(filePath: "/")
    }

    /// Updates `existing` in place to match `fresh`, preserving expanded state and
    /// FileNode identity for nodes that still exist (so SwiftUI doesn't re-render them).
    private static func mergeNodes(existing: inout [FileNode], fresh: [FileNode]) {
        let existingByURL = Dictionary(uniqueKeysWithValues: existing.map { ($0.url, $0) })

        existing = fresh.map { freshNode in
            guard let old = existingByURL[freshNode.url] else { return freshNode }
            // Node still exists — refresh its children if it was expanded
            if old.isExpanded, old.children != nil {
                let freshChildren = loadChildren(of: old.url)
                var oldChildren = old.children ?? []
                mergeNodes(existing: &oldChildren, fresh: freshChildren)
                old.children = oldChildren
            }
            return old
        }
    }

    private static func loadChildren(of url: URL) -> [FileNode] {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        )) ?? []

        let nodes = contents.map { childURL -> FileNode in
            let isDir = (try? childURL.resourceValues(forKeys: [.isDirectoryKey]))
                .flatMap(\.isDirectory) ?? false
            return FileNode(url: childURL, isDirectory: isDir)
        }
        return FileNode.sorted(nodes)
    }

    private func persist() {
        store.save(vaults: vaults, defaultVaultID: defaultVaultID)
    }
}

// MARK: - Environment key

private struct VaultManagerKey: EnvironmentKey {
    static let defaultValue: VaultManager = MainActor.assumeIsolated { VaultManager() }
}

extension EnvironmentValues {
    var vaultManager: VaultManager {
        get { self[VaultManagerKey.self] }
        set { self[VaultManagerKey.self] = newValue }
    }
}
