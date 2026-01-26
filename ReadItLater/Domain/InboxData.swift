//
//  InboxData.swift
//  ReadItLater
//
//  Data Transfer Object for Inbox creation
//

import Foundation

/// Inboxの作成時に使用するデータ転送オブジェクト
///
/// SwiftDataの制約により、Inboxモデルを直接作成することが困難なため、
/// 中間データ構造として使用します。
struct InboxData: Equatable {
    let url: String
    let title: String

    init(url: String, title: String) {
        self.url = url
        self.title = title
    }
}
