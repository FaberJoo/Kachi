import Foundation

struct EditableMarkdownBlock: Identifiable, Equatable {
    let id: UUID
    var raw: String

    init(id: UUID = UUID(), raw: String) {
        self.id = id
        self.raw = raw
    }
}

