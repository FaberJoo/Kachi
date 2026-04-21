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

    private var theme: AppTheme { AppTheme(colorScheme: appState.colorScheme) }

    var body: some View {
        ZStack(alignment: .leading) {
            // ── Main layout ────────────────────────────────
            HStack(spacing: 0) {
                // Sidebar is part of the layout only in pinned mode
                if appState.sidebarPinned {
                    SidebarView(appState: appState, theme: theme)
                        .frame(width: sidebarWidth)
                }

                // Editor area (to be implemented)
                Color(theme.bg)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // ── Auto-hide overlay ──────────────────────────
            if !appState.sidebarPinned {
                autoHideOverlay
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(theme.bg)
        .preferredColorScheme(appState.colorScheme)
        .toolbar {
            // Sidebar toggle button — placed to the right of the traffic lights
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.sidebarPinned.toggle()
                        // Reset hover state when switching back to pinned mode
                        if appState.sidebarPinned {
                            appState.sidebarHovered = false
                        }
                    }
                } label: {
                    Image(systemName: "sidebar.left")
                        .foregroundStyle(appState.sidebarPinned ? theme.accent : theme.textSecondary)
                }
                .help(appState.sidebarPinned ? "Switch to auto-hide" : "Pin sidebar")
            }
        }
        .environment(appState)
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
                SidebarView(appState: appState, theme: theme)
                    .frame(width: sidebarWidth)
                    .frame(maxHeight: .infinity)
                    .shadow(color: theme.shadow, radius: 16, x: 4)
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
