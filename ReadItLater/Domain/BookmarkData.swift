//
//  BookmarkData.swift
//  ReadItLater
//
//  Data Transfer Object for Bookmark creation
//

import Foundation

/// Bookmarkの作成時に使用するデータ転送オブジェクト
///
/// SwiftDataの制約により、Bookmarkモデルを直接作成することが困難なため、
/// 中間データ構造として使用します。
struct BookmarkData: Equatable {
    let url: String
    let title: String

    init(url: String, title: String) {
        self.url = url
        self.title = title
    }
}
