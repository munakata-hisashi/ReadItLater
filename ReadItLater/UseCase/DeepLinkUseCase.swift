//
//  DeepLinkUseCase.swift
//  ReadItLater
//
//  カスタムURLスキーム処理のUseCase実装
//

import Foundation

/// カスタムURLスキーム（readitlater://save?url=...）を処理するUseCase
///
/// 1. URLスキームのパース
/// 2. メタデータ取得（タイトル未指定時）
/// 3. URL検証
/// 4. Inboxに保存
struct DeepLinkUseCase: DeepLinkUseCaseProtocol {
    private let metadataService: URLMetadataServiceProtocol
    private let repository: InboxRepositoryProtocol

    init(
        metadataService: URLMetadataServiceProtocol,
        repository: InboxRepositoryProtocol
    ) {
        self.metadataService = metadataService
        self.repository = repository
    }

    func execute(url: URL) async -> Result<Void, DeepLinkError> {
        // 1. URLスキームのパース
        let action: DeepLinkAction
        do {
            action = try DeepLinkParser.parse(url)
        } catch let error as DeepLinkParser.ParseError {
            return .failure(.parseError(error))
        } catch {
            return .failure(.parseError(.unsupportedScheme))
        }

        // 2. アクションに応じた処理
        switch action {
        case .saveToInbox(let targetURL, let title):
            return await saveToInbox(urlString: targetURL, title: title)
        }
    }

    // MARK: - Private

    private func saveToInbox(urlString: String, title: String?) async -> Result<Void, DeepLinkError> {
        // タイトル未指定の場合はメタデータから取得を試みる
        let resolvedTitle: String? = if let title {
            title
        } else {
            await fetchTitle(for: urlString)
        }

        // URL検証とInboxデータ生成
        let result = Inbox.create(from: urlString, title: resolvedTitle)

        switch result {
        case .success(let inboxData):
            // Inbox上限チェック
            guard repository.canAdd() else {
                return .failure(.saveFailed(.inboxFull))
            }

            do {
                try repository.add(url: inboxData.url, title: inboxData.title)
                return .success(())
            } catch {
                return .failure(.saveFailed(.inboxFull))
            }

        case .failure(let error):
            switch error {
            case .invalidURL(let urlError):
                return .failure(.saveFailed(.inboxCreationFailed(urlError)))
            }
        }
    }

    private func fetchTitle(for urlString: String) async -> String? {
        guard let url = URL(string: urlString) else { return nil }

        do {
            let metadata = try await metadataService.fetchMetadata(for: url)
            return metadata.title
        } catch {
            return nil
        }
    }
}
