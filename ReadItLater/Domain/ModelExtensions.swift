//
//  ModelExtensions.swift
//  ReadItLater
//

import Foundation

/// 現在のスキーマバージョンのモデルへのtype alias
typealias Inbox = AppV3Schema.Inbox
typealias Bookmark = AppV3Schema.Bookmark
typealias Archive = AppV3Schema.Archive

/// 共通プロトコル: URLを持つアイテム
protocol URLItem {
    var id: UUID { get }
    var url: String? { get }
    var title: String? { get }
    var addedInboxAt: Date { get }
}

extension Inbox: URLItem {}
extension Bookmark: URLItem {}
extension Archive: URLItem {}

/// URLItemの共通extension
extension URLItem {
    var safeTitle: String {
        title ?? "No title"
    }

    var maybeURL: URL? {
        URL(string: url ?? "")
    }
}
