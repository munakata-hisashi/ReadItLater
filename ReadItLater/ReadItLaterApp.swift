//
//  ReadItLaterApp.swift
//  ReadItLater
//
//  Created by 宗像恒 on 2025/08/02.
//

import SwiftUI
import SwiftData

@main
struct ReadItLaterApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainerFactory.createSharedContainer()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
