//
//  ExtensionItemProvider.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/24.
//

import Foundation
import UIKit

/// NSExtensionContextからURLとタイトルを抽出する実装
final class ExtensionItemProvider: ExtensionItemProviderProtocol {
    private weak var extensionContext: NSExtensionContext?

    init(extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
    }

    @MainActor
    func extractURLAndTitle() async throws -> (url: URL, title: String?) {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProviders = extensionItem.attachments else {
            throw ShareError.noURLFound
        }

        var foundURL: URL?
        var foundTitle: String?

        for provider in itemProviders {
            if foundURL == nil, provider.hasItemConformingToTypeIdentifier("public.url") {
                let url: URL? = try await withCheckedThrowingContinuation { continuation in
                    provider.loadItem(forTypeIdentifier: "public.url", options: nil) { item, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: item as? URL)
                        }
                    }
                }
                foundURL = url
            }

            if foundTitle == nil, provider.hasItemConformingToTypeIdentifier("public.plain-text") {
                let text: String? = try await withCheckedThrowingContinuation { continuation in
                    provider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { item, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: item as? String)
                        }
                    }
                }
                foundTitle = text
            }
        }

        guard let url = foundURL else {
            throw ShareError.noURLFound
        }

        return (url: url, title: foundTitle)
    }
}
