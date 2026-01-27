//
//  URLMetadataService.swift
//  ReadItLater
//
//  Created by Claude on 2025/08/16.
//

import Foundation
import LinkPresentation

struct URLMetadata {
    let title: String?
    let description: String?
}

final class URLMetadataService: URLMetadataServiceProtocol {
    private var currentProvider: LPMetadataProvider?

    func fetchMetadata(for url: URL) async throws -> URLMetadata {
        // 前回のリクエストをキャンセル
        currentProvider?.cancel()

        // 新しいproviderを作成して保持
        let provider = LPMetadataProvider()
        currentProvider = provider

        // メタデータを取得
        let metadata = try await provider.startFetchingMetadata(for: url)
        return URLMetadata(title: metadata.title, description: nil)
    }
}
