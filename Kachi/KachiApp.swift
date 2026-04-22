//
//  KachiApp.swift
//  Kachi
//
//  Created by FaberJoo on 4/15/26.
//

import SwiftUI

@main
struct KachiApp: App {
    @State private var vaultManager = VaultManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.vaultManager, vaultManager)
        }

        Window("Vault Manager", id: "vault-manager") {
            VaultManagerView()
                .environment(\.vaultManager, vaultManager)
        }
        .windowResizability(.contentMinSize)
    }
}
