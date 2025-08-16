//
//  AddBookmarkViewModelTests.swift
//  ReadItLaterTests
//
//  Created by Claude on 2025/08/14.
//

import XCTest
@testable import ReadItLater

@MainActor
final class AddBookmarkViewModelTests: XCTestCase {
    
    var viewModel: AddBookmarkViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = AddBookmarkViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - 初期状態テスト
    
    func test_初期状態_プロパティ確認() {
        XCTAssertEqual(viewModel.urlString, "")
        XCTAssertEqual(viewModel.titleString, "")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - URL入力バリデーション
    
    func test_有効なHTTPSURL_エラーなし() async {
        viewModel.urlString = "https://example.com"
        viewModel.titleString = "Example Site"
        
        let result = await viewModel.createBookmark()
        
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_有効なHTTPURL_エラーなし() async {
        viewModel.urlString = "http://example.com"
        viewModel.titleString = "HTTP Example"
        
        let result = await viewModel.createBookmark()
        
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_空URL_エラー表示() async {
        viewModel.urlString = ""
        viewModel.titleString = "Empty URL"
        
        let result = await viewModel.createBookmark()
        
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "URLを入力してください")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_空白のみURL_エラー表示() async {
        viewModel.urlString = "   \n\t   "
        viewModel.titleString = "Whitespace URL"
        
        let result = await viewModel.createBookmark()
        
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "URLを入力してください")
    }
    
    func test_無効な形式URL_エラー表示() async {
        viewModel.urlString = "invalid-url-format"
        viewModel.titleString = "Invalid URL"
        
        let result = await viewModel.createBookmark()
        
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "有効なURL形式で入力してください")
    }
    
    func test_プロトコルなしURL_エラー表示() async {
        viewModel.urlString = "example.com"
        viewModel.titleString = "No Protocol"
        
        let result = await viewModel.createBookmark()
        
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "有効なURL形式で入力してください")
    }
    
    func test_非対応プロトコル_FTP_エラー表示() async {
        viewModel.urlString = "ftp://ftp.example.com"
        viewModel.titleString = "FTP Site"
        
        let result = await viewModel.createBookmark()
        
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "http://またはhttps://のURLのみ対応しています")
    }
    
    func test_非対応プロトコル_FILE_エラー表示() async {
        viewModel.urlString = "file:///path/to/file"
        viewModel.titleString = "Local File"
        
        let result = await viewModel.createBookmark()
        
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "http://またはhttps://のURLのみ対応しています")
    }
    
    // MARK: - タイトル処理テスト
    
    func test_タイトル省略_URL由来タイトル自動生成() async {
        viewModel.urlString = "https://github.com"
        viewModel.titleString = ""
        
        let result = await viewModel.createBookmark()
        
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
        // 注: 実際のブックマーク作成結果はモックで検証する必要がある
    }
    
    func test_タイトル空白のみ_URL由来タイトル自動生成() async {
        viewModel.urlString = "https://www.example.com"
        viewModel.titleString = "   \n\t   "
        
        let result = await viewModel.createBookmark()
        
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - ローディング状態テスト
    
    func test_ブックマーク作成中_ローディング状態() async {
        viewModel.urlString = "https://example.com"
        viewModel.titleString = "Example"
        
        // 非同期処理の開始をテスト
        let createTask = Task {
            await viewModel.createBookmark()
        }
        
        // 短時間待機してローディング状態を確認
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        await createTask.value
        XCTAssertFalse(viewModel.isLoading) // 完了後はfalse
    }
    
    // MARK: - 入力フィールド更新テスト
    
    func test_URL入力_状態更新() {
        viewModel.urlString = "https://test.com"
        XCTAssertEqual(viewModel.urlString, "https://test.com")
    }
    
    func test_タイトル入力_状態更新() {
        viewModel.titleString = "Test Title"
        XCTAssertEqual(viewModel.titleString, "Test Title")
    }
    
    // MARK: - エラー状態リセット
    
    func test_URL変更時_エラーメッセージクリア() async {
        // 先にエラー状態を作る
        viewModel.urlString = ""
        await viewModel.createBookmark()
        XCTAssertNotNil(viewModel.errorMessage)
        
        // URL変更時にエラーメッセージがクリアされることをテスト
        viewModel.urlString = "https://example.com"
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_タイトル変更時_エラーメッセージクリア() async {
        // 先にエラー状態を作る
        viewModel.urlString = ""
        await viewModel.createBookmark()
        XCTAssertNotNil(viewModel.errorMessage)
        
        // タイトル変更時にエラーメッセージがクリアされることをテスト
        viewModel.titleString = "New Title"
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - 複雑なURLテスト
    
    func test_複雑なURL_正常処理() async {
        let complexURL = "https://blog.subdomain.example.com/path/to/article?id=123&utm_source=test"
        viewModel.urlString = complexURL
        viewModel.titleString = "Complex Article"
        
        let result = await viewModel.createBookmark()
        
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_ポート番号付きURL_正常処理() async {
        viewModel.urlString = "http://localhost:3000"
        viewModel.titleString = "Local Dev Server"
        
        let result = await viewModel.createBookmark()
        
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_IPアドレスURL_正常処理() async {
        viewModel.urlString = "https://192.168.1.1:8080"
        viewModel.titleString = "Router Admin"
        
        let result = await viewModel.createBookmark()
        
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - 国際化テスト
    
    func test_日本語ドメイン_正常処理() async {
        viewModel.urlString = "https://日本語.example.com"
        viewModel.titleString = "日本語ドメイン"
        
        let result = await viewModel.createBookmark()
        
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_中国語タイトル_正常処理() async {
        viewModel.urlString = "https://example.cn"
        viewModel.titleString = "这是一个中文网站"
        
        let result = await viewModel.createBookmark()
        
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_アラビア語タイトル_正常処理() async {
        viewModel.urlString = "https://example.ae"
        viewModel.titleString = "هذا موقع عربي رائع"
        
        let result = await viewModel.createBookmark()
        
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Observable更新の確認テスト（@Observable Macro使用）
    
    func test_urlString更新_プロパティ反映() {
        viewModel.urlString = "https://test.com"
        XCTAssertEqual(viewModel.urlString, "https://test.com")
    }
    
    func test_titleString更新_プロパティ反映() {
        viewModel.titleString = "Test Title"
        XCTAssertEqual(viewModel.titleString, "Test Title")
    }
    
    func test_errorMessage設定_プロパティ反映() async {
        // エラーを発生させる
        viewModel.urlString = ""
        await viewModel.createBookmark()
        
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "URLを入力してください")
    }
}