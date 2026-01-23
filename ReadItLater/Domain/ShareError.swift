//
//  ShareError.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/24.
//

import Foundation

/// Share Extension固有のエラー
enum ShareError: LocalizedError, Equatable {
    case noURLFound
    case containerInitFailed
    case bookmarkCreationFailed(Bookmark.CreationError)
    case inboxFull

    var errorDescription: String? {
        switch self {
        case .noURLFound:
            return "URLが見つかりませんでした"
        case .containerInitFailed:
            return "データベースの初期化に失敗しました"
        case .bookmarkCreationFailed(let error):
            return "ブックマークの作成に失敗しました: \(error.localizedDescription)"
        case .inboxFull:
            return "Inboxが上限（\(InboxConfiguration.maxItems)件）に達しています。既存のアイテムを整理してください。"
        }
    }

    static func == (lhs: ShareError, rhs: ShareError) -> Bool {
        switch (lhs, rhs) {
        case (.noURLFound, .noURLFound),
             (.containerInitFailed, .containerInitFailed),
             (.inboxFull, .inboxFull):
            return true
        case (.bookmarkCreationFailed(let lhsError), .bookmarkCreationFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
