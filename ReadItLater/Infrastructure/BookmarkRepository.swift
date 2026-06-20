import Foundation
import SwiftData

/// SwiftDataを使用したBookmarkRepository実装
///
/// BookmarkRepositoryProtocolの具体的な実装。
/// ModelContextを通じてSwiftDataへのCRUD操作を提供する。
///
/// # 注意
/// BookmarkはInboxから移動したものなので、直接addすることはありません。
/// InboxRepositoryのmoveToBookmarkメソッドを使用してBookmarkを作成します。
///
/// # テスト
/// テスト時はin-memory ModelContainerのcontextを注入することで、
/// 実際のデータベースに影響を与えずにテストが可能。
struct BookmarkRepository: BookmarkRepositoryProtocol {
    private let modelContext: ModelContext

    /// イニシャライザ
    /// - Parameter modelContext: SwiftDataのModelContext
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func delete(_ bookmark: URLItem) {
        modelContext.delete(bookmark)
    }

    func delete(_ bookmarks: [URLItem]) {
        for bookmark in bookmarks {
            modelContext.delete(bookmark)
        }
    }

    // MARK: - 状態移動

    func moveToArchive(_ bookmark: URLItem) throws {
        bookmark.status = URLItemStatus.archive.rawValue
        bookmark.bookmarkedAt = nil
        bookmark.archivedAt = Date.now
        try modelContext.save()
    }

    func moveToInbox(_ bookmark: URLItem, using inboxRepository: InboxRepositoryProtocol) throws {
        // Inbox容量チェック
        guard inboxRepository.canAdd() else {
            throw InboxRepositoryError.inboxFull
        }

        bookmark.status = URLItemStatus.inbox.rawValue
        bookmark.bookmarkedAt = nil
        bookmark.archivedAt = nil
        try modelContext.save()
    }
}
