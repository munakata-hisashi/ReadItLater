//
//  ShareURLUseCase.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/24.
//

import Foundation

/// Share ExtensionからのURL保存処理のUseCase実装
///
/// 1. URL抽出
/// 2. タイトル取得（メタデータまたはホスト名）
/// 3. URL検証
/// 4. Inboxに保存
@MainActor
final class ShareURLUseCase: ShareURLUseCaseProtocol {
    private let itemProvider: ExtensionItemProviderProtocol
    private let metadataService: URLMetadataServiceProtocol
    private let repository: InboxRepositoryProtocol

    init(
        itemProvider: ExtensionItemProviderProtocol,
        metadataService: URLMetadataServiceProtocol,
        repository: InboxRepositoryProtocol
    ) {
        self.itemProvider = itemProvider
        self.metadataService = metadataService
        self.repository = repository
    }

    func execute() async -> Result<Void, InboxSaveError> {
        do {
            // 1. URL抽出とタイトル抽出
            let (url, maybeTitle) = try await itemProvider.extractURLAndTitle()

            // 2. タイトル取得（共有時のタイトルがない場合はメタデータから取得）
            let title: String? = if maybeTitle != nil {
                maybeTitle
            } else {
                await fetchTitle(for: url)
            }

            // 3. URL検証とInboxに保存
            try saveToInbox(url: url.absoluteString, title: title)

            // 4. 成功完了
            return .success(())

        } catch let error as InboxSaveError {
            return .failure(error)
        } catch {
            return .failure(.containerInitFailed)
        }
    }

    // MARK: - Private

    private func fetchTitle(for url: URL) async -> String? {
        do {
            let metadata = try await metadataService.fetchMetadata(for: url)
            return metadata.title
        } catch {
            // タイトル取得失敗時はnilを返す（BookmarkCreationがホスト名で代用）
            return nil
        }
    }

    private func saveToInbox(url: String, title: String?) throws {
        // 既存のBookmarkCreationロジックを使用（URL検証とタイトル正規化）
        let result = Bookmark.create(from: url, title: title)

        switch result {
        case .success(let bookmarkData):
            // Inbox上限チェック
            guard repository.canAdd() else {
                throw InboxSaveError.inboxFull
            }

            // Inboxに追加
            try repository.add(
                url: bookmarkData.url,
                title: bookmarkData.title
            )

        case .failure(let error):
            throw InboxSaveError.bookmarkCreationFailed(error)
        }
    }
}
