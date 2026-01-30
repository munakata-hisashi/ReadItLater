//
//  MockExtensionItemProvider.swift
//  ReadItLaterTests
//
//  Created by Claude Code on 2026/01/24.
//

import Foundation
@testable import ReadItLater

/// ExtensionItemProviderのモック実装
struct MockExtensionItemProvider: ExtensionItemProviderProtocol {
    var urlToReturn: URL?
    var titleToReturn: String?
    var errorToThrow: Error?

    @MainActor
    func extractURLAndTitle() async throws -> (url: URL, title: String?) {
        if let error = errorToThrow {
            throw error
        }

        guard let url = urlToReturn else {
            throw InboxSaveError.noURLFound
        }

        return (url: url, title: titleToReturn)
    }
}
