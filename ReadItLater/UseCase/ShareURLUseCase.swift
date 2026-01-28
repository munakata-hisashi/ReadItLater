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

            // 3. URL検証とInboxデータ生成
            let inboxData = try await createInboxData(from: url, title: title)

            // 4. Inboxに保存
            try saveToInbox(inboxData)

            // 5. 成功完了
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

    private func createInboxData(from url: URL, title: String?) async throws -> InboxData {
        let result = await Inbox.create(from: url.absoluteString, title: title)

        switch result {
        case .success(let inboxData):
            return inboxData
        case .failure(let error):
            switch error {
            case .invalidURL(let urlError):
                throw InboxSaveError.inboxCreationFailed(urlError)
            }
        }
    }

    private func saveToInbox(_ inboxData: InboxData) throws {
        // Inbox上限チェック
        guard repository.canAdd() else {
            throw InboxSaveError.inboxFull
        }

        // Inboxに追加
        do {
            try repository.add(
                url: inboxData.url,
                title: inboxData.title
            )
        } catch let error as InboxRepositoryError {
            switch error {
            case .inboxFull:
                throw InboxSaveError.inboxFull
            }
        } catch {
            throw error
        }
    }
}
