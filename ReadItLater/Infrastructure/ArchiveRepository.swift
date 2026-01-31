//
//  ArchiveRepository.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/22.
//

import Foundation
import SwiftData

/// SwiftDataを使用したArchiveRepository実装
struct ArchiveRepository: ArchiveRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - 状態移動

    func moveToBookmark(_ archive: Archive) throws {
        let bookmark = Bookmark(
            url: archive.url ?? "",
            title: archive.title ?? "",
            addedInboxAt: archive.addedInboxAt,  // 元の追加日時を引き継ぐ
            bookmarkedAt: Date.now  // Bookmarkに移動した日時
        )

        modelContext.insert(bookmark)
        modelContext.delete(archive)
        try modelContext.save()
    }

    func moveToInbox(_ archive: Archive, using inboxRepository: InboxRepositoryProtocol) throws {
        // Inbox容量チェック
        guard inboxRepository.canAdd() else {
            throw InboxRepositoryError.inboxFull
        }

        // Inboxを作成（元の追加日時を引き継ぐ）
        let inbox = Inbox(
            url: archive.url ?? "",
            title: archive.title ?? "",
            addedInboxAt: archive.addedInboxAt  // 元の追加日時を維持
        )

        modelContext.insert(inbox)
        modelContext.delete(archive)
        try modelContext.save()
    }

    // MARK: - 削除

    func delete(_ archive: Archive) {
        modelContext.delete(archive)
    }
}
