import SwiftUI

/// Global app state. Declared with @Observable so views can observe it without extra property wrappers.
@Observable
final class AppState {

    // MARK: - Sidebar

    /// true = sidebar always visible (pinned), false = auto-hide (slides in on hover)
    var sidebarPinned: Bool = true

    /// Whether the mouse is hovering over the sidebar in auto-hide mode
    var sidebarHovered: Bool = false

    /// Whether the sidebar should currently be visible
    var isSidebarVisible: Bool {
        sidebarPinned || sidebarHovered
    }

    // MARK: - Appearance

    /// nil follows the system setting; set explicitly to force dark or light
    var colorScheme: ColorScheme? = nil
}
