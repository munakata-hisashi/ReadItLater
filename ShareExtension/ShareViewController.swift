//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by 宗像恒 on 2026/01/05.
//

import UIKit
import SwiftData

@MainActor
final class ShareViewController: UIViewController {

    private var modelContainer: ModelContainer?
    private let metadataService = URLMetadataService()

    override func viewDidLoad() {
        super.viewDidLoad()

        // ModelContainer初期化
        do {
            modelContainer = try ModelContainerFactory.createSharedContainer()
        } catch {
            completeRequest(with: .failure(ShareError.containerInitFailed))
            return
        }

        // URL処理
        Task {
            await processSharedURL()
        }
    }

    private func processSharedURL() async {
        do {
            // 1. URL抽出とタイトル抽出
            let (url, maybeTitle) = try await extractURLAndTitle()
            let title: String? = if maybeTitle != nil {
                maybeTitle
            } else {
                await fetchTitle(for: url)
            }

            // 3. ブックマーク保存
            try await saveBookmark(url: url.absoluteString, title: title)

            // 4. 成功完了
            completeRequest(with: .success(()))

        } catch {
            completeRequest(with: .failure(error))
        }
    }

    private func extractURLAndTitle() async throws -> (url: URL, title: String?) {
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

    private func fetchTitle(for url: URL) async -> String? {
        do {
            let metadata = try await metadataService.fetchMetadata(for: url)
            return metadata.title
        } catch {
            // タイトル取得失敗時はnilを返す（BookmarkCreationがホスト名で代用）
            return nil
        }
    }

    private func saveBookmark(url: String, title: String?) async throws {
        guard let container = modelContainer else {
            throw ShareError.containerInitFailed
        }

        // 既存のBookmarkCreationロジックを使用
        let result = Bookmark.create(from: url, title: title)

        switch result {
        case .success(let bookmarkData):
            let context = ModelContext(container)
            let bookmark = Bookmark(url: bookmarkData.url, title: bookmarkData.title)
            context.insert(bookmark)
            try context.save()

        case .failure(let error):
            throw ShareError.bookmarkCreationFailed(error)
        }
    }

    private func completeRequest(with result: Result<Void, Error>) {
        switch result {
        case .success:
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        case .failure(let error):
            extensionContext?.cancelRequest(withError: error as NSError)
        }
    }
}

enum ShareError: LocalizedError {
    case noURLFound
    case containerInitFailed
    case bookmarkCreationFailed(Bookmark.CreationError)

    var errorDescription: String? {
        switch self {
        case .noURLFound:
            return "URLが見つかりませんでした"
        case .containerInitFailed:
            return "データベースの初期化に失敗しました"
        case .bookmarkCreationFailed(let error):
            return "ブックマークの作成に失敗しました: \(error.localizedDescription)"
        }
    }
}
