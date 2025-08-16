//
//  URLValidationError.swift
//  ReadItLater
//
//  Created by Claude on 2025/08/14.
//

import Foundation

enum URLValidationError: Error, LocalizedError, Equatable {
    case emptyURL
    case invalidFormat
    case unsupportedScheme
    
    var errorDescription: String {
        switch self {
        case .emptyURL:
            return "URLを入力してください"
        case .invalidFormat:
            return "有効なURL形式で入力してください"
        case .unsupportedScheme:
            return "http://またはhttps://のURLのみ対応しています"
        }
    }
}
