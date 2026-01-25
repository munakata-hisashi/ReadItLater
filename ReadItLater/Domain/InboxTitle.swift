//
//  InboxTitle.swift
//  ReadItLater
//
//  Created by Claude on 2025/08/14.
//

import Foundation

struct InboxTitle {
    private let value: String

    init(_ title: String = "") {
        self.value = title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayValue: String {
        return value.isEmpty ? "Untitled Inbox" : value
    }

    var isEmpty: Bool {
        return value.isEmpty
    }

    static func fromURL(_ url: InboxURL) -> InboxTitle {
        return InboxTitle(url.extractedTitle)
    }
}