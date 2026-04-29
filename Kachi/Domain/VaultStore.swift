import Foundation

/// Persists vault list and default vault ID in UserDefaults.
/// Uses a configurable suiteName so tests can use isolated storage.
final class VaultStore {
    private let defaults: UserDefaults
    private let vaultsKey = "vaults"
    private let defaultVaultKey = "defaultVaultID"

    init(suiteName: String = "com.kachi.vaults") {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    func save(vaults: [Vault], defaultVaultID: UUID?) {
        if let data = try? JSONEncoder().encode(vaults) {
            defaults.set(data, forKey: vaultsKey)
        }
        defaults.set(defaultVaultID?.uuidString, forKey: defaultVaultKey)
    }

    func load() -> (vaults: [Vault], defaultVaultID: UUID?) {
        guard let data = defaults.data(forKey: vaultsKey),
              let vaults = try? JSONDecoder().decode([Vault].self, from: data)
        else { return ([], nil) }

        let defaultID = defaults.string(forKey: defaultVaultKey)
            .flatMap(UUID.init(uuidString:))
        return (vaults, defaultID)
    }
}
