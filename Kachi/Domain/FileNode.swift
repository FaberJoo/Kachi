import Foundation
import Observation

@Observable
final class FileNode: Identifiable {
    let id: UUID = UUID()
    let url: URL
    let isDirectory: Bool
    var children: [FileNode]?   // nil = not yet loaded; [] = empty directory
    var isExpanded: Bool = false

    var name: String { url.lastPathComponent }

    init(url: URL, isDirectory: Bool) {
        self.url = url
        self.isDirectory = isDirectory
    }

    /// Returns nodes sorted: directories first, then files, both alphabetically.
    static func sorted(_ nodes: [FileNode]) -> [FileNode] {
        nodes.sorted {
            if $0.isDirectory != $1.isDirectory { return $0.isDirectory }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
}
