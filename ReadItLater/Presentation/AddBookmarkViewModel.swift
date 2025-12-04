//
//  AddBookmarkViewModel.swift
//  ReadItLater
//
//  Created by Claude on 2025/08/14.
//

import Foundation
import Observation

@MainActor
@Observable
final class AddBookmarkViewModel {
    
    // MARK: - Published Properties
    
    var urlString: String = "" {
        didSet {
            if urlString != oldValue {
                clearErrorMessage()
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
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    func createBookmark() -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        let trimmedTitle = titleString.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? fetchedTitle : trimmedTitle
        let result = Bookmark.create(from: urlString, title: finalTitle)
        
        switch result {
        case .success:
            clearErrorMessage()
            return true
            
        case .failure(let error):
            handleCreationError(error)
            return false
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
        fetchedTitle = nil
    }
    
    private func handleCreationError(_ error: Bookmark.CreationError) {
        switch error {
        case .invalidURL(let urlError):
            errorMessage = urlError.localizedDescription
        }
    }
}
