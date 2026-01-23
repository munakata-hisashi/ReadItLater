import Foundation
import SwiftData

/// Bookmark永続化操作のためのプロトコル
///
/// テスト時にモック実装を注入可能にするためのプロトコル。
/// SwiftDataのModelContextを使用した実装をInfrastructure層で提供する。
protocol BookmarkRepositoryProtocol {
    // MARK: - 追加操作

    /// ブックマークを追加
    /// - Parameter bookmarkData: 作成済みのBookmarkData
    func add(_ bookmarkData: BookmarkData)

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
}
