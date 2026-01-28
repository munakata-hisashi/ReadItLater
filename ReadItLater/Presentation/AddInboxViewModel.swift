//
//  AddInboxViewModel.swift
//  ReadItLater
//
//  Created by Claude on 2025/08/14.
//

import Foundation
import Observation

@Observable
final class AddInboxViewModel {
    
    // MARK: - Published Properties
    
    var urlString: String = "" {
        didSet {
            if urlString != oldValue {
                clearErrorMessage()
                // URL変更時は取得済みタイトルもクリア
                fetchedTitle = nil
                // URL変更時にデバウンス付きでメタデータ取得を開始
                startFetchingMetadataWithDebounce()
            }
        }
    }
    
    var titleString: String = "" {
        didSet {
            if titleString != oldValue {
                clearErrorMessage()
            }
        }
    }
    
    var errorMessage: String?
    var isLoading: Bool = false
    var isFetchingMetadata: Bool = false
    var fetchedTitle: String?
    
    // MARK: - Dependencies

    private let metadataService = URLMetadataService()

    // MARK: - Private Properties

    private var fetchTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    func createInbox() -> InboxData? {
        isLoading = true
        defer { isLoading = false }

        let trimmedTitle = titleString.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? fetchedTitle : trimmedTitle
        let result = Inbox.create(from: urlString, title: finalTitle)

        switch result {
        case .success(let inboxData):
            clearErrorMessage()
            return inboxData

        case .failure(let error):
            handleCreationError(error)
            return nil
        }
    }

    /// デバウンス付きでメタデータ取得を開始
    func startFetchingMetadataWithDebounce() {
        // 前回のタスクをキャンセル
        fetchTask?.cancel()

        fetchTask = Task {
            // 0.5秒のデバウンス
            try? await Task.sleep(nanoseconds: 500_000_000)

            // キャンセルされていないか確認
            guard !Task.isCancelled else { return }

            await fetchMetadataIfNeeded()
        }
    }

    func fetchMetadataIfNeeded() async {
        guard titleString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return
        }
        
        isFetchingMetadata = true
        defer { isFetchingMetadata = false }
        
        do {
            let metadata = try await metadataService.fetchMetadata(for: url)
            fetchedTitle = metadata.title
        } catch {
            fetchedTitle = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func clearErrorMessage() {
        errorMessage = nil
    }
    
    private func handleCreationError(_ error: Inbox.CreationError) {
        switch error {
        case .invalidURL(let urlError):
            errorMessage = urlError.localizedDescription
        }
    }
}
