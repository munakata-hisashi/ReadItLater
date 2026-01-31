//
//  ArchiveRepositoryProtocol.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/22.
//

import Foundation

/// Archive永続化操作のためのプロトコル
protocol ArchiveRepositoryProtocol {
    // MARK: - 状態移動

    /// ArchiveからBookmarkへ移動
    /// - Parameter archive: 移動元のArchive
    /// - Throws: SwiftDataのエラー
    func moveToBookmark(_ archive: Archive) throws

    /// ArchiveからInboxへ移動
    /// - Parameters:
    ///   - archive: 移動元のArchive
    ///   - inboxRepository: Inbox容量チェックと追加に使用するリポジトリ
    /// - Throws: InboxError（容量超過時）、SwiftDataのエラー
    func moveToInbox(_ archive: Archive, using inboxRepository: InboxRepositoryProtocol) throws

    // MARK: - 削除

    /// Archiveを削除
    /// - Parameter archive: 削除対象のArchive
    func delete(_ archive: Archive)
}
