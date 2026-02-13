//
//  DeepLinkUseCaseProtocol.swift
//  ReadItLater
//
//  カスタムURLスキーム処理のUseCaseプロトコル
//

import Foundation

/// カスタムURLスキーム処理のUseCaseプロトコル
protocol DeepLinkUseCaseProtocol {
    /// カスタムURLスキームを処理してInboxに保存する
    /// - Parameter url: カスタムURLスキームのURL
    /// - Returns: 処理結果
    func execute(url: URL) async -> Result<Void, DeepLinkError>
}

/// ディープリンク処理で発生するエラー
enum DeepLinkError: Error, LocalizedError, Equatable {
    case parseError(DeepLinkParser.ParseError)
    case saveFailed(InboxSaveError)

    var errorDescription: String? {
        switch self {
        case .parseError(let error):
            return error.errorDescription
        case .saveFailed(let error):
            return error.errorDescription
        }
    }
}
