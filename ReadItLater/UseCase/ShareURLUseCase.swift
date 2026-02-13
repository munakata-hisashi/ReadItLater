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
/// 2. 共通保存UseCaseに委譲
struct ShareURLUseCase: ShareURLUseCaseProtocol {
    private let itemProvider: ExtensionItemProviderProtocol
    private let saveToInboxUseCase: SaveToInboxUseCase

    init(
        itemProvider: ExtensionItemProviderProtocol,
        metadataService: URLMetadataServiceProtocol,
        repository: InboxRepositoryProtocol
    ) {
        self.itemProvider = itemProvider
        self.saveToInboxUseCase = SaveToInboxUseCase(
            metadataService: metadataService,
            repository: repository
        )
    }

    func execute() async -> Result<Void, InboxSaveError> {
        do {
            // 1. URLとタイトルを抽出
            let (url, maybeTitle) = try await itemProvider.extractURLAndTitle()

            // 2. 共通の保存処理を実行
            return await saveToInboxUseCase.execute(
                urlString: url.absoluteString,
                title: maybeTitle
            )
        } catch let error as InboxSaveError {
            return .failure(error)
        } catch {
            return .failure(.containerInitFailed)
        }
    }
}
