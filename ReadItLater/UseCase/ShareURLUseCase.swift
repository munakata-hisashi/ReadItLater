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
        // URL検証
        let validatedURL: String
        let finalTitle: String

        do {
            // URLバリデーション（InboxURLと同じロジック）
            let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmed.isEmpty else {
                throw URLValidationError.emptyURL
            }

            guard let urlObj = URL(string: trimmed),
                  let scheme = urlObj.scheme?.lowercased() else {
                throw URLValidationError.invalidFormat
            }

            guard ["http", "https"].contains(scheme) else {
                throw URLValidationError.unsupportedScheme
            }

            guard urlObj.host != nil else {
                throw URLValidationError.invalidFormat
            }

            validatedURL = trimmed

            // タイトル処理（InboxTitleと同じロジック）
            let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmedTitle.isEmpty {
                finalTitle = trimmedTitle
            } else {
                // URLからタイトルを生成
                if let host = urlObj.host {
                    let cleanHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
                    let components = cleanHost.components(separatedBy: ".")
                    let capitalizedComponents = components.map { component in
                        guard !component.isEmpty else { return component }
                        return component.prefix(1).uppercased() + component.dropFirst()
                    }
                    finalTitle = capitalizedComponents.joined(separator: ".")
                } else {
                    finalTitle = "Untitled Inbox"
                }
            }
        } catch let error as URLValidationError {
            throw InboxSaveError.inboxCreationFailed(error)
        }

        // Inbox上限チェック
        guard repository.canAdd() else {
            throw InboxSaveError.inboxFull
        }

        // Inboxに追加
        try repository.add(
            url: validatedURL,
            title: finalTitle
        )
    }
}
