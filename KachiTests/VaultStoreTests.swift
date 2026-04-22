import Testing
import Foundation
@testable import Kachi

@MainActor
@Suite struct VaultStoreTests {

    @Test func saveAndLoad() throws {
        let store = VaultStore(suiteName: "test.\(UUID())")
        let vault = Vault(id: UUID(), name: "Test", bookmarkData: Data([9, 8, 7]))
        store.save(vaults: [vault], defaultVaultID: vault.id)

        let (loaded, defaultID) = store.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].id == vault.id)
        #expect(defaultID == vault.id)
    }

    @Test func loadEmptyReturnsDefaults() {
        let store = VaultStore(suiteName: "test.\(UUID())")
        let (vaults, defaultID) = store.load()
        #expect(vaults.isEmpty)
        #expect(defaultID == nil)
    }

    @Test func removeVaultPersists() {
        let store = VaultStore(suiteName: "test.\(UUID())")
        let v1 = Vault(id: UUID(), name: "A", bookmarkData: Data([1]))
        let v2 = Vault(id: UUID(), name: "B", bookmarkData: Data([2]))
        store.save(vaults: [v1, v2], defaultVaultID: v1.id)
        store.save(vaults: [v2], defaultVaultID: v2.id)

        let (loaded, defaultID) = store.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].id == v2.id)
        #expect(defaultID == v2.id)
    }
}
