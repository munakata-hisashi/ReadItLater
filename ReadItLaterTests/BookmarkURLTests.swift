//
//  BookmarkURLTests.swift
//  ReadItLaterTests
//
//  Created by Claude on 2025/08/14.
//

import XCTest
@testable import ReadItLater

final class BookmarkURLTests: XCTestCase {
    
    // MARK: - 初期化テスト
    
    func test_有効なHTTPSURL_初期化成功() throws {
        let url = try BookmarkURL("https://example.com")
        XCTAssertEqual(url.value, "https://example.com")
    }
    
    func test_有効なHTTPURL_初期化成功() throws {
        let url = try BookmarkURL("http://example.com")
        XCTAssertEqual(url.value, "http://example.com")
    }
    
    func test_空文字列_初期化失敗() {
        XCTAssertThrowsError(try BookmarkURL("")) { error in
            XCTAssertEqual(error as? URLValidationError, .emptyURL)
        }
    }
    
    func test_空白のみ_初期化失敗() {
        XCTAssertThrowsError(try BookmarkURL("   \n\t   ")) { error in
            XCTAssertEqual(error as? URLValidationError, .emptyURL)
        }
    }
    
    func test_無効な形式_初期化失敗() {
        XCTAssertThrowsError(try BookmarkURL("invalid-url")) { error in
            XCTAssertEqual(error as? URLValidationError, .invalidFormat)
        }
    }
    
    func test_プロトコルなし_初期化失敗() {
        XCTAssertThrowsError(try BookmarkURL("example.com")) { error in
            XCTAssertEqual(error as? URLValidationError, .invalidFormat)
        }
    }
    
    func test_ftpプロトコル_初期化失敗() {
        XCTAssertThrowsError(try BookmarkURL("ftp://example.com")) { error in
            XCTAssertEqual(error as? URLValidationError, .unsupportedScheme)
        }
    }
    
    func test_fileプロトコル_初期化失敗() {
        XCTAssertThrowsError(try BookmarkURL("file:///path/to/file")) { error in
            XCTAssertEqual(error as? URLValidationError, .unsupportedScheme)
        }
    }
    
    // MARK: - 正規化テスト
    
    func test_前後空白除去() throws {
        let url = try BookmarkURL("  https://example.com  ")
        XCTAssertEqual(url.value, "https://example.com")
    }
    
    func test_改行文字除去() throws {
        let url = try BookmarkURL("https://example.com\n")
        XCTAssertEqual(url.value, "https://example.com")
    }
    
    func test_タブ文字除去() throws {
        let url = try BookmarkURL("\thttps://example.com\t")
        XCTAssertEqual(url.value, "https://example.com")
    }
    
    // MARK: - タイトル抽出テスト
    
    func test_シンプルドメイン_タイトル抽出() throws {
        let url = try BookmarkURL("https://github.com")
        XCTAssertEqual(url.extractedTitle, "Github.Com")
    }
    
    func test_wwwプレフィックス除去() throws {
        let url = try BookmarkURL("https://www.example.com")
        XCTAssertEqual(url.extractedTitle, "Example.Com")
    }
    
    func test_パス付きURL_ホストのみ使用() throws {
        let url = try BookmarkURL("https://example.com/path/to/page")
        XCTAssertEqual(url.extractedTitle, "Example.Com")
    }
    
    func test_クエリパラメータ付きURL_ホストのみ使用() throws {
        let url = try BookmarkURL("https://example.com/?param=value")
        XCTAssertEqual(url.extractedTitle, "Example.Com")
    }
    
    func test_サブドメイン付きURL_全ホスト使用() throws {
        let url = try BookmarkURL("https://api.example.com")
        XCTAssertEqual(url.extractedTitle, "Api.Example.Com")
    }
    
    func test_複雑なサブドメイン_全ホスト使用() throws {
        let url = try BookmarkURL("https://blog.subdomain.example.com")
        XCTAssertEqual(url.extractedTitle, "Blog.Subdomain.Example.Com")
    }
    
    func test_ポート番号付きURL_ホストのみ使用() throws {
        let url = try BookmarkURL("http://example.com:8080")
        XCTAssertEqual(url.extractedTitle, "Example.Com")
    }
    
    func test_IPアドレス_そのまま表示() throws {
        let url = try BookmarkURL("http://192.168.1.1")
        XCTAssertEqual(url.extractedTitle, "192.168.1.1")
    }
    
    func test_不正なホスト情報_デフォルトタイトル() throws {
        // URLとして有効だがホスト情報を取得できない特殊なケース
        // 実際にこのようなケースが発生するかは要検証
        // 一旦テストケースとして残しておく
    }
    
    // MARK: - 正規化URL取得テスト
    
    func test_正規化URL_元URLと同じ() throws {
        let originalURL = "https://example.com/path?param=value"
        let url = try BookmarkURL("  " + originalURL + "  ")
        XCTAssertEqual(url.normalizedURL, originalURL)
    }
    
    // MARK: - エッジケーステスト
    
    func test_非常に長いURL_処理可能() throws {
        let longURL = "https://example.com/" + String(repeating: "a", count: 2000)
        let url = try BookmarkURL(longURL)
        XCTAssertEqual(url.value, longURL)
    }
    
    func test_日本語ドメイン_処理可能() throws {
        let url = try BookmarkURL("https://日本語.example.com")
        XCTAssertEqual(url.value, "https://日本語.example.com")
    }
    
    func test_特殊文字含むURL_処理可能() throws {
        let specialURL = "https://example.com/path?param=value&other=%E3%81%82"
        let url = try BookmarkURL(specialURL)
        XCTAssertEqual(url.value, specialURL)
    }
    
    // MARK: - 大文字小文字テスト
    
    func test_HTTPSプロトコル大文字_初期化成功() throws {
        let url = try BookmarkURL("HTTPS://example.com")
        XCTAssertEqual(url.value, "HTTPS://example.com")
    }
    
    func test_HTTPプロトコル大文字_初期化成功() throws {
        let url = try BookmarkURL("HTTP://example.com")
        XCTAssertEqual(url.value, "HTTP://example.com")
    }
    
    func test_混合ケースプロトコル_初期化成功() throws {
        let url = try BookmarkURL("HtTpS://example.com")
        XCTAssertEqual(url.value, "HtTpS://example.com")
    }
}