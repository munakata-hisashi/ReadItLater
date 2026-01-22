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
