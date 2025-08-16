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
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    func createBookmark() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        let result = Bookmark.create(from: urlString, title: titleString.isEmpty ? nil : titleString)
        
        switch result {
        case .success:
            clearErrorMessage()
            return true
            
        case .failure(let error):
            handleCreationError(error)
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func clearErrorMessage() {
        errorMessage = nil
    }
    
    private func handleCreationError(_ error: Bookmark.CreationError) {
        switch error {
        case .invalidURL(let urlError):
            errorMessage = urlError.localizedDescription
        }
    }
}