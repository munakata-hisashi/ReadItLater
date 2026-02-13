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
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func handleDeepLink(_ url: URL) {
        let modelContext = sharedModelContainer.mainContext
        let repository = InboxRepository(modelContext: modelContext)
        let metadataService = URLMetadataService()
        let useCase = DeepLinkUseCase(
            metadataService: metadataService,
            repository: repository
        )

        Task {
            let result = await useCase.execute(url: url)
            if case .failure(let error) = result {
                print("DeepLink処理エラー: \(error.localizedDescription)")
            }
        }
    }
}
