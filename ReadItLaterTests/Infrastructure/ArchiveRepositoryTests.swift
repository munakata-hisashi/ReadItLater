//
//  ArchiveRepositoryTests.swift
//  ReadItLaterTests
//
//  Created by Claude Code on 2026/01/22.
//

import Testing
import SwiftData
import Foundation
@testable import ReadItLater

@Suite("ArchiveRepository")
struct ArchiveRepositoryTests {

    // MARK: - Helper

    /// テスト用のin-memory ModelContainerを作成
    private func createInMemoryContainer() throws -> ModelContainer {
        try ModelContainerFactory.createSharedContainer(inMemory: true)
    }

    // MARK: - 状態移動テスト

    @Test("状態移動: ArchiveからBookmarkへ")
    @MainActor
    func 状態移動_ArchiveからBookmarkへ() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let repository = ArchiveRepository(modelContext: context)

        // Given: Archiveを作成
        let archive = Archive(
            url: "https://example.com",
            title: "Test",
            addedInboxAt: Date(timeIntervalSince1970: 1234567890)
        )
        context.insert(archive)
        try context.save()

        let originalAddedAt = archive.addedInboxAt

        // When: Bookmarkへ移動
        try repository.moveToBookmark(archive)

        // Then: Bookmarkに存在
        let bookmarks = try context.fetch(FetchDescriptor<Bookmark>())
        #expect(bookmarks.count == 1)
        #expect(bookmarks.first?.url == "https://example.com")
        #expect(bookmarks.first?.addedInboxAt == originalAddedAt)

        // Archiveから削除されている
        let remainingArchives = try context.fetch(FetchDescriptor<Archive>())
        #expect(remainingArchives.isEmpty)
    }

    @Test("状態移動: ArchiveからInboxへ")
    @MainActor
    func 状態移動_ArchiveからInboxへ() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let archiveRepository = ArchiveRepository(modelContext: context)
        let inboxRepository = InboxRepository(modelContext: context)

        // Given: Archiveを作成
        let archive = Archive(
            url: "https://example.com",
            title: "Test Archive",
            addedInboxAt: Date(timeIntervalSince1970: 1234567890)
        )
        context.insert(archive)
        try context.save()

        let originalAddedAt = archive.addedInboxAt

        // When: Inboxへ移動
        try archiveRepository.moveToInbox(archive, using: inboxRepository)

        // Then: Inboxに存在
        let inboxItems = try context.fetch(FetchDescriptor<Inbox>())
        #expect(inboxItems.count == 1)
        #expect(inboxItems.first?.url == "https://example.com")
        #expect(inboxItems.first?.title == "Test Archive")
        #expect(inboxItems.first?.addedInboxAt == originalAddedAt)

        // Archiveから削除されている
        let remainingArchives = try context.fetch(FetchDescriptor<Archive>())
        #expect(remainingArchives.isEmpty)
    }

    @Test("状態移動: Inbox満杯時にArchiveからInboxへ移動できない")
    @MainActor
    func 状態移動_Inbox満杯時にArchiveからInboxへ移動できない() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let archiveRepository = ArchiveRepository(modelContext: context)
        let inboxRepository = InboxRepository(modelContext: context)

        // Given: Inboxを満杯にする
        for i in 0..<InboxConfiguration.maxItems {
            let inbox = Inbox(url: "https://example\(i).com", title: "Item \(i)")
            context.insert(inbox)
        }
        try context.save()

        // Archiveを作成
        let archive = Archive(
            url: "https://test.com",
            title: "Test Archive"
        )
        context.insert(archive)
        try context.save()

        // When & Then: 容量エラーがスローされる
        #expect(throws: InboxRepositoryError.inboxFull) {
            try archiveRepository.moveToInbox(archive, using: inboxRepository)
        }

        // Archiveは削除されていない
        let remainingArchives = try context.fetch(FetchDescriptor<Archive>())
        #expect(remainingArchives.count == 1)

        // Inboxは増えていない
        let inboxItems = try context.fetch(FetchDescriptor<Inbox>())
        #expect(inboxItems.count == InboxConfiguration.maxItems)
    }

    // MARK: - 削除テスト

    @Test("削除: Archive削除")
    @MainActor
    func 削除_Archive削除() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let repository = ArchiveRepository(modelContext: context)

        // Given: Archiveを作成
        let archive = Archive(url: "https://example.com", title: "Test")
        context.insert(archive)
        try context.save()

        // When: 削除
        repository.delete(archive)
        try context.save()

        // Then: Archiveが空
        #expect(try context.fetch(FetchDescriptor<Archive>()).isEmpty)
    }
}
