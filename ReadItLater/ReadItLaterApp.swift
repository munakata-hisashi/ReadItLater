//
//  ReadItLaterApp.swift
//  ReadItLater
//
//  Created by 宗像恒 on 2025/08/02.
//

import SwiftUI
import SwiftData
import CoreData

@main
struct ReadItLaterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            #if DEBUG
//            try autoreleasepool {
//                let desc = NSPersistentStoreDescription(url: modelConfiguration.url)
//                let opts = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.munakata-hisashi.ReadItLater")
//                desc.cloudKitContainerOptions = opts
//                // Load the store synchronously so it completes before initializing the
//                // CloudKit schema.
//                desc.shouldAddStoreAsynchronously = false
//                if let mom = NSManagedObjectModel.makeManagedObjectModel(for: [Item.self]) {
//                    let container = NSPersistentCloudKitContainer(name: "Items", managedObjectModel: mom)
//                    container.persistentStoreDescriptions = [desc]
//                    container.loadPersistentStores {_, err in
//                        if let err {
//                            fatalError(err.localizedDescription)
//                        }
//                    }
//                    // Initialize the CloudKit schema after the store finishes loading.
//                    try container.initializeCloudKitSchema()
//                    // Remove and unload the store from the persistent container.
//                    if let store = container.persistentStoreCoordinator.persistentStores.first {
//                        try container.persistentStoreCoordinator.remove(store)
//                    }
//                }
//            }
#endif
            return try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: modelConfiguration)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
