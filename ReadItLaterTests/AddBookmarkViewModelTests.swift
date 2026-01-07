//
//  AddBookmarkViewModelTests.swift
//  ReadItLaterTests
//
//  Created by Claude on 2025/08/14.
//

import Testing
@testable import ReadItLater

@Suite
@MainActor
struct AddBookmarkViewModelTests {

    let viewModel: AddBookmarkViewModel

    init() {
        viewModel = AddBookmarkViewModel()
    }
    
    // MARK: - 初期状態テスト
    
    @Test func 初期状態_プロパティ確認() {
        #expect(viewModel.urlString == "")
        #expect(viewModel.titleString == "")
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isLoading)
    }
    
    // MARK: - URL入力バリデーション
    
    @Test func 有効なHTTPSURL_エラーなし() {
        viewModel.urlString = "https://example.com"
        viewModel.titleString = "Example Site"

        let result = viewModel.createBookmark()

        #expect(result != nil)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isLoading)
    }

    @Test func 有効なHTTPURL_エラーなし() {
        viewModel.urlString = "http://example.com"
        viewModel.titleString = "HTTP Example"

        let result = viewModel.createBookmark()

        #expect(result != nil)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func 空URL_エラー表示() {
        viewModel.urlString = ""
        viewModel.titleString = "Empty URL"

        let result = viewModel.createBookmark()

        #expect(result == nil)
        #expect(viewModel.errorMessage == "URLを入力してください")
        #expect(!viewModel.isLoading)
    }

    @Test func 空白のみURL_エラー表示() {
        viewModel.urlString = "   \n\t   "
        viewModel.titleString = "Whitespace URL"

        let result = viewModel.createBookmark()

        #expect(result == nil)
        #expect(viewModel.errorMessage == "URLを入力してください")
    }

    @Test func 無効な形式URL_エラー表示() {
        viewModel.urlString = "invalid-url-format"
        viewModel.titleString = "Invalid URL"

        let result = viewModel.createBookmark()

        #expect(result == nil)
        #expect(viewModel.errorMessage == "有効なURL形式で入力してください")
    }

    @Test func プロトコルなしURL_エラー表示() {
        viewModel.urlString = "example.com"
        viewModel.titleString = "No Protocol"

        let result = viewModel.createBookmark()

        #expect(result == nil)
        #expect(viewModel.errorMessage == "有効なURL形式で入力してください")
    }

    @Test func 非対応プロトコル_FTP_エラー表示() {
        viewModel.urlString = "ftp://ftp.example.com"
        viewModel.titleString = "FTP Site"

        let result = viewModel.createBookmark()

        #expect(result == nil)
        #expect(viewModel.errorMessage == "http://またはhttps://のURLのみ対応しています")
    }

    @Test func 非対応プロトコル_FILE_エラー表示() {
        viewModel.urlString = "file:///path/to/file"
        viewModel.titleString = "Local File"

        let result = viewModel.createBookmark()

        #expect(result == nil)
        #expect(viewModel.errorMessage == "http://またはhttps://のURLのみ対応しています")
    }
    
    // MARK: - タイトル処理テスト

    @Test func タイトル省略_URL由来タイトル自動生成() {
        viewModel.urlString = "https://github.com"
        viewModel.titleString = ""

        let result = viewModel.createBookmark()

        #expect(result != nil)
        #expect(viewModel.errorMessage == nil)
        // 注: 実際のブックマーク作成結果はモックで検証する必要がある
    }

    @Test func タイトル空白のみ_URL由来タイトル自動生成() {
        viewModel.urlString = "https://www.example.com"
        viewModel.titleString = "   \n\t   "

        let result = viewModel.createBookmark()

        #expect(result != nil)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - ローディング状態テスト

    @Test func ブックマーク作成中_ローディング状態() {
        viewModel.urlString = "https://example.com"
        viewModel.titleString = "Example"

        // createBookmark()は同期関数だが、内部でisLoadingをtrue/falseに切り替える
        let result = viewModel.createBookmark()

        #expect(result != nil)
        #expect(!viewModel.isLoading) // 完了後はfalse // 完了後はfalse
    }
    
    // MARK: - 入力フィールド更新テスト
    
    @Test func URL入力_状態更新() {
        viewModel.urlString = "https://test.com"
        #expect(viewModel.urlString == "https://test.com")
    }
    
    @Test func タイトル入力_状態更新() {
        viewModel.titleString = "Test Title"
        #expect(viewModel.titleString == "Test Title")
    }
    
    // MARK: - エラー状態リセット

    @Test func URL変更時_エラーメッセージクリア() {
        // 先にエラー状態を作る
        viewModel.urlString = ""
        _ = viewModel.createBookmark()
        #expect(viewModel.errorMessage != nil)

        // URL変更時にエラーメッセージがクリアされることをテスト
        viewModel.urlString = "https://example.com"
        #expect(viewModel.errorMessage == nil)
    }

    @Test func タイトル変更時_エラーメッセージクリア() {
        // 先にエラー状態を作る
        viewModel.urlString = ""
        _ = viewModel.createBookmark()
        #expect(viewModel.errorMessage != nil)

        // タイトル変更時にエラーメッセージがクリアされることをテスト
        viewModel.titleString = "New Title"
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - 複雑なURLテスト

    @Test func 複雑なURL_正常処理() {
        let complexURL = "https://blog.subdomain.example.com/path/to/article?id=123&utm_source=test"
        viewModel.urlString = complexURL
        viewModel.titleString = "Complex Article"

        let result = viewModel.createBookmark()

        #expect(result != nil)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func ポート番号付きURL_正常処理() {
        viewModel.urlString = "http://localhost:3000"
        viewModel.titleString = "Local Dev Server"

        let result = viewModel.createBookmark()

        #expect(result != nil)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func IPアドレスURL_正常処理() {
        viewModel.urlString = "https://192.168.1.1:8080"
        viewModel.titleString = "Router Admin"

        let result = viewModel.createBookmark()

        #expect(result != nil)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - 国際化テスト

    @Test func 日本語ドメイン_正常処理() {
        viewModel.urlString = "https://日本語.example.com"
        viewModel.titleString = "日本語ドメイン"

        let result = viewModel.createBookmark()

        #expect(result != nil)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func 中国語タイトル_正常処理() {
        viewModel.urlString = "https://example.cn"
        viewModel.titleString = "这是一个中文网站"

        let result = viewModel.createBookmark()

        #expect(result != nil)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func アラビア語タイトル_正常処理() {
        viewModel.urlString = "https://example.ae"
        viewModel.titleString = "هذا موقع عربي رائع"

        let result = viewModel.createBookmark()

        #expect(result != nil)
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - Observable更新の確認テスト（@Observable Macro使用）
    
    @Test func urlString更新_プロパティ反映() {
        viewModel.urlString = "https://test.com"
        #expect(viewModel.urlString == "https://test.com")
    }
    
    @Test func titleString更新_プロパティ反映() {
        viewModel.titleString = "Test Title"
        #expect(viewModel.titleString == "Test Title")
    }
    
    @Test func errorMessage設定_プロパティ反映() {
        // エラーを発生させる
        viewModel.urlString = ""
        _ = viewModel.createBookmark()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage == "URLを入力してください")
    }
}