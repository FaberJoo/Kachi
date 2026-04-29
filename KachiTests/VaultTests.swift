import Testing
import Foundation
@testable import Kachi

@MainActor
@Suite struct VaultTests {

    @Test func encodeDecode() throws {
        let vault = Vault(id: UUID(), name: "Work", bookmarkData: Data([1, 2, 3]))
        let data = try JSONEncoder().encode(vault)
        let decoded = try JSONDecoder().decode(Vault.self, from: data)
        #expect(decoded.id == vault.id)
        #expect(decoded.name == vault.name)
        #expect(decoded.bookmarkData == vault.bookmarkData)
    }

    @Test func defaultNameFromURL() {
        let vault = Vault(bookmarkData: Data(), resolvedURL: URL(filePath: "/Users/test/Notes"))
        #expect(vault.name == "Notes")
    }
}
