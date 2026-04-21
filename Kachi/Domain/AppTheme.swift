import SwiftUI

/// Color tokens ported from the HTML prototype.
/// Returns the appropriate value based on AppState.colorScheme.
struct AppTheme {
    let colorScheme: ColorScheme

    // MARK: - Background

    var bg: Color {
        colorScheme == .dark ? Color(hex: "#1a1b1e") : Color(hex: "#ffffff")
    }
    var sidebarBg: Color {
        colorScheme == .dark ? Color(hex: "#16171a") : Color(hex: "#f7f8fa")
    }
    var headerBg: Color { sidebarBg }

    // MARK: - Text

    var textPrimary: Color {
        colorScheme == .dark ? Color(hex: "#e8e9ec") : Color(hex: "#1a1b1e")
    }
    var textSecondary: Color {
        colorScheme == .dark ? Color(hex: "#8b8d97") : Color(hex: "#6b6f7a")
    }
    var textMuted: Color {
        colorScheme == .dark ? Color(hex: "#5a5c66") : Color(hex: "#a0a4b0")
    }

    // MARK: - Border

    var border: Color {
        colorScheme == .dark ? Color(hex: "#333439") : Color(hex: "#d8dae0")
    }
    var borderLight: Color {
        colorScheme == .dark ? Color(hex: "#2a2b2f") : Color(hex: "#e8eaef")
    }

    // MARK: - Accent

    var accent: Color {
        colorScheme == .dark ? Color(hex: "#4C9EEB") : Color(hex: "#2b7de9")
    }

    // MARK: - Sidebar item states

    var sidebarItemHover: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04)
    }
    var sidebarItemActive: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }

    // MARK: - Shadow (used by auto-hide overlay)

    var shadow: Color {
        colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.15)
    }
}

// MARK: - Color hex initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8)  & 0xFF) / 255
            b = Double(int         & 0xFF) / 255
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}
