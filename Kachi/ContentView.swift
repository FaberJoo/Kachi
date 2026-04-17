//
//  ContentView.swift
//  Kachi
//
//  Created by FaberJoo on 4/15/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            // TODO: 에디터 영역 (MVP)
            Color.clear
        }
    }
}

#Preview {
    ContentView()
}
