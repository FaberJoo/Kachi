import SwiftUI

struct SidebarView: View {

    var appState: AppState
    @Environment(\.theme) private var theme
    @Environment(\.vaultManager) private var vaultManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            topToolbar
            Divider()
            fileTree
            Divider()
            bottomToolbar
        }
        .background(theme.backgroundSecondary)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Top toolbar

    private var topToolbar: some View {
        HStack(spacing: 2) {
            SidebarToolButton(icon: "magnifyingglass", help: "Search")
            SidebarToolButton(icon: "doc.badge.plus", help: "New Document") {
                vaultManager.createDocument()
            }
            SidebarToolButton(icon: "folder.badge.plus", help: "New Folder") {
                vaultManager.createFolder()
            }
            Spacer()
            SidebarToolButton(icon: "line.3.horizontal.decrease", help: "Sort")
        }
        .padding(.horizontal, 8)
        .frame(height: 36)
    }

    // MARK: - File tree

    private var fileTree: some View {
        Group {
            if vaultManager.activeVault == nil {
                EmptyVaultView()
            } else if vaultManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vaultManager.rootNodes.isEmpty {
                Text("No files")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.textTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        FileTreeView(nodes: vaultManager.rootNodes)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ReturnKeyMonitor {
            vaultManager.beginRenameSelected()
        })
    }

    // MARK: - Bottom toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 2) {
            vaultSwitcher
            Spacer()
            SidebarToolButton(icon: "questionmark.circle", help: "Help")
            SidebarToolButton(icon: "gearshape", help: "Settings")
        }
        .padding(.horizontal, 8)
        .frame(height: 34)
    }

    private var vaultSwitcher: some View {
        Menu {
            ForEach(vaultManager.vaults.sorted { $0.name < $1.name }) { vault in
                let isActive  = vault.id == vaultManager.activeVault?.id
                let isDefault = vault.id == vaultManager.defaultVaultID
                let title = isDefault ? "\(vault.name)  —  Default" : vault.name
                Button {
                    vaultManager.setActive(vault: vault)
                } label: {
                    // checkmark = currently active  |  "— Default" = opens on next launch
                    if isActive {
                        Label(title, systemImage: "checkmark")
                    } else {
                        Text(title)
                    }
                }
            }
            if !vaultManager.vaults.isEmpty { Divider() }
            Button("Manage Vaults…") {
                openWindow(id: "vault-manager")
            }
        } label: {
            HStack(spacing: 4) {
                Text(vaultManager.activeVault?.name ?? "No Vault")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(theme.textTertiary)
            }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}

// MARK: - Sub-components

/// Listens for the Return key at the window level and fires `action` when no text field is active.
private struct ReturnKeyMonitor: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = MonitorView()
        view.action = action
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? MonitorView)?.action = action
    }

    private class MonitorView: NSView {
        var action: (() -> Void)?
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window != nil {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    // keyCode 36 = Return; skip if a text field is first responder
                    guard event.keyCode == 36,
                          !(NSApp.keyWindow?.firstResponder is NSTextView) else {
                        return event
                    }
                    self?.action?()
                    return nil
                }
            } else {
                if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
            }
        }
    }
}

private struct SidebarToolButton: View {
    let icon: String
    let help: String
    var action: (() -> Void)? = nil
    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        Button {
            action?()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(isHovered ? theme.textPrimary : theme.textSecondary)
                .frame(width: 28, height: 28)
                .background(isHovered ? theme.surfaceHover : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    let state = AppState()
    SidebarView(appState: state)
        .frame(width: 240, height: 600)
        .environment(\.theme, AppTheme.dark)
        .environment(\.vaultManager, VaultManager())
}
