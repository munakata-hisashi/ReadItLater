//
//  BookmarkTitleTests.swift
//  ReadItLaterTests
//
//  Created by Claude on 2025/08/14.
//

import Testing
@testable import ReadItLater

@Suite struct BookmarkTitleTests {
    
    // MARK: - 初期化テスト
    
    @Test func 有効なタイトル_初期化成功() {
        let title = BookmarkTitle("Example Title")
        #expect(title.displayValue == "Example Title")
    }
    
    @Test func 空文字列_初期化成功() {
        let title = BookmarkTitle("")
        #expect(title.displayValue == "Untitled Bookmark")
        #expect(title.isEmpty)
    }
    
    @Test func デフォルト初期化_空タイトル() {
        let title = BookmarkTitle()
        #expect(title.displayValue == "Untitled Bookmark")
        #expect(title.isEmpty)
    }
    
    // MARK: - 正規化テスト
    
    @Test func 前後空白除去() {
        let title = BookmarkTitle("  Example Title  ")
        #expect(title.displayValue == "Example Title")
        #expect(!title.isEmpty)
    }
    
    @Test func 改行文字除去() {
        let title = BookmarkTitle("Example Title\n")
        #expect(title.displayValue == "Example Title")
    }
    
    @Test func タブ文字除去() {
        let title = BookmarkTitle("\tExample Title\t")
        #expect(title.displayValue == "Example Title")
    }
    
    @Test func 空白のみ文字列_空として扱う() {
        let title = BookmarkTitle("   \n\t   ")
        #expect(title.displayValue == "Untitled Bookmark")
        #expect(title.isEmpty)
    }
    
    // MARK: - isEmpty プロパティテスト
    
    @Test func 空文字列_isEmpty_true() {
        let title = BookmarkTitle("")
        #expect(title.isEmpty)
    }
    
    @Test func 有効なタイトル_isEmpty_false() {
        let title = BookmarkTitle("Example Title")
        #expect(!title.isEmpty)
    }
    
    @Test func 空白のみ_isEmpty_true() {
        let title = BookmarkTitle("   ")
        #expect(title.isEmpty)
    }
    
    // MARK: - URLからの生成テスト
    
    @Test func URLからタイトル生成_シンプルドメイン() throws {
        let url = try BookmarkURL("https://github.com")
        let title = BookmarkTitle.fromURL(url)
        #expect(title.displayValue == "Github.Com")
        #expect(!title.isEmpty)
    }
    
    @Test func URLからタイトル生成_wwwプレフィックス除去() throws {
        let url = try BookmarkURL("https://www.example.com")
        let title = BookmarkTitle.fromURL(url)
        #expect(title.displayValue == "Example.Com")
    }
    
    @Test func URLからタイトル生成_複雑なURL() throws {
        let url = try BookmarkURL("https://blog.subdomain.example.com/path?param=value")
        let title = BookmarkTitle.fromURL(url)
        #expect(title.displayValue == "Blog.Subdomain.Example.Com")
    }
    
    @Test func URLからタイトル生成_IPアドレス() throws {
        let url = try BookmarkURL("http://192.168.1.1:8080")
        let title = BookmarkTitle.fromURL(url)
        #expect(title.displayValue == "192.168.1.1")
    }
    
    // MARK: - displayValue プロパティテスト
    
    @Test func displayValue_有効なタイトル_そのまま表示() {
        let title = BookmarkTitle("My Awesome Website")
        #expect(title.displayValue == "My Awesome Website")
    }
    
    @Test func displayValue_空タイトル_デフォルト表示() {
        let title = BookmarkTitle("")
        #expect(title.displayValue == "Untitled Bookmark")
    }
    
    @Test func displayValue_空白のみ_デフォルト表示() {
        let title = BookmarkTitle("   ")
        #expect(title.displayValue == "Untitled Bookmark")
    }
    
    // MARK: - エッジケーステスト
    
    @Test func 非常に長いタイトル_処理可能() {
        let longTitle = String(repeating: "あ", count: 1000)
        let title = BookmarkTitle(longTitle)
        #expect(title.displayValue == longTitle)
        #expect(!title.isEmpty)
    }
    
    @Test func 特殊文字含むタイトル_処理可能() {
        let specialTitle = "Title with 特殊文字 & symbols! @#$%^&*()"
        let title = BookmarkTitle(specialTitle)
        #expect(title.displayValue == specialTitle)
    }
    
    @Test func 絵文字含むタイトル_処理可能() {
        let emojiTitle = "My Website 🚀 日本語 👍"
        let title = BookmarkTitle(emojiTitle)
        #expect(title.displayValue == emojiTitle)
    }
    
    @Test func 改行含むタイトル_正規化される() {
        let multilineTitle = "Line1\nLine2\rLine3\r\nLine4"
        let title = BookmarkTitle(multilineTitle)
        #expect(title.displayValue == "Line1\nLine2\rLine3\r\nLine4")
    }
    
    // MARK: - 国際化テスト
    
    @Test func 日本語タイトル_正常処理() {
        let japaneseTitle = "これは日本語のタイトルです"
        let title = BookmarkTitle(japaneseTitle)
        #expect(title.displayValue == japaneseTitle)
    }
    
    @Test func 中国語タイトル_正常処理() {
        let chineseTitle = "这是中文标题"
        let title = BookmarkTitle(chineseTitle)
        #expect(title.displayValue == chineseTitle)
    }
    
    @Test func アラビア語タイトル_正常処理() {
        let arabicTitle = "هذا عنوان عربي"
        let title = BookmarkTitle(arabicTitle)
        #expect(title.displayValue == arabicTitle)
    }
    
    // MARK: - Equatable テスト（将来的にEquatableを実装する場合）
    
    @Test func 同じタイトル_等価比較_将来実装予定() {
        let _ = BookmarkTitle("Same Title")
        let _ = BookmarkTitle("Same Title")
        // XCTAssertEqual(title1, title2) // 将来実装
    }

    @Test func 異なるタイトル_非等価比較_将来実装予定() {
        let _ = BookmarkTitle("Title 1")
        let _ = BookmarkTitle("Title 2")
        // XCTAssertNotEqual(title1, title2) // 将来実装
    }
}