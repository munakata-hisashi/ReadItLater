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

/// cf: https://developer.apple.com/forums/thread/756802
extension MigrationStage: @unchecked @retroactive Sendable { }
extension Schema.Version: @unchecked @retroactive Sendable { }
