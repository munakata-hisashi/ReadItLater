import Foundation

/// Bookmark永続化操作のためのプロトコル
///
/// テスト時にモック実装を注入可能にするためのプロトコル。
/// SwiftDataのModelContextを使用した実装をInfrastructure層で提供する。
///
/// 注: BookmarkはInboxから移動したものなので、直接addメソッドで追加することはありません。
/// 追加はInboxRepositoryを使用し、その後moveToBookmarkで移動します。
protocol BookmarkRepositoryProtocol {
    // MARK: - 削除操作

    /// ブックマークを削除
    /// - Parameter bookmark: 削除対象のBookmark
    func delete(_ bookmark: Bookmark)

    /// 複数のブックマークを削除
    /// - Parameter bookmarks: 削除対象のBookmark配列
    func delete(_ bookmarks: [Bookmark])

    // MARK: - 状態移動

    /// BookmarkからArchiveへ移動
    /// - Parameter bookmark: 移動元のBookmark
    /// - Throws: SwiftDataのエラー
    func moveToArchive(_ bookmark: Bookmark) throws

    /// BookmarkからInboxへ移動
    /// - Parameters:
    ///   - bookmark: 移動元のBookmark
    ///   - inboxRepository: Inbox容量チェックと追加に使用するリポジトリ
    /// - Throws: InboxError（容量超過時）、SwiftDataのエラー
    func moveToInbox(_ bookmark: Bookmark, using inboxRepository: InboxRepositoryProtocol) throws
}
