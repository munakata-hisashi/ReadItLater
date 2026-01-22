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

@Suite("Repository統合テスト")
struct RepositoryIntegrationTests {

    // MARK: - Helper

    /// テスト用のin-memory ModelContainerを作成
    private func createInMemoryContainer() throws -> ModelContainer {
        try ModelContainerFactory.createSharedContainer(inMemory: true)
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
        let inbox = Inbox(url: "https://example.com", title: "Test", addedInboxAt: specificDate)
        context.insert(inbox)
        try context.save()

        // Inbox → Bookmark
        try inboxRepository.moveToBookmark(inbox)
        let bookmark = try context.fetch(FetchDescriptor<Bookmark>()).first!
        #expect(bookmark.addedInboxAt == specificDate)

        // Bookmark → Archive
        try bookmarkRepository.moveToArchive(bookmark)
        let archive = try context.fetch(FetchDescriptor<Archive>()).first!
        #expect(archive.addedInboxAt == specificDate)

        // Archive → Bookmark
        try archiveRepository.moveToBookmark(archive)
        let finalBookmark = try context.fetch(FetchDescriptor<Bookmark>()).first!
        #expect(finalBookmark.addedInboxAt == specificDate)
    }

    @Test("統合: 複数アイテムの状態移動")
    @MainActor
    func 統合_複数アイテムの状態移動() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext

        let inboxRepository = InboxRepository(modelContext: context)
        let bookmarkRepository = BookmarkRepository(modelContext: context)

        // Given: 3つのInboxアイテム
        try inboxRepository.add(url: "https://example1.com", title: "Test1")
        try inboxRepository.add(url: "https://example2.com", title: "Test2")
        try inboxRepository.add(url: "https://example3.com", title: "Test3")

        let inboxItems = try context.fetch(FetchDescriptor<Inbox>())
        #expect(inboxItems.count == 3)

        // When: 2つをBookmarkへ、1つをArchiveへ移動
        try inboxRepository.moveToBookmark(inboxItems[0])
        try inboxRepository.moveToBookmark(inboxItems[1])
        try inboxRepository.moveToArchive(inboxItems[2])

        // Then: Inboxが空、Bookmark=2、Archive=1
        #expect(try context.fetch(FetchDescriptor<Inbox>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Bookmark>()).count == 2)
        #expect(try context.fetch(FetchDescriptor<Archive>()).count == 1)
    }
}
