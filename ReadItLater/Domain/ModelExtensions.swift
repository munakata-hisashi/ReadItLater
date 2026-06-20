//
//  ModelExtensions.swift
//  ReadItLater
//

import Foundation

/// 現在のスキーマバージョンのモデルへのtype alias
typealias URLItem = AppV5Schema.URLItem
typealias Inbox = AppV5Schema.URLItem
typealias Bookmark = AppV5Schema.URLItem
typealias Archive = AppV5Schema.URLItem

/// 共通プロトコル: URLを持つアイテム
protocol URLItemDisplayable {
    var id: UUID { get }
    var url: String? { get }
    var title: String? { get }
    var addedInboxAt: Date { get }
    var bookmarkedAt: Date? { get }
    var archivedAt: Date? { get }
    var status: String { get }
}

extension URLItem: URLItemDisplayable {}

/// URLItemの共通extension
extension URLItemDisplayable {
    var itemStatus: URLItemStatus? {
        URLItemStatus(rawValue: status)
    }

    var safeTitle: String {
        title ?? "No title"
    }

    var maybeURL: URL? {
        URL(string: url ?? "")
    }

    /// 検索テキストがタイトルまたはURLに含まれるかを判定
    /// - Parameter searchText: 検索文字列
    /// - Returns: マッチする場合true、空文字列の場合も常にtrue
    func matches(searchText: String) -> Bool {
        guard !searchText.isEmpty else { return true }
        let titleMatches = title?.localizedCaseInsensitiveContains(searchText) ?? false
        let urlMatches = url?.localizedCaseInsensitiveContains(searchText) ?? false
        return titleMatches || urlMatches
    }
}
