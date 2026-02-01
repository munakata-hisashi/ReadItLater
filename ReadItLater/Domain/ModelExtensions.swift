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
