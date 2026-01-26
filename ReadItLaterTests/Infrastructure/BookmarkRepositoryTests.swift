import Testing
import SwiftData
import Foundation
@testable import ReadItLater

@Suite("BookmarkRepository")
struct BookmarkRepositoryTests {

    // MARK: - Helper

    /// テスト用のin-memory ModelContainerを作成
    private func createInMemoryContainer() throws -> ModelContainer {
        try ModelContainerFactory.createSharedContainer(inMemory: true)
    }

    // MARK: - Delete Single Tests
    // 注: BookmarkはInboxから移動したものなので、直接addすることはありません。
    // addのテストはInboxRepositoryTests.swiftで行います。

    @Test("ブックマーク削除: 単一削除成功")
    @MainActor
    func ブックマーク削除_単一削除成功() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let repository = BookmarkRepository(modelContext: context)

        // 準備: ブックマークを追加
        let bookmark = Bookmark(url: "https://example.com", title: "Example")
        context.insert(bookmark)

        // 削除前の確認
        var descriptor = FetchDescriptor<Bookmark>()
        var bookmarks = try context.fetch(descriptor)
        #expect(bookmarks.count == 1)

        // 実行
        repository.delete(bookmark)

        // 検証
        descriptor = FetchDescriptor<Bookmark>()
        bookmarks = try context.fetch(descriptor)
        #expect(bookmarks.isEmpty)
    }

    // MARK: - Delete Multiple Tests

    @Test("ブックマーク削除: 複数削除成功")
    @MainActor
    func ブックマーク削除_複数削除成功() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let repository = BookmarkRepository(modelContext: context)

        // 準備: 3つのブックマークを追加
        let bookmark1 = Bookmark(url: "https://example1.com", title: "Example 1")
        let bookmark2 = Bookmark(url: "https://example2.com", title: "Example 2")
        let bookmark3 = Bookmark(url: "https://example3.com", title: "Example 3")
        context.insert(bookmark1)
        context.insert(bookmark2)
        context.insert(bookmark3)

        // 削除前の確認
        var descriptor = FetchDescriptor<Bookmark>()
        var bookmarks = try context.fetch(descriptor)
        #expect(bookmarks.count == 3)

        // 実行: 2つを削除
        repository.delete([bookmark1, bookmark3])

        // 検証: bookmark2のみ残る
        descriptor = FetchDescriptor<Bookmark>()
        bookmarks = try context.fetch(descriptor)
        #expect(bookmarks.count == 1)
        #expect(bookmarks.first?.url == "https://example2.com")
    }

    @Test("ブックマーク削除: 空配列を削除")
    @MainActor
    func ブックマーク削除_空配列を削除() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let repository = BookmarkRepository(modelContext: context)

        // 準備: ブックマークを追加
        let bookmark = Bookmark(url: "https://example.com", title: "Example")
        context.insert(bookmark)

        // 実行: 空配列で削除
        repository.delete([])

        // 検証: bookmarkが残る
        let descriptor = FetchDescriptor<Bookmark>()
        let bookmarks = try context.fetch(descriptor)
        #expect(bookmarks.count == 1)
    }

    @Test("ブックマーク削除: 全件削除")
    @MainActor
    func ブックマーク削除_全件削除() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let repository = BookmarkRepository(modelContext: context)

        // 準備: 複数のブックマークを追加
        let bookmark1 = Bookmark(url: "https://example1.com", title: "Example 1")
        let bookmark2 = Bookmark(url: "https://example2.com", title: "Example 2")
        context.insert(bookmark1)
        context.insert(bookmark2)

        // 実行: 全件削除
        var descriptor = FetchDescriptor<Bookmark>()
        var allBookmarks = try context.fetch(descriptor)
        repository.delete(allBookmarks)

        // 検証: 空になる
        descriptor = FetchDescriptor<Bookmark>()
        allBookmarks = try context.fetch(descriptor)
        #expect(allBookmarks.isEmpty)
    }

    // MARK: - 状態移動テスト

    @Test("状態移動: BookmarkからArchiveへ")
    @MainActor
    func 状態移動_BookmarkからArchiveへ() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let repository = BookmarkRepository(modelContext: context)

        // Given: Bookmarkを作成
        let bookmark = Bookmark(
            url: "https://example.com",
            title: "Test",
            addedInboxAt: Date(timeIntervalSince1970: 1234567890)
        )
        context.insert(bookmark)
        try context.save()

        let originalAddedAt = bookmark.addedInboxAt

        // When: Archiveへ移動
        try repository.moveToArchive(bookmark)

        // Then: Archiveに存在
        let archives = try context.fetch(FetchDescriptor<Archive>())
        #expect(archives.count == 1)
        #expect(archives.first?.url == "https://example.com")
        #expect(archives.first?.addedInboxAt == originalAddedAt)

        // Bookmarkから削除されている
        let remainingBookmarks = try context.fetch(FetchDescriptor<Bookmark>())
        #expect(remainingBookmarks.isEmpty)
    }
}
