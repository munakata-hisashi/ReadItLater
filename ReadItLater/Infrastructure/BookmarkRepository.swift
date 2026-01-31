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

    func delete(_ bookmark: Bookmark) {
        modelContext.delete(bookmark)
    }

    func delete(_ bookmarks: [Bookmark]) {
        for bookmark in bookmarks {
            modelContext.delete(bookmark)
        }
    }

    // MARK: - 状態移動

    func moveToArchive(_ bookmark: Bookmark) throws {
        let archive = Archive(
            url: bookmark.url ?? "",
            title: bookmark.title ?? "",
            addedInboxAt: bookmark.addedInboxAt,  // 元の追加日時を引き継ぐ
            archivedAt: Date.now  // Archiveに移動した日時
        )

        modelContext.insert(archive)
        modelContext.delete(bookmark)
        try modelContext.save()
    }

    func moveToInbox(_ bookmark: Bookmark, using inboxRepository: InboxRepositoryProtocol) throws {
        // Inbox容量チェック
        guard inboxRepository.canAdd() else {
            throw InboxRepositoryError.inboxFull
        }

        // Inboxを作成（元の追加日時を引き継ぐ）
        let inbox = Inbox(
            url: bookmark.url ?? "",
            title: bookmark.title ?? "",
            addedInboxAt: bookmark.addedInboxAt  // 元の追加日時を維持
        )

        modelContext.insert(inbox)
        modelContext.delete(bookmark)
        try modelContext.save()
    }
}
