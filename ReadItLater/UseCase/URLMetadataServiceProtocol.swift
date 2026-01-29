//
//  URLMetadataServiceProtocol.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/24.
//

import Foundation

/// URLメタデータ取得のためのプロトコル
///
/// テスト時にモック実装を注入可能にするためのプロトコル。
protocol URLMetadataServiceProtocol {
    /// 指定されたURLのメタデータを取得
    /// - Parameter url: メタデータ取得対象のURL
    /// - Returns: 取得したメタデータ
    /// - Throws: メタデータ取得に失敗した場合のエラー
    func fetchMetadata(for url: URL) async throws -> URLMetadata
}
