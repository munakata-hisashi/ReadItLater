//
//  ShareURLUseCaseProtocol.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/24.
//

import Foundation

/// Share ExtensionからのURL保存処理のUseCaseプロトコル
///
/// ShareViewControllerのビジネスロジックを抽象化し、テスト可能にするためのプロトコル。
protocol ShareURLUseCaseProtocol {
    /// 共有されたURLをInboxに保存
    /// - Returns: 成功または失敗を示すResult
    func execute() async -> Result<Void, InboxSaveError>
}
