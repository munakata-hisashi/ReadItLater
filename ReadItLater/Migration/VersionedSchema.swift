//
//  VersionedSchema.swift
//  ReadItLater
//
//  Created by 宗像恒 on 2025/08/02.
//
import Foundation
import SwiftData

struct AppV1Schema: VersionedSchema {
    static let models: [any PersistentModel.Type] = [Item.self, Bookmark.self]
    static let versionIdentifier: Schema.Version = .init(1, 0, 0)
    
    @Model
    final class Item {
        var id: UUID = UUID()
        var timestamp: Date?
        var url: String?
        var title: String?
        init(timestamp: Date = .now, url: String = "", title: String = "") {
            self.timestamp = timestamp
            self.url = url
            self.title = title
        }
    }
    
    @Model
    final class Bookmark {
        var id: UUID = UUID()
        var createdAt: Date = Date.now
        var url: String?
        var title: String?
        
        init(url: String, title: String = "") {
            self.url = url
            self.title = title
        }
        
    }
}

struct AppV2Schema: VersionedSchema {
    static let models: [any PersistentModel.Type] = [Bookmark.self]
    static let versionIdentifier: Schema.Version = .init(2, 0, 0)

    @Model
    final class Bookmark {
        var id: UUID = UUID()
        var createdAt: Date = Date.now
        var url: String?
        var title: String?

        init(url: String, title: String = "") {
            self.url = url
            self.title = title
        }
    }
}

struct AppV3Schema: VersionedSchema {
    static let models: [any PersistentModel.Type] = [
        Inbox.self,
        Bookmark.self,
        Archive.self
    ]
    static let versionIdentifier: Schema.Version = .init(3, 0, 0)

    /// Inbox: 新規追加されたURL（最大50件制限）
    @Model
    final class Inbox {
        var id: UUID = UUID()
        var addedInboxAt: Date = Date.now  // Inboxに追加された日時
        var url: String?
        var title: String?

        init(id: UUID = UUID(), url: String, title: String, addedInboxAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.addedInboxAt = addedInboxAt
        }
    }

    /// Bookmark: 定期的に見たいURL
    @Model
    final class Bookmark {
        var id: UUID = UUID()
        var addedInboxAt: Date = Date.now  // 重要: デフォルト値必須（軽量マイグレーション）
        var bookmarkedAt: Date = Date.now  // Bookmarkに移動した日時
        var url: String?
        var title: String?

        init(id: UUID = UUID(), url: String, title: String, addedInboxAt: Date = Date.now, bookmarkedAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.addedInboxAt = addedInboxAt
            self.bookmarkedAt = bookmarkedAt
        }
    }

    /// Archive: 読み終わったURL
    @Model
    final class Archive {
        var id: UUID = UUID()
        var addedInboxAt: Date = Date.now  // 重要: デフォルト値必須（軽量マイグレーション）
        var archivedAt: Date = Date.now  // Archiveに移動した日時
        var url: String?
        var title: String?

        init(id: UUID = UUID(), url: String, title: String, addedInboxAt: Date = Date.now, archivedAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.addedInboxAt = addedInboxAt
            self.archivedAt = archivedAt
        }
    }
}

enum URLItemStatus: String {
    case inbox
    case bookmark
    case archive
}

struct AppV4Schema: VersionedSchema {
    static let models: [any PersistentModel.Type] = [
        Inbox.self,
        Bookmark.self,
        Archive.self,
        URLItem.self
    ]
    static let versionIdentifier: Schema.Version = .init(4, 0, 0)

    @Model
    final class Inbox {
        var id: UUID = UUID()
        var addedInboxAt: Date = Date.now
        var url: String?
        var title: String?

        init(id: UUID = UUID(), url: String, title: String, addedInboxAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.addedInboxAt = addedInboxAt
        }
    }

    @Model
    final class Bookmark {
        var id: UUID = UUID()
        var addedInboxAt: Date = Date.now
        var bookmarkedAt: Date = Date.now
        var url: String?
        var title: String?

        init(id: UUID = UUID(), url: String, title: String, addedInboxAt: Date = Date.now, bookmarkedAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.addedInboxAt = addedInboxAt
            self.bookmarkedAt = bookmarkedAt
        }
    }

    @Model
    final class Archive {
        var id: UUID = UUID()
        var addedInboxAt: Date = Date.now
        var archivedAt: Date = Date.now
        var url: String?
        var title: String?

        init(id: UUID = UUID(), url: String, title: String, addedInboxAt: Date = Date.now, archivedAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.addedInboxAt = addedInboxAt
            self.archivedAt = archivedAt
        }
    }

    /// URLItem: V3の3モデルを集約するための中間モデル。
    @Model
    final class URLItem {
        var id: UUID = UUID()
        var addedInboxAt: Date = Date.now
        var bookmarkedAt: Date?
        var archivedAt: Date?
        var url: String?
        var title: String?
        var status: String = URLItemStatus.inbox.rawValue

        init(
            id: UUID = UUID(),
            url: String,
            title: String,
            addedInboxAt: Date = Date.now,
            bookmarkedAt: Date? = nil,
            archivedAt: Date? = nil,
            status: URLItemStatus = .inbox
        ) {
            self.id = id
            self.url = url
            self.title = title
            self.addedInboxAt = addedInboxAt
            self.bookmarkedAt = bookmarkedAt
            self.archivedAt = archivedAt
            self.status = status.rawValue
        }
    }
}

struct AppV5Schema: VersionedSchema {
    static let models: [any PersistentModel.Type] = [
        URLItem.self
    ]
    static let versionIdentifier: Schema.Version = .init(5, 0, 0)

    /// URLItem: URLの共通本体。現在の置き場所はstatusで表す。
    @Model
    final class URLItem {
        var id: UUID = UUID()
        var addedInboxAt: Date = Date.now
        var bookmarkedAt: Date?
        var archivedAt: Date?
        var url: String?
        var title: String?
        var status: String = URLItemStatus.inbox.rawValue

        init(
            id: UUID = UUID(),
            url: String,
            title: String,
            addedInboxAt: Date = Date.now,
            bookmarkedAt: Date? = nil,
            archivedAt: Date? = nil,
            status: URLItemStatus = .inbox
        ) {
            self.id = id
            self.url = url
            self.title = title
            self.addedInboxAt = addedInboxAt
            self.bookmarkedAt = bookmarkedAt
            self.archivedAt = archivedAt
            self.status = status.rawValue
        }
    }
}
