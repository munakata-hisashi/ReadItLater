//
//  ModelContainerFactory.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/05.
//

import Foundation
import SwiftData

enum ModelContainerFactory {
    /// App Groups識別子
    static let appGroupIdentifier = "group.munakata-hisashi.ReadItLater"

    /// 共有ModelContainer作成
    static func createSharedContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([Bookmark.self])
        let modelConfiguration: ModelConfiguration

        if inMemory {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
        } else {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier(appGroupIdentifier)
            )
        }

        return try ModelContainer(
            for: schema,
            migrationPlan: AppMigrationPlan.self,
            configurations: modelConfiguration
        )
    }
}
