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

    // MARK: - 削除

    /// Archiveを削除
    /// - Parameter archive: 削除対象のArchive
    func delete(_ archive: Archive)
}
