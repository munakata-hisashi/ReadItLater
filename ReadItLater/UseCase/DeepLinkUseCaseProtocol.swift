//
//  DeepLinkUseCaseProtocol.swift
//  ReadItLater
//
//  カスタムURLスキーム処理のUseCaseプロトコル
//

import Foundation

/// カスタムURLスキーム処理のUseCaseプロトコル
protocol DeepLinkUseCaseProtocol {
    /// カスタムURLスキームを処理する
    /// - Parameter url: カスタムURLスキームのURL
    /// - Returns: 処理結果
    func execute(url: URL) async -> Result<DeepLinkOutput, DeepLinkError>
}


/// ディープリンク処理結果
enum DeepLinkOutput: Equatable {
    /// 保存処理のみ実行した
    case none
    /// 指定のタブを開く
    case openTab(MainTab)
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
