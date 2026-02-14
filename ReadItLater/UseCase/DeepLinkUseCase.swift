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
/// 2. 共通保存UseCaseに委譲
struct DeepLinkUseCase: DeepLinkUseCaseProtocol {
    private let saveToInboxUseCase: SaveToInboxUseCase

    init(
        metadataService: URLMetadataServiceProtocol,
        repository: InboxRepositoryProtocol
    ) {
        self.saveToInboxUseCase = SaveToInboxUseCase(
            metadataService: metadataService,
            repository: repository
        )
    }

    func execute(url: URL) async -> Result<DeepLinkOutput, DeepLinkError> {
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
            let saveResult = await saveToInboxUseCase.execute(urlString: targetURL, title: title)
            switch saveResult {
            case .success:
                return .success(.none)
            case .failure(let error):
                return .failure(.saveFailed(error))
            }
        case .openInbox:
            return .success(.openTab(.inbox))
        case .openBookmarks:
            return .success(.openTab(.bookmarks))
        case .openArchive:
            return .success(.openTab(.archive))
        }
    }
}
