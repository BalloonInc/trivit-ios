//
//  TrivitWatchApp.swift
//  Trivit Watch App
//
//  Created by Claude on 28/01/26.
//

import SwiftUI
import SwiftData

@main
struct TrivitWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Trivit.self])
    }
}
