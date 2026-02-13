//
//  DeepLinkParserTests.swift
//  ReadItLaterTests
//
//  DeepLinkParserのユニットテスト
//

import Testing
import Foundation
@testable import ReadItLater

@Suite("DeepLinkParser")
@MainActor
struct DeepLinkParserTests {

    // MARK: - saveアクションのパース成功

    @Test("save - URLとタイトル指定")
    func testParseSave_WithURLAndTitle() throws {
        let url = URL(string: "readitlater://save?url=https%3A%2F%2Fexample.com&title=Example%20Title")!
        let action = try DeepLinkParser.parse(url)
        #expect(action == .saveToInbox(url: "https://example.com", title: "Example Title"))
    }

    @Test("save - URLのみ（タイトルなし）")
    func testParseSave_WithURLOnly() throws {
        let url = URL(string: "readitlater://save?url=https%3A%2F%2Fexample.com")!
        let action = try DeepLinkParser.parse(url)
        #expect(action == .saveToInbox(url: "https://example.com", title: nil))
    }

    @Test("save - 日本語タイトル")
    func testParseSave_WithJapaneseTitle() throws {
        let urlString = "readitlater://save?url=https%3A%2F%2Fexample.com&title=" + "テスト記事".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: urlString)!
        let action = try DeepLinkParser.parse(url)
        #expect(action == .saveToInbox(url: "https://example.com", title: "テスト記事"))
    }

    @Test("save - パスやクエリ付きURL")
    func testParseSave_WithComplexURL() throws {
        let targetURL = "https://example.com/path/to/page?key=value&other=123"
        let encoded = targetURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: "readitlater://save?url=\(encoded)")!
        let action = try DeepLinkParser.parse(url)
        #expect(action == .saveToInbox(url: targetURL, title: nil))
    }

    @Test("save - パスやクエリ付きURLとタイトル")
    func testParseSave_WithComplexURLAndTitle() throws {
        let targetURL = "https://example.com/path/to/page?key=value&other=123"
        let encodedURL = targetURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let encodedTitle = "Example Title".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: "readitlater://save?url=\(encodedURL)&title=\(encodedTitle)")!
        let action = try DeepLinkParser.parse(url)
        #expect(action == .saveToInbox(url: targetURL, title: "Example Title"))
    }

    @Test("save - スキーム大文字小文字を区別しない")
    func testParseSave_CaseInsensitiveScheme() throws {
        let url = URL(string: "ReadItLater://save?url=https%3A%2F%2Fexample.com")!
        let action = try DeepLinkParser.parse(url)
        #expect(action == .saveToInbox(url: "https://example.com", title: nil))
    }

    // MARK: - パースエラー

    @Test("エラー - サポートされていないスキーム")
    func testParse_UnsupportedScheme() {
        let url = URL(string: "https://example.com")!
        #expect(throws: DeepLinkParser.ParseError.unsupportedScheme) {
            try DeepLinkParser.parse(url)
        }
    }

    @Test("エラー - 不明なアクション")
    func testParse_UnknownAction() {
        let url = URL(string: "readitlater://unknown")!
        #expect(throws: DeepLinkParser.ParseError.unknownAction("unknown")) {
            try DeepLinkParser.parse(url)
        }
    }

    @Test("エラー - saveアクションでURL未指定")
    func testParseSave_MissingURL() {
        let url = URL(string: "readitlater://save")!
        #expect(throws: DeepLinkParser.ParseError.missingURL) {
            try DeepLinkParser.parse(url)
        }
    }

    @Test("エラー - saveアクションでURL空文字")
    func testParseSave_EmptyURL() {
        let url = URL(string: "readitlater://save?url=")!
        #expect(throws: DeepLinkParser.ParseError.missingURL) {
            try DeepLinkParser.parse(url)
        }
    }

    @Test("エラー - saveアクションでurlパラメータなし（他のパラメータあり）")
    func testParseSave_NoURLParam() {
        let url = URL(string: "readitlater://save?title=Test")!
        #expect(throws: DeepLinkParser.ParseError.missingURL) {
            try DeepLinkParser.parse(url)
        }
    }

    @Test("エラー - アクションなし（ホストなし）")
    func testParse_NoHost() {
        let url = URL(string: "readitlater:///path")!
        #expect(throws: DeepLinkParser.ParseError.unknownAction("")) {
            try DeepLinkParser.parse(url)
        }
    }
}
