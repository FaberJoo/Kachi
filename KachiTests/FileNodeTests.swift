import Testing
import Foundation
@testable import Kachi

@MainActor
@Suite struct FileNodeTests {

    @Test func fileNodeIsLeaf() {
        let node = FileNode(url: URL(filePath: "/tmp/note.md"), isDirectory: false)
        #expect(node.isDirectory == false)
        #expect(node.children == nil)
        #expect(node.name == "note.md")
    }

    @Test func directoryNodeStartsCollapsed() {
        let node = FileNode(url: URL(filePath: "/tmp/folder"), isDirectory: true)
        #expect(node.isDirectory == true)
        #expect(node.isExpanded == false)
        #expect(node.children == nil)
    }

    @Test func sortChildrenFoldersFirst() {
        let file = FileNode(url: URL(filePath: "/tmp/a.md"), isDirectory: false)
        let folder = FileNode(url: URL(filePath: "/tmp/b"), isDirectory: true)
        let sorted = FileNode.sorted([file, folder])
        #expect(sorted.first?.isDirectory == true)
        #expect(sorted.last?.isDirectory == false)
    }

    @Test func sortAlphabeticallyWithinSameType() {
        let a = FileNode(url: URL(filePath: "/tmp/alpha.md"), isDirectory: false)
        let b = FileNode(url: URL(filePath: "/tmp/beta.md"), isDirectory: false)
        let sorted = FileNode.sorted([b, a])
        #expect(sorted.first?.name == "alpha.md")
    }
}
