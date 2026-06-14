//
//  InboxRepositoryTests.swift
//  ReadItLaterTests
//
//  Created by Claude Code on 2026/01/22.
//

import Testing
import SwiftData
import Foundation
@testable import ReadItLater

@Suite("InboxRepository", .serialized)
struct InboxRepositoryTests {

    // MARK: - Helper

    @MainActor
    private func createInMemoryContainer() throws -> ModelContainer {
        try ModelContainerFactory.createSharedContainer(inMemory: true)
    }

    private func fetchInboxItems(from context: ModelContext) throws -> [Inbox] {
        let descriptor = FetchDescriptor<Inbox>(
            predicate: #Predicate { $0.status == "inbox" }
        )
        return try context.fetch(descriptor)
    }

    private func fetchBookmarks(from context: ModelContext) throws -> [Bookmark] {
        let descriptor = FetchDescriptor<Bookmark>(
            predicate: #Predicate { $0.status == "bookmark" }
        )
        return try context.fetch(descriptor)
    }

    private func fetchArchives(from context: ModelContext) throws -> [Archive] {
        let descriptor = FetchDescriptor<Archive>(
            predicate: #Predicate { $0.status == "archive" }
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Add Tests

    @Test("Inbox追加: 成功")
    @MainActor
    func Inbox追加_成功() throws {
        let container = try createInMemoryContainer()
        let repository = InboxRepository(modelContext: container.mainContext)

        try repository.add(url: "https://example.com", title: "Example")

        let items = try fetchInboxItems(from: container.mainContext)

        #expect(items.count == 1)
        #expect(items.first?.url == "https://example.com")
        #expect(items.first?.title == "Example")
    }

    @Test("Inbox追加: 複数追加")
    @MainActor
    func Inbox追加_複数追加() throws {
        let container = try createInMemoryContainer()
        let repository = InboxRepository(modelContext: container.mainContext)

        try repository.add(url: "https://example1.com", title: "Example 1")
        try repository.add(url: "https://example2.com", title: "Example 2")
        try repository.add(url: "https://example3.com", title: "Example 3")

        #expect(repository.count() == 3)
    }

    // MARK: - Capacity Tests

    @Test("容量確認: 追加可能")
    @MainActor
    func 容量確認_追加可能() throws {
        let container = try createInMemoryContainer()
        let repository = InboxRepository(modelContext: container.mainContext)

        #expect(repository.canAdd())
        #expect(repository.count() == 0)
        #expect(repository.remainingCapacity() == InboxConfiguration.maxItems)
    }

    @Test("容量確認: 残り1件")
    @MainActor
    func 容量確認_残り1件() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let repository = InboxRepository(modelContext: context)

        // 上限-1件を追加
        for i in 0..<(InboxConfiguration.maxItems - 1) {
            let inbox = Inbox(url: "https://example.com/\(i)", title: "Item \(i)")
            context.insert(inbox)
        }

        #expect(repository.canAdd())
        #expect(repository.remainingCapacity() == 1)
    }

    @Test("容量確認: 上限到達")
    @MainActor
    func 容量確認_上限到達() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let repository = InboxRepository(modelContext: context)

        // 上限件数を追加
        for i in 0..<InboxConfiguration.maxItems {
            let inbox = Inbox(url: "https://example.com/\(i)", title: "Item \(i)")
            context.insert(inbox)
        }

        #expect(!repository.canAdd())
        #expect(repository.remainingCapacity() == 0)
    }

    // MARK: - Error Tests

    @Test("上限エラー: 追加時に例外")
    @MainActor
    func 上限エラー_追加時に例外() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let repository = InboxRepository(modelContext: context)

        // 上限件数を追加
        for i in 0..<InboxConfiguration.maxItems {
            let inbox = Inbox(url: "https://example.com/\(i)", title: "Item \(i)")
            context.insert(inbox)
        }

        // 追加しようとするとエラー
        #expect(throws: InboxRepositoryError.inboxFull) {
            try repository.add(url: "https://example.com/new", title: "New")
        }
    }

    // MARK: - 状態移動テスト

    @Test("状態移動: InboxからBookmarkへ")
    @MainActor
    func 状態移動_InboxからBookmarkへ() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let repository = InboxRepository(modelContext: context)

        // Given: Inboxアイテム
        try repository.add(url: "https://example.com", title: "Test")
        let inbox = try fetchInboxItems(from: context).first!
        let originalAddedAt = inbox.addedInboxAt

        // When: Bookmarkへ移動
        try repository.moveToBookmark(inbox)

        // Then: Bookmarkに存在し、Inboxから削除
        let bookmarks = try fetchBookmarks(from: context)
        #expect(bookmarks.count == 1)
        #expect(bookmarks.first?.url == "https://example.com")
        #expect(bookmarks.first?.addedInboxAt == originalAddedAt)

        let remainingInbox = try fetchInboxItems(from: context)
        #expect(remainingInbox.isEmpty)
    }

    @Test("状態移動: InboxからArchiveへ")
    @MainActor
    func 状態移動_InboxからArchiveへ() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let repository = InboxRepository(modelContext: context)

        // Given: Inboxアイテム
        try repository.add(url: "https://example.com", title: "Test")
        let inbox = try fetchInboxItems(from: context).first!
        let originalAddedAt = inbox.addedInboxAt

        // When: Archiveへ移動
        try repository.moveToArchive(inbox)

        // Then: Archiveに存在し、Inboxから削除
        let archives = try fetchArchives(from: context)
        #expect(archives.count == 1)
        #expect(archives.first?.url == "https://example.com")
        #expect(archives.first?.addedInboxAt == originalAddedAt)

        let remainingInbox = try fetchInboxItems(from: context)
        #expect(remainingInbox.isEmpty)
    }

    @Test("削除: Inbox削除")
    @MainActor
    func 削除_Inbox削除() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let repository = InboxRepository(modelContext: context)

        // Given: Inboxアイテム
        try repository.add(url: "https://example.com", title: "Test")
        let inbox = try fetchInboxItems(from: context).first!

        // When: 削除
        repository.delete(inbox)
        try context.save()

        // Then: Inboxが空
        #expect(try fetchInboxItems(from: context).isEmpty)
    }
}
