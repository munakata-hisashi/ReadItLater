import Foundation
import SwiftData

/// SwiftDataを使用したBookmarkRepository実装
///
/// BookmarkRepositoryProtocolの具体的な実装。
/// ModelContextを通じてSwiftDataへのCRUD操作を提供する。
///
/// # 使用方法
/// ```swift
/// let repository = BookmarkRepository(modelContext: modelContext)
/// repository.add(bookmarkData)
/// ```
///
/// # テスト
/// テスト時はin-memory ModelContainerのcontextを注入することで、
/// 実際のデータベースに影響を与えずにテストが可能。
final class BookmarkRepository: BookmarkRepositoryProtocol {
    private let modelContext: ModelContext

    /// イニシャライザ
    /// - Parameter modelContext: SwiftDataのModelContext
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func add(_ bookmarkData: BookmarkData) {
        let newBookmark = Bookmark(
            url: bookmarkData.url,
            title: bookmarkData.title,
            addedInboxAt: Date.now
        )
        modelContext.insert(newBookmark)
    }

    func delete(_ bookmark: Bookmark) {
        modelContext.delete(bookmark)
    }

    func delete(_ bookmarks: [Bookmark]) {
        for bookmark in bookmarks {
            modelContext.delete(bookmark)
        }
    }
}
