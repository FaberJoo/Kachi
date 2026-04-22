import Foundation

struct Vault: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var bookmarkData: Data

    init(id: UUID = UUID(), name: String, bookmarkData: Data) {
        self.id = id
        self.name = name
        self.bookmarkData = bookmarkData
    }

    /// Derives name from the folder name of the resolved URL.
    init(bookmarkData: Data, resolvedURL: URL) {
        self.id = UUID()
        self.name = resolvedURL.lastPathComponent
        self.bookmarkData = bookmarkData
    }
}
