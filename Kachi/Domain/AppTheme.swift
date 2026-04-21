import SwiftUI

enum AppTheme {

    static let light = SemanticColor(
        backgroundPrimary:   PaletteColor.Gray.c00,
        backgroundSecondary: PaletteColor.Gray.c05,
        textPrimary:         PaletteColor.Gray.c95,
        textSecondary:       PaletteColor.Gray.c60,
        textTertiary:        PaletteColor.Gray.c40,
        borderSubtle:        PaletteColor.Gray.c10,
        borderStrong:        PaletteColor.Gray.c20,
        accentPrimary:       PaletteColor.Blue.c50,
        accentHover:         PaletteColor.Blue.c60,
        accentPressed:       PaletteColor.Blue.c70,
        statusDanger:        PaletteColor.Red.c50,
        statusSuccess:       PaletteColor.Green.c50,
        statusWarning:       PaletteColor.Orange.c50,
        surfaceHover:        PaletteColor.Gray.c10,
        surfaceActive:       PaletteColor.Gray.c20,
        shadow:              PaletteColor.Gray.c90.opacity(0.2)
    )

    static let dark = SemanticColor(
        backgroundPrimary:   PaletteColor.Gray.c95,
        backgroundSecondary: PaletteColor.Gray.c90,
        textPrimary:         PaletteColor.Gray.c05,
        textSecondary:       PaletteColor.Gray.c30,
        textTertiary:        PaletteColor.Gray.c50,
        borderSubtle:        PaletteColor.Gray.c80,
        borderStrong:        PaletteColor.Gray.c70,
        accentPrimary:       PaletteColor.Blue.c40,
        accentHover:         PaletteColor.Blue.c50,
        accentPressed:       PaletteColor.Blue.c60,
        statusDanger:        PaletteColor.Red.c40,
        statusSuccess:       PaletteColor.Green.c40,
        statusWarning:       PaletteColor.Orange.c40,
        surfaceHover:        PaletteColor.Gray.c80,
        surfaceActive:       PaletteColor.Gray.c80,
        shadow:              PaletteColor.Gray.c100.opacity(0.4)
    )
}
