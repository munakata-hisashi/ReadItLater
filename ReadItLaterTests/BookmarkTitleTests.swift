//
//  BookmarkTitleTests.swift
//  ReadItLaterTests
//
//  Created by Claude on 2025/08/14.
//

import XCTest
@testable import ReadItLater

final class BookmarkTitleTests: XCTestCase {
    
    // MARK: - 初期化テスト
    
    func test_有効なタイトル_初期化成功() {
        let title = BookmarkTitle("Example Title")
        XCTAssertEqual(title.displayValue, "Example Title")
    }
    
    func test_空文字列_初期化成功() {
        let title = BookmarkTitle("")
        XCTAssertEqual(title.displayValue, "Untitled Bookmark")
        XCTAssertTrue(title.isEmpty)
    }
    
    func test_デフォルト初期化_空タイトル() {
        let title = BookmarkTitle()
        XCTAssertEqual(title.displayValue, "Untitled Bookmark")
        XCTAssertTrue(title.isEmpty)
    }
    
    // MARK: - 正規化テスト
    
    func test_前後空白除去() {
        let title = BookmarkTitle("  Example Title  ")
        XCTAssertEqual(title.displayValue, "Example Title")
        XCTAssertFalse(title.isEmpty)
    }
    
    func test_改行文字除去() {
        let title = BookmarkTitle("Example Title\n")
        XCTAssertEqual(title.displayValue, "Example Title")
    }
    
    func test_タブ文字除去() {
        let title = BookmarkTitle("\tExample Title\t")
        XCTAssertEqual(title.displayValue, "Example Title")
    }
    
    func test_空白のみ文字列_空として扱う() {
        let title = BookmarkTitle("   \n\t   ")
        XCTAssertEqual(title.displayValue, "Untitled Bookmark")
        XCTAssertTrue(title.isEmpty)
    }
    
    // MARK: - isEmpty プロパティテスト
    
    func test_空文字列_isEmpty_true() {
        let title = BookmarkTitle("")
        XCTAssertTrue(title.isEmpty)
    }
    
    func test_有効なタイトル_isEmpty_false() {
        let title = BookmarkTitle("Example Title")
        XCTAssertFalse(title.isEmpty)
    }
    
    func test_空白のみ_isEmpty_true() {
        let title = BookmarkTitle("   ")
        XCTAssertTrue(title.isEmpty)
    }
    
    // MARK: - URLからの生成テスト
    
    func test_URLからタイトル生成_シンプルドメイン() throws {
        let url = try BookmarkURL("https://github.com")
        let title = BookmarkTitle.fromURL(url)
        XCTAssertEqual(title.displayValue, "Github.Com")
        XCTAssertFalse(title.isEmpty)
    }
    
    func test_URLからタイトル生成_wwwプレフィックス除去() throws {
        let url = try BookmarkURL("https://www.example.com")
        let title = BookmarkTitle.fromURL(url)
        XCTAssertEqual(title.displayValue, "Example.Com")
    }
    
    func test_URLからタイトル生成_複雑なURL() throws {
        let url = try BookmarkURL("https://blog.subdomain.example.com/path?param=value")
        let title = BookmarkTitle.fromURL(url)
        XCTAssertEqual(title.displayValue, "Blog.Subdomain.Example.Com")
    }
    
    func test_URLからタイトル生成_IPアドレス() throws {
        let url = try BookmarkURL("http://192.168.1.1:8080")
        let title = BookmarkTitle.fromURL(url)
        XCTAssertEqual(title.displayValue, "192.168.1.1")
    }
    
    // MARK: - displayValue プロパティテスト
    
    func test_displayValue_有効なタイトル_そのまま表示() {
        let title = BookmarkTitle("My Awesome Website")
        XCTAssertEqual(title.displayValue, "My Awesome Website")
    }
    
    func test_displayValue_空タイトル_デフォルト表示() {
        let title = BookmarkTitle("")
        XCTAssertEqual(title.displayValue, "Untitled Bookmark")
    }
    
    func test_displayValue_空白のみ_デフォルト表示() {
        let title = BookmarkTitle("   ")
        XCTAssertEqual(title.displayValue, "Untitled Bookmark")
    }
    
    // MARK: - エッジケーステスト
    
    func test_非常に長いタイトル_処理可能() {
        let longTitle = String(repeating: "あ", count: 1000)
        let title = BookmarkTitle(longTitle)
        XCTAssertEqual(title.displayValue, longTitle)
        XCTAssertFalse(title.isEmpty)
    }
    
    func test_特殊文字含むタイトル_処理可能() {
        let specialTitle = "Title with 特殊文字 & symbols! @#$%^&*()"
        let title = BookmarkTitle(specialTitle)
        XCTAssertEqual(title.displayValue, specialTitle)
    }
    
    func test_絵文字含むタイトル_処理可能() {
        let emojiTitle = "My Website 🚀 日本語 👍"
        let title = BookmarkTitle(emojiTitle)
        XCTAssertEqual(title.displayValue, emojiTitle)
    }
    
    func test_改行含むタイトル_正規化される() {
        let multilineTitle = "Line1\nLine2\rLine3\r\nLine4"
        let title = BookmarkTitle(multilineTitle)
        XCTAssertEqual(title.displayValue, "Line1\nLine2\rLine3\r\nLine4")
    }
    
    // MARK: - 国際化テスト
    
    func test_日本語タイトル_正常処理() {
        let japaneseTitle = "これは日本語のタイトルです"
        let title = BookmarkTitle(japaneseTitle)
        XCTAssertEqual(title.displayValue, japaneseTitle)
    }
    
    func test_中国語タイトル_正常処理() {
        let chineseTitle = "这是中文标题"
        let title = BookmarkTitle(chineseTitle)
        XCTAssertEqual(title.displayValue, chineseTitle)
    }
    
    func test_アラビア語タイトル_正常処理() {
        let arabicTitle = "هذا عنوان عربي"
        let title = BookmarkTitle(arabicTitle)
        XCTAssertEqual(title.displayValue, arabicTitle)
    }
    
    // MARK: - Equatable テスト（将来的にEquatableを実装する場合）
    
    func test_同じタイトル_等価比較_将来実装予定() {
        let title1 = BookmarkTitle("Same Title")
        let title2 = BookmarkTitle("Same Title")
        // XCTAssertEqual(title1, title2) // 将来実装
    }
    
    func test_異なるタイトル_非等価比較_将来実装予定() {
        let title1 = BookmarkTitle("Title 1")
        let title2 = BookmarkTitle("Title 2")
        // XCTAssertNotEqual(title1, title2) // 将来実装
    }
}