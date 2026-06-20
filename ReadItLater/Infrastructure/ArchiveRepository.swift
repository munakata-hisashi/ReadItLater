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

    func moveToBookmark(_ archive: URLItem) throws {
        archive.status = URLItemStatus.bookmark.rawValue
        archive.bookmarkedAt = Date.now
        archive.archivedAt = nil
        try modelContext.save()
    }

    func moveToInbox(_ archive: URLItem, using inboxRepository: InboxRepositoryProtocol) throws {
        // Inbox容量チェック
        guard inboxRepository.canAdd() else {
            throw InboxRepositoryError.inboxFull
        }

        archive.status = URLItemStatus.inbox.rawValue
        archive.bookmarkedAt = nil
        archive.archivedAt = nil
        try modelContext.save()
    }

    // MARK: - 削除

    func delete(_ archive: URLItem) {
        modelContext.delete(archive)
    }
}
