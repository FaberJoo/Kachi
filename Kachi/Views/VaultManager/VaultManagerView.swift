import SwiftUI

struct VaultManagerView: View {
    @Environment(\.vaultManager) private var vaultManager

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(vaultManager.vaults) { vault in
                    VaultRow(vault: vault)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.inset)

            Divider()

            HStack {
                Button("Add Vault…") {
                    vaultManager.addVaultWithPicker()
                }
                Spacer()
            }
            .padding(12)
        }
        .frame(minWidth: 440, minHeight: 300)
    }
}

// MARK: - Vault row

private struct VaultRow: View {
    let vault: Vault
    @Environment(\.vaultManager) private var vaultManager
    @State private var editingName: String = ""
    @State private var isEditing = false

    var isDefault: Bool { vault.id == vaultManager.defaultVaultID }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "internaldrive")
                .foregroundStyle(.secondary)
                .frame(width: 16)

            if isEditing {
                TextField("Vault name", text: $editingName)
                    .textFieldStyle(.plain)
                    .onSubmit { commitRename() }
                    .onExitCommand { isEditing = false }
            } else {
                Text(vault.name)
                    .onTapGesture(count: 2) {
                        editingName = vault.name
                        isEditing = true
                    }
            }

            Spacer()

            if isDefault {
                Text("Default")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            } else {
                Button("Set as Default") {
                    vaultManager.setAsDefault(vault: vault)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(Color.accentColor)
            }

            Button(role: .destructive) {
                vaultManager.remove(vault: vault)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .onAppear { editingName = vault.name }
    }

    private func commitRename() {
        vaultManager.rename(vault: vault, to: editingName)
        isEditing = false
    }
}
