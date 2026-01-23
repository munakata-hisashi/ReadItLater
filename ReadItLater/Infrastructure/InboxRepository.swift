//
//  InboxRepository.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/22.
//

import Foundation
import SwiftData

/// SwiftDataを使用したInboxRepository実装
///
/// InboxRepositoryProtocolの具体的な実装。
/// ModelContextを通じてSwiftDataへのCRUD操作を提供する。
///
/// # 使用方法
/// ```swift
/// let repository = InboxRepository(modelContext: modelContext)
/// try repository.add(url: "https://example.com", title: "Example")
/// ```
///
/// # テスト
/// テスト時はin-memory ModelContainerのcontextを注入することで、
/// 実際のデータベースに影響を与えずにテストが可能。
final class InboxRepository: InboxRepositoryProtocol {
    private let modelContext: ModelContext

    /// イニシャライザ
    /// - Parameter modelContext: SwiftDataのModelContext
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - 追加操作

    func add(url: String, title: String) throws {
        guard canAdd() else {
            throw InboxRepositoryError.inboxFull
        }

        let inbox = Inbox(url: url, title: title)
        modelContext.insert(inbox)
        try modelContext.save()
    }

    // MARK: - 容量確認

    func canAdd() -> Bool {
        remainingCapacity() > 0
    }

    func count() -> Int {
        let descriptor = FetchDescriptor<Inbox>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func remainingCapacity() -> Int {
        max(0, InboxConfiguration.maxItems - count())
    }

    // MARK: - 状態移動

    func moveToBookmark(_ inbox: Inbox) throws {
        let bookmark = Bookmark(
            url: inbox.url ?? "",
            title: inbox.title ?? "",
            addedInboxAt: inbox.addedInboxAt,  // 元の追加日時を引き継ぐ
            bookmarkedAt: Date.now  // Bookmarkに移動した日時
        )

        modelContext.insert(bookmark)
        modelContext.delete(inbox)
        try modelContext.save()
    }

    func moveToArchive(_ inbox: Inbox) throws {
        let archive = Archive(
            url: inbox.url ?? "",
            title: inbox.title ?? "",
            addedInboxAt: inbox.addedInboxAt,  // 元の追加日時を引き継ぐ
            archivedAt: Date.now  // Archiveに移動した日時
        )

        modelContext.insert(archive)
        modelContext.delete(inbox)
        try modelContext.save()
    }

    // MARK: - 削除

    func delete(_ inbox: Inbox) {
        modelContext.delete(inbox)
    }
}
