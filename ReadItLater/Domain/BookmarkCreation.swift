//
//  BookmarkCreation.swift
//  ReadItLater
//
//  Bookmark creation factory and validation logic
//

import Foundation

extension Bookmark {
    enum CreationError: Error, LocalizedError, Equatable {
        case invalidURL(URLValidationError)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL(let urlError):
                return urlError.errorDescription
            }
        }
    }
    
    static func create(
        from urlString: String,
        title: String? = nil
    ) -> Result<BookmarkData, CreationError> {
        do {
            let bookmarkURL = try BookmarkURL(urlString)
            
            // タイトル処理: 提供されたタイトルが空の場合はURLから生成
            let bookmarkTitle: BookmarkTitle
            if let providedTitle = title, !BookmarkTitle(providedTitle).isEmpty {
                bookmarkTitle = BookmarkTitle(providedTitle)
            } else {
                bookmarkTitle = BookmarkTitle.fromURL(bookmarkURL)
            }
            
            return .success(BookmarkData(
                url: bookmarkURL.value,
                title: bookmarkTitle.displayValue
            ))
        } catch let error as URLValidationError {
            return .failure(.invalidURL(error))
        } catch {
            return .failure(.invalidURL(.invalidFormat))
        }
    }
}