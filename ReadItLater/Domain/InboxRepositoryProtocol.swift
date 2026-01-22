//
//  InboxRepositoryProtocol.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/22.
//

import Foundation

/// Inbox永続化操作のためのプロトコル
///
/// テスト時にモック実装を注入可能にするためのプロトコル。
/// SwiftDataのModelContextを使用した実装をInfrastructure層で提供する。
protocol InboxRepositoryProtocol {
    // MARK: - 追加操作

    /// Inboxにアイテムを追加
    /// - Parameters:
    ///   - url: 追加するURL文字列
    ///   - title: タイトル
    /// - Throws: InboxRepositoryError.inboxFull（上限到達時）
    func add(url: String, title: String) throws

    // MARK: - 容量確認

    /// Inboxに追加可能かどうか
    /// - Returns: 追加可能な場合true
    func canAdd() -> Bool

    /// 現在のInboxアイテム数を取得
    /// - Returns: アイテム数
    func count() -> Int

    /// 残りの追加可能数を取得
    /// - Returns: 残り容量
    func remainingCapacity() -> Int

    // MARK: - 状態移動

    /// InboxからBookmarkへ移動
    /// - Parameter inbox: 移動元のInbox
    /// - Throws: SwiftDataのエラー
    func moveToBookmark(_ inbox: Inbox) throws

    /// InboxからArchiveへ移動
    /// - Parameter inbox: 移動元のInbox
    /// - Throws: SwiftDataのエラー
    func moveToArchive(_ inbox: Inbox) throws

    // MARK: - 削除

    /// Inboxを削除
    /// - Parameter inbox: 削除対象のInbox
    func delete(_ inbox: Inbox)
}

/// InboxRepository固有のエラー
enum InboxRepositoryError: LocalizedError {
    case inboxFull

    var errorDescription: String? {
        switch self {
        case .inboxFull:
            return "Inboxが上限（\(InboxConfiguration.maxItems)件）に達しています"
        }
    }
}
