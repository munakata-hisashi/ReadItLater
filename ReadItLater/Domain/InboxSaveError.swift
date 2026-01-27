//
//  InboxSaveError.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/24.
//

import Foundation

/// Inbox保存処理で発生するエラー
enum InboxSaveError: LocalizedError, Equatable {
    case noURLFound
    case containerInitFailed
    case inboxCreationFailed(URLValidationError)
    case inboxFull

    var errorDescription: String? {
        switch self {
        case .noURLFound:
            return "URLが見つかりませんでした"
        case .containerInitFailed:
            return "データベースの初期化に失敗しました"
        case .inboxCreationFailed(let error):
            return "Inboxアイテムの作成に失敗しました: \(error.localizedDescription)"
        case .inboxFull:
            return "Inboxが上限（\(InboxConfiguration.maxItems)件）に達しています。既存のアイテムを整理してください。"
        }
    }
}
