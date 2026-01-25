//
//  BookmarkTitle.swift
//  ReadItLater
//
//  Created by Claude on 2025/08/14.
//

import Foundation

struct BookmarkTitle {
    private let value: String
    
    init(_ title: String = "") {
        self.value = title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var displayValue: String {
        return value.isEmpty ? "Untitled Bookmark" : value
    }
    
    var isEmpty: Bool {
        return value.isEmpty
    }
    
    static func fromURL(_ url: BookmarkURL) -> BookmarkTitle {
        return BookmarkTitle(url.extractedTitle)
    }
}