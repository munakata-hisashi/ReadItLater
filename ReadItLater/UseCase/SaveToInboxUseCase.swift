//
//  SaveToInboxUseCase.swift
//  ReadItLater
//
//  共通のInbox保存処理
//

import Foundation

/// URL文字列とタイトルからInbox保存を実行する共通UseCase
///
/// Share/DeepLinkの入口ごとの差異を吸収し、保存処理を一元化する。
struct SaveToInboxUseCase {
    private let metadataService: URLMetadataServiceProtocol
    private let repository: InboxRepositoryProtocol

    init(
        metadataService: URLMetadataServiceProtocol,
        repository: InboxRepositoryProtocol
    ) {
        self.metadataService = metadataService
        self.repository = repository
    }

    func execute(urlString: String, title: String?) async -> Result<Void, InboxSaveError> {
        let resolvedTitle: String? = if let title {
            title
        } else {
            await fetchTitle(for: urlString)
        }

        let inboxDataResult = Inbox.create(from: urlString, title: resolvedTitle)
        let inboxData: InboxData
        switch inboxDataResult {
        case .success(let data):
            inboxData = data
        case .failure(let error):
            switch error {
            case .invalidURL(let urlError):
                return .failure(.inboxCreationFailed(urlError))
            }
        }

        return save(inboxData)
    }

    private func fetchTitle(for urlString: String) async -> String? {
        guard let url = URL(string: urlString) else { return nil }

        do {
            let metadata = try await metadataService.fetchMetadata(for: url)
            return metadata.title
        } catch {
            // タイトル取得失敗時はnilを返す（Inbox.createがホスト名で代用）
            return nil
        }
    }

    private func save(_ inboxData: InboxData) -> Result<Void, InboxSaveError> {
        guard repository.canAdd() else {
            return .failure(.inboxFull)
        }

        do {
            try repository.add(url: inboxData.url, title: inboxData.title)
            return .success(())
        } catch let error as InboxRepositoryError {
            switch error {
            case .inboxFull:
                return .failure(.inboxFull)
            }
        } catch {
            return .failure(.containerInitFailed)
        }
    }
}
