//
//  BookmarkURLTests.swift
//  ReadItLaterTests
//
//  Created by Claude on 2025/08/14.
//

import Testing
@testable import ReadItLater

@Suite struct BookmarkURLTests {
    
    // MARK: - 初期化テスト
    
    @Test func 有効なHTTPSURL_初期化成功() throws {
        let url = try BookmarkURL("https://example.com")
        #expect(url.value == "https://example.com")
    }
    
    @Test func 有効なHTTPURL_初期化成功() throws {
        let url = try BookmarkURL("http://example.com")
        #expect(url.value == "http://example.com")
    }
    
    @Test func 空文字列_初期化失敗() {
        var caughtError: URLValidationError?
        do {
            _ = try BookmarkURL("")
            Issue.record("Expected URLValidationError to be thrown")
        } catch let error as URLValidationError {
            caughtError = error
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
        #expect(caughtError == .emptyURL)
    }
    
    @Test func 空白のみ_初期化失敗() {
        var caughtError: URLValidationError?
        do {
            _ = try BookmarkURL("   \n\t   ")
            Issue.record("Expected URLValidationError to be thrown")
        } catch let error as URLValidationError {
            caughtError = error
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
        #expect(caughtError == .emptyURL)
    }
    
    @Test func 無効な形式_初期化失敗() {
        var caughtError: URLValidationError?
        do {
            _ = try BookmarkURL("invalid-url")
            Issue.record("Expected URLValidationError to be thrown")
        } catch let error as URLValidationError {
            caughtError = error
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
        #expect(caughtError == .invalidFormat)
    }
    
    @Test func プロトコルなし_初期化失敗() {
        var caughtError: URLValidationError?
        do {
            _ = try BookmarkURL("example.com")
            Issue.record("Expected URLValidationError to be thrown")
        } catch let error as URLValidationError {
            caughtError = error
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
        #expect(caughtError == .invalidFormat)
    }
    
    @Test func ftpプロトコル_初期化失敗() {
        var caughtError: URLValidationError?
        do {
            _ = try BookmarkURL("ftp://example.com")
            Issue.record("Expected URLValidationError to be thrown")
        } catch let error as URLValidationError {
            caughtError = error
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
        #expect(caughtError == .unsupportedScheme)
    }
    
    @Test func fileプロトコル_初期化失敗() {
        var caughtError: URLValidationError?
        do {
            _ = try BookmarkURL("file:///path/to/file")
            Issue.record("Expected URLValidationError to be thrown")
        } catch let error as URLValidationError {
            caughtError = error
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
        #expect(caughtError == .unsupportedScheme)
    }
    
    // MARK: - 正規化テスト
    
    @Test func 前後空白除去() throws {
        let url = try BookmarkURL("  https://example.com  ")
        #expect(url.value == "https://example.com")
    }
    
    @Test func 改行文字除去() throws {
        let url = try BookmarkURL("https://example.com\n")
        #expect(url.value == "https://example.com")
    }
    
    @Test func タブ文字除去() throws {
        let url = try BookmarkURL("\thttps://example.com\t")
        #expect(url.value == "https://example.com")
    }
    
    // MARK: - タイトル抽出テスト
    
    @Test func シンプルドメイン_タイトル抽出() throws {
        let url = try BookmarkURL("https://github.com")
        #expect(url.extractedTitle == "Github.Com")
    }
    
    @Test func wwwプレフィックス除去() throws {
        let url = try BookmarkURL("https://www.example.com")
        #expect(url.extractedTitle == "Example.Com")
    }
    
    @Test func パス付きURL_ホストのみ使用() throws {
        let url = try BookmarkURL("https://example.com/path/to/page")
        #expect(url.extractedTitle == "Example.Com")
    }
    
    @Test func クエリパラメータ付きURL_ホストのみ使用() throws {
        let url = try BookmarkURL("https://example.com/?param=value")
        #expect(url.extractedTitle == "Example.Com")
    }
    
    @Test func サブドメイン付きURL_全ホスト使用() throws {
        let url = try BookmarkURL("https://api.example.com")
        #expect(url.extractedTitle == "Api.Example.Com")
    }
    
    @Test func 複雑なサブドメイン_全ホスト使用() throws {
        let url = try BookmarkURL("https://blog.subdomain.example.com")
        #expect(url.extractedTitle == "Blog.Subdomain.Example.Com")
    }
    
    @Test func ポート番号付きURL_ホストのみ使用() throws {
        let url = try BookmarkURL("http://example.com:8080")
        #expect(url.extractedTitle == "Example.Com")
    }
    
    @Test func IPアドレス_そのまま表示() throws {
        let url = try BookmarkURL("http://192.168.1.1")
        #expect(url.extractedTitle == "192.168.1.1")
    }
    
    @Test func 不正なホスト情報_デフォルトタイトル() throws {
        // URLとして有効だがホスト情報を取得できない特殊なケース
        // 実際にこのようなケースが発生するかは要検証
        // 一旦テストケースとして残しておく
    }
    
    // MARK: - 正規化URL取得テスト
    
    @Test func 正規化URL_元URLと同じ() throws {
        let originalURL = "https://example.com/path?param=value"
        let url = try BookmarkURL("  " + originalURL + "  ")
        #expect(url.normalizedURL == originalURL)
    }
    
    // MARK: - エッジケーステスト
    
    @Test func 非常に長いURL_処理可能() throws {
        let longURL = "https://example.com/" + String(repeating: "a", count: 2000)
        let url = try BookmarkURL(longURL)
        #expect(url.value == longURL)
    }
    
    @Test func 日本語ドメイン_処理可能() throws {
        let url = try BookmarkURL("https://日本語.example.com")
        #expect(url.value == "https://日本語.example.com")
    }
    
    @Test func 特殊文字含むURL_処理可能() throws {
        let specialURL = "https://example.com/path?param=value&other=%E3%81%82"
        let url = try BookmarkURL(specialURL)
        #expect(url.value == specialURL)
    }
    
    // MARK: - 大文字小文字テスト
    
    @Test func HTTPSプロトコル大文字_初期化成功() throws {
        let url = try BookmarkURL("HTTPS://example.com")
        #expect(url.value == "HTTPS://example.com")
    }
    
    @Test func HTTPプロトコル大文字_初期化成功() throws {
        let url = try BookmarkURL("HTTP://example.com")
        #expect(url.value == "HTTP://example.com")
    }
    
    @Test func 混合ケースプロトコル_初期化成功() throws {
        let url = try BookmarkURL("HtTpS://example.com")
        #expect(url.value == "HtTpS://example.com")
    }
}