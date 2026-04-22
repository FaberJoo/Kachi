import SwiftUI

struct EmptyVaultView: View {
    @Environment(\.theme) private var theme
    @Environment(\.vaultManager) private var vaultManager

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(theme.textTertiary)
            Text("No Vault Open")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.textSecondary)
            Button("Open Folder…") {
                vaultManager.addVaultWithPicker()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(theme.accentPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
