import SwiftUI

// MARK: - Semantic token set

struct SemanticColor {

    // MARK: Background
    let backgroundPrimary: Color    // editor / main content area
    let backgroundSecondary: Color  // sidebar / secondary surfaces

    // MARK: Text
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color         // labels, placeholders, muted text

    // MARK: Border
    let borderSubtle: Color
    let borderStrong: Color

    // MARK: Accent
    let accentPrimary: Color
    let accentHover: Color
    let accentPressed: Color

    // MARK: Status
    let statusDanger: Color
    let statusSuccess: Color
    let statusWarning: Color

    // MARK: Surface states
    let surfaceHover: Color         // list row hover
    let surfaceActive: Color        // list row selected

    // MARK: Shadow
    let shadow: Color
}

// MARK: - Environment keys

private struct VaultManagerKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue = VaultManager()
}

extension EnvironmentValues {
    @Entry var theme: SemanticColor = AppTheme.dark
    var vaultManager: VaultManager {
        get { self[VaultManagerKey.self] }
        set { self[VaultManagerKey.self] = newValue }
    }
}
