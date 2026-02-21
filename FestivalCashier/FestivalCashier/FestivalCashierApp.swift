//
//  FestivalCashierApp.swift
//  FestivalCashier
//
//  Created by 村上マキシ on 2025/03/04.
//

import SwiftUI
import FirebaseCore

@main
struct FestivalCashierApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
