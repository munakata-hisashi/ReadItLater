//
//  MockInboxRepository.swift
//  ReadItLaterTests
//
//  Created by Claude Code on 2026/01/24.
//

import Foundation
@testable import ReadItLater

/// InboxRepositoryのモック実装
final class MockInboxRepository: InboxRepositoryProtocol {
    var canAddResult = true
    var countResult = 0
    var addCalled = false
    var addedURL: String?
    var addedTitle: String?
    var errorToThrow: Error?

    func add(url: String, title: String) throws {
        if let error = errorToThrow {
            throw error
        }
        addCalled = true
        addedURL = url
        addedTitle = title
        countResult += 1
    }

    func canAdd() -> Bool {
        return canAddResult
    }

    func count() -> Int {
        return countResult
    }

    func remainingCapacity() -> Int {
        return InboxConfiguration.maxItems - countResult
    }

    func moveToBookmark(_ inbox: Inbox) throws {
        // テストでは未使用
    }

    func moveToArchive(_ inbox: Inbox) throws {
        // テストでは未使用
    }

    func delete(_ inbox: Inbox) {
        // テストでは未使用
    }
}
