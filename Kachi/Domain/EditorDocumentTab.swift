import Foundation

struct EditorDocumentTab: Identifiable, Equatable {
    let id: UUID
    var sourceURL: URL?
    var title: String
    var content: String
    var lastSavedContent: String

    init(
        id: UUID = UUID(),
        sourceURL: URL?,
        title: String,
        content: String,
        lastSavedContent: String? = nil
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.title = title
        self.content = content
        self.lastSavedContent = lastSavedContent ?? content
    }

    var isDirty: Bool {
        content != lastSavedContent
    }
}
