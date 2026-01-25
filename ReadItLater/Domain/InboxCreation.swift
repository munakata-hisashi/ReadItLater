//
//  InboxCreation.swift
//  ReadItLater
//
//  Inbox creation factory and validation logic
//

import Foundation

extension Inbox {
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
    ) -> Result<InboxData, CreationError> {
        do {
            let inboxURL = try InboxURL(urlString)

            // タイトル処理: 提供されたタイトルが空の場合はURLから生成
            let inboxTitle: InboxTitle
            if let providedTitle = title, !InboxTitle(providedTitle).isEmpty {
                inboxTitle = InboxTitle(providedTitle)
            } else {
                inboxTitle = InboxTitle.fromURL(inboxURL)
            }

            return .success(InboxData(
                url: inboxURL.value,
                title: inboxTitle.displayValue
            ))
        } catch let error as URLValidationError {
            return .failure(.invalidURL(error))
        } catch {
            return .failure(.invalidURL(.invalidFormat))
        }
    }
}