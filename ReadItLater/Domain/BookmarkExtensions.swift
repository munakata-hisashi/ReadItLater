//
//  BookmarkExtensions.swift
//  ReadItLater
//
//  Type alias and convenience extensions for Bookmark model
//  Actual model definition is in Migration/VersionedSchema.swift
//

import Foundation

/// 現在のスキーマバージョンのBookmarkモデルへのtype alias
/// 実際の定義は `AppV2Schema.Bookmark` を参照
typealias Bookmark = AppV2Schema.Bookmark

extension Bookmark {
    /// タイトルの安全なアクセサ
    /// - Returns: タイトルが存在する場合はその値、存在しない場合は "No title"
    var safeTitle: String {
        title ?? "No title"
    }

    /// URLの安全なアクセサ
    /// - Returns: 有効なURLの場合はURL、無効な場合はnil
    var maybeURL: URL? {
        URL(string: url ?? "")
    }
}
