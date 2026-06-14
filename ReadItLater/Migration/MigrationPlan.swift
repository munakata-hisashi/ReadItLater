//
//  MigrationPlan.swift
//  ReadItLater
//
//  Created by 宗像恒 on 2025/08/02.
//
import SwiftData

struct AppMigrationPlan: SchemaMigrationPlan {
    static let schemas: [VersionedSchema.Type] = [
        AppV1Schema.self,
        AppV2Schema.self,
        AppV3Schema.self,
        AppV4Schema.self,
        AppV5Schema.self
    ]
    static let stages: [MigrationStage] = [
        migrateV3toV4,
        .lightweight(fromVersion: AppV4Schema.self, toVersion: AppV5Schema.self)
    ]

    static let migrateV3toV4 = MigrationStage.custom(
        fromVersion: AppV3Schema.self,
        toVersion: AppV4Schema.self,
        willMigrate: nil,
        didMigrate: { context in
            let inboxItems = try context.fetch(FetchDescriptor<AppV4Schema.Inbox>())
            for inbox in inboxItems {
                context.insert(AppV4Schema.URLItem(
                    id: inbox.id,
                    url: inbox.url ?? "",
                    title: inbox.title ?? "",
                    addedInboxAt: inbox.addedInboxAt,
                    status: .inbox
                ))
            }

            let bookmarks = try context.fetch(FetchDescriptor<AppV4Schema.Bookmark>())
            for bookmark in bookmarks {
                context.insert(AppV4Schema.URLItem(
                    id: bookmark.id,
                    url: bookmark.url ?? "",
                    title: bookmark.title ?? "",
                    addedInboxAt: bookmark.addedInboxAt,
                    bookmarkedAt: bookmark.bookmarkedAt,
                    status: .bookmark
                ))
            }

            let archives = try context.fetch(FetchDescriptor<AppV4Schema.Archive>())
            for archive in archives {
                context.insert(AppV4Schema.URLItem(
                    id: archive.id,
                    url: archive.url ?? "",
                    title: archive.title ?? "",
                    addedInboxAt: archive.addedInboxAt,
                    archivedAt: archive.archivedAt,
                    status: .archive
                ))
            }

            try context.save()
        }
    )
}
