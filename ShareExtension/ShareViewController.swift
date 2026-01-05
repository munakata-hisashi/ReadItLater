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
            // 1. URL抽出
            guard let url = try await extractURL() else {
                throw ShareError.noURLFound
            }

            // 2. タイトル取得（非同期）
            let title = await fetchTitle(for: url)

            // 3. ブックマーク保存
            try await saveBookmark(url: url.absoluteString, title: title)

            // 4. 成功完了
            completeRequest(with: .success(()))

        } catch {
            completeRequest(with: .failure(error))
        }
    }

    private func extractURL() async throws -> URL? {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            return nil
        }

        if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
            return try await withCheckedThrowingContinuation { continuation in
                itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { (item, error) in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = item as? URL {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
        return nil
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
