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
struct InboxRepository: InboxRepositoryProtocol {
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

        let inbox = Inbox(url: url, title: title, status: .inbox)
        modelContext.insert(inbox)
        try modelContext.save()
    }

    // MARK: - 容量確認

    func canAdd() -> Bool {
        remainingCapacity() > 0
    }

    func count() -> Int {
        let descriptor = FetchDescriptor<Inbox>(
            predicate: #Predicate { $0.status == "inbox" }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func remainingCapacity() -> Int {
        max(0, InboxConfiguration.maxItems - count())
    }

    // MARK: - 状態移動

    func moveToBookmark(_ inbox: Inbox) throws {
        inbox.status = URLItemStatus.bookmark.rawValue
        inbox.bookmarkedAt = Date.now
        inbox.archivedAt = nil
        try modelContext.save()
    }

    func moveToArchive(_ inbox: Inbox) throws {
        inbox.status = URLItemStatus.archive.rawValue
        inbox.bookmarkedAt = nil
        inbox.archivedAt = Date.now
        try modelContext.save()
    }

    // MARK: - 削除

    func delete(_ inbox: Inbox) {
        modelContext.delete(inbox)
    }
}
