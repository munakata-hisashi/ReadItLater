//
//  MockURLMetadataService.swift
//  ReadItLaterTests
//
//  Created by Claude Code on 2026/01/24.
//

import Foundation
@testable import ReadItLater

/// URLMetadataServiceのモック実装
@MainActor
final class MockURLMetadataService: URLMetadataServiceProtocol {
    var metadataToReturn: URLMetadata?
    var errorToThrow: Error?

    func fetchMetadata(for url: URL) async throws -> URLMetadata {
        if let error = errorToThrow {
            throw error
        }

        return metadataToReturn ?? URLMetadata(title: nil, description: nil)
    }
}
