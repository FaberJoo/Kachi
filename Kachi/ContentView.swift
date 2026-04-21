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

                // Editor area (to be implemented)
                currentTheme.backgroundPrimary
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .onAppear { configureToolbar() }
        .onChange(of: appState.sidebarPinned) { refreshToolbarButton() }
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
        refreshToolbarButton()
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
}

#Preview {
    ContentView()
        .frame(width: 900, height: 600)
}
