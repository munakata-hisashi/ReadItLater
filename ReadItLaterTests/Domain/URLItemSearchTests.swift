//
//  URLItemSearchTests.swift
//  ReadItLater
//

import Testing
import Foundation
@testable import ReadItLater

@MainActor
struct URLItemSearchTests {
    // テスト用のモックアイテム
    struct MockURLItem: URLItem {
        var id: UUID
        var url: String?
        var title: String?
        var addedInboxAt: Date
    }

    @Test("空文字列での検索は常にマッチする")
    func emptySearchTextAlwaysMatches() {
        let item = MockURLItem(
            id: UUID(),
            url: "https://example.com",
            title: "Example Title",
            addedInboxAt: Date()
        )

        #expect(item.matches(searchText: ""))
    }

    @Test("タイトルで部分一致検索ができる")
    func searchByTitlePartialMatch() {
        let item = MockURLItem(
            id: UUID(),
            url: "https://example.com",
            title: "Swift Programming Guide",
            addedInboxAt: Date()
        )

        #expect(item.matches(searchText: "Swift"))
        #expect(item.matches(searchText: "Programming"))
        #expect(item.matches(searchText: "Guide"))
        #expect(!item.matches(searchText: "Python"))
    }

    @Test("URLで部分一致検索ができる")
    func searchByURLPartialMatch() {
        let item = MockURLItem(
            id: UUID(),
            url: "https://developer.apple.com/swift",
            title: "Swift Documentation",
            addedInboxAt: Date()
        )

        #expect(item.matches(searchText: "apple"))
        #expect(item.matches(searchText: "developer"))
        #expect(item.matches(searchText: "swift"))
        #expect(!item.matches(searchText: "google"))
    }

    @Test("大文字小文字を区別しない検索")
    func caseInsensitiveSearch() {
        let item = MockURLItem(
            id: UUID(),
            url: "https://Example.COM/Test",
            title: "Example Title",
            addedInboxAt: Date()
        )

        #expect(item.matches(searchText: "EXAMPLE"))
        #expect(item.matches(searchText: "example"))
        #expect(item.matches(searchText: "ExAmPlE"))
        #expect(item.matches(searchText: "TEST"))
        #expect(item.matches(searchText: "test"))
    }

    @Test("titleがnilの場合でもURLで検索できる")
    func searchWithNilTitle() {
        let item = MockURLItem(
            id: UUID(),
            url: "https://example.com",
            title: nil,
            addedInboxAt: Date()
        )

        #expect(item.matches(searchText: "example"))
        #expect(!item.matches(searchText: "title"))
    }

    @Test("urlがnilの場合でもタイトルで検索できる")
    func searchWithNilURL() {
        let item = MockURLItem(
            id: UUID(),
            url: nil,
            title: "Example Title",
            addedInboxAt: Date()
        )

        #expect(item.matches(searchText: "Example"))
        #expect(!item.matches(searchText: "example.com"))
    }

    @Test("titleとurlの両方がnilの場合、空文字列以外はマッチしない")
    func searchWithBothNil() {
        let item = MockURLItem(
            id: UUID(),
            url: nil,
            title: nil,
            addedInboxAt: Date()
        )

        #expect(item.matches(searchText: ""))
        #expect(!item.matches(searchText: "anything"))
    }

    @Test("日本語での検索")
    func japaneseSearch() {
        let item = MockURLItem(
            id: UUID(),
            url: "https://example.jp/記事",
            title: "スウィフト入門ガイド",
            addedInboxAt: Date()
        )

        #expect(item.matches(searchText: "スウィフト"))
        #expect(item.matches(searchText: "入門"))
        #expect(item.matches(searchText: "ガイド"))
        #expect(item.matches(searchText: "記事"))
        #expect(!item.matches(searchText: "Python"))
    }
}
