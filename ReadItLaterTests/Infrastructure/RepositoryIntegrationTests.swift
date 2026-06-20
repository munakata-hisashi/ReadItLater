//
//  RepositoryIntegrationTests.swift
//  ReadItLaterTests
//
//  Created by Claude Code on 2026/01/22.
//

import Testing
import SwiftData
import Foundation
@testable import ReadItLater

@Suite("Repository統合テスト", .serialized)
struct RepositoryIntegrationTests {

    // MARK: - Helper

    /// テスト用のin-memory ModelContainerを作成
    private func createInMemoryContainer() throws -> ModelContainer {
        try ModelContainerFactory.createSharedContainer(inMemory: true)
    }

    private func fetchInboxItems(from context: ModelContext) throws -> [URLItem] {
        let descriptor = FetchDescriptor<URLItem>(
            predicate: #Predicate { $0.status == "inbox" }
        )
        return try context.fetch(descriptor)
    }

    private func fetchBookmarks(from context: ModelContext) throws -> [URLItem] {
        let descriptor = FetchDescriptor<URLItem>(
            predicate: #Predicate { $0.status == "bookmark" }
        )
        return try context.fetch(descriptor)
    }

    private func fetchArchives(from context: ModelContext) throws -> [URLItem] {
        let descriptor = FetchDescriptor<URLItem>(
            predicate: #Predicate { $0.status == "archive" }
        )
        return try context.fetch(descriptor)
    }

    // MARK: - 状態移動連鎖テスト

    @Test("統合: addedInboxAtが全移動で保持される")
    @MainActor
    func 統合_addedInboxAtが全移動で保持される() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext

        let inboxRepository = InboxRepository(modelContext: context)
        let bookmarkRepository = BookmarkRepository(modelContext: context)
        let archiveRepository = ArchiveRepository(modelContext: context)

        // Given: 特定の日時でInboxに追加
        let specificDate = Date(timeIntervalSince1970: 1234567890)
        let inbox = URLItem(url: "https://example.com", title: "Test", addedInboxAt: specificDate)
        context.insert(inbox)
        try context.save()

        // Inbox → Bookmark
        try inboxRepository.moveToBookmark(inbox)
        let bookmark = try fetchBookmarks(from: context).first!
        #expect(bookmark.addedInboxAt == specificDate)

        // Bookmark → Archive
        try bookmarkRepository.moveToArchive(bookmark)
        let archive = try fetchArchives(from: context).first!
        #expect(archive.addedInboxAt == specificDate)

        // Archive → Bookmark
        try archiveRepository.moveToBookmark(archive)
        let finalBookmark = try fetchBookmarks(from: context).first!
        #expect(finalBookmark.addedInboxAt == specificDate)
    }

    @Test("統合: 複数アイテムの状態移動")
    @MainActor
    func 統合_複数アイテムの状態移動() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext

        let inboxRepository = InboxRepository(modelContext: context)

        // Given: 3つのInboxアイテム
        try inboxRepository.add(url: "https://example1.com", title: "Test1")
        try inboxRepository.add(url: "https://example2.com", title: "Test2")
        try inboxRepository.add(url: "https://example3.com", title: "Test3")

        let inboxItems = try fetchInboxItems(from: context)
        #expect(inboxItems.count == 3)

        // When: 2つをBookmarkへ、1つをArchiveへ移動
        try inboxRepository.moveToBookmark(inboxItems[0])
        try inboxRepository.moveToBookmark(inboxItems[1])
        try inboxRepository.moveToArchive(inboxItems[2])

        // Then: Inboxが空、Bookmark=2、Archive=1
        #expect(try fetchInboxItems(from: context).isEmpty)
        #expect(try fetchBookmarks(from: context).count == 2)
        #expect(try fetchArchives(from: context).count == 1)
    }

    @Test("統合: V3の3モデルからV5のURLItemへ移行される")
    @MainActor
    func 統合_V3からV5へ移行される() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let storeURL = directory.appendingPathComponent("MigrationTest.store")

        do {
            let v3Schema = Schema([
                AppV3Schema.Inbox.self,
                AppV3Schema.Bookmark.self,
                AppV3Schema.Archive.self
            ])
            let v3Configuration = ModelConfiguration(
                schema: v3Schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let v3Container = try ModelContainer(
                for: v3Schema,
                configurations: v3Configuration
            )
            let context = v3Container.mainContext
            context.insert(AppV3Schema.Inbox(url: "https://inbox.example", title: "Inbox"))
            context.insert(AppV3Schema.Bookmark(url: "https://bookmark.example", title: "Bookmark"))
            context.insert(AppV3Schema.Archive(url: "https://archive.example", title: "Archive"))
            try context.save()
        }

        let finalSchema = Schema([URLItem.self])
        let finalConfiguration = ModelConfiguration(
            schema: finalSchema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let finalContainer = try ModelContainer(
            for: finalSchema,
            migrationPlan: AppMigrationPlan.self,
            configurations: finalConfiguration
        )

        #expect(try fetchInboxItems(from: finalContainer.mainContext).count == 1)
        #expect(try fetchBookmarks(from: finalContainer.mainContext).count == 1)
        #expect(try fetchArchives(from: finalContainer.mainContext).count == 1)
    }
}
