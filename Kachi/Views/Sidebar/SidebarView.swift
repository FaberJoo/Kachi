import SwiftUI

struct SidebarView: View {
    var body: some View {
        List {
            // TODO: vault 트리, 폴더/문서 목록 (MVP)
        }
        .listStyle(.sidebar)
    }
}

#Preview {
    SidebarView()
        .frame(width: 240)
}
