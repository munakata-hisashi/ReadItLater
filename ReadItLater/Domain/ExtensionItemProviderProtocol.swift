//
//  ExtensionItemProviderProtocol.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/24.
//

import Foundation

/// NSExtensionItemからのURL/タイトル抽出のためのプロトコル
///
/// Share Extensionのinput処理を抽象化し、テスト可能にするためのプロトコル。
protocol ExtensionItemProviderProtocol {
    /// ExtensionからURLとタイトルを抽出
    /// - Returns: (URL, タイトル) のタプル。タイトルは取得できない場合はnil
    /// - Throws: URLが見つからない場合や読み込みエラー
    @MainActor
    func extractURLAndTitle() async throws -> (url: URL, title: String?)
}
