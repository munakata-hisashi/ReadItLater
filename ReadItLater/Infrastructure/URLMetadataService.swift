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

@MainActor
final class URLMetadataService {
    private let metadataProvider = LPMetadataProvider()
    private var currentProvider: LPMetadataProvider?
    func fetchMetadata(for url: URL) async throws -> URLMetadata {
        
        currentProvider?.cancel()
        
        let metadataProvider = LPMetadataProvider()
        currentProvider = metadataProvider
        let hoge = try await currentProvider!.startFetchingMetadata(for: url)

        return URLMetadata(title: hoge.title, description: hoge.originalURL?.absoluteString)
    }
}
