//
//  BookmarkCreationTests.swift
//  ReadItLaterTests
//
//  Created by Claude on 2025/08/14.
//

import XCTest
@testable import ReadItLater

final class BookmarkCreationTests: XCTestCase {
    
    // MARK: - 正常系テスト
    
    func test_有効なHTTPSURL_ブックマーク作成成功() {
        let result = Bookmark.create(from: "https://example.com", title: "Example Site")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "https://example.com")
            XCTAssertEqual(data.title, "Example Site")
        case .failure(let error):
            XCTFail("期待される成功結果が得られませんでした: \(error)")
        }
    }
    
    func test_有効なHTTPURL_ブックマーク作成成功() {
        let result = Bookmark.create(from: "http://example.com", title: "Example HTTP")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "http://example.com")
            XCTAssertEqual(data.title, "Example HTTP")
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_タイトル省略_URL由来タイトル自動生成() {
        let result = Bookmark.create(from: "https://github.com")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "https://github.com")
            XCTAssertEqual(data.title, "Github.Com")
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_タイトル空文字列_URL由来タイトル自動生成() {
        let result = Bookmark.create(from: "https://www.example.com", title: "")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "https://www.example.com")
            XCTAssertEqual(data.title, "Example.Com")
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_タイトル空白のみ_URL由来タイトル自動生成() {
        let result = Bookmark.create(from: "https://api.example.com", title: "   \n\t   ")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "https://api.example.com")
            XCTAssertEqual(data.title, "Api.Example.Com")
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_複雑なURL_正常処理() {
        let complexURL = "https://blog.subdomain.example.com/path/to/article?id=123&utm_source=test"
        let result = Bookmark.create(from: complexURL, title: "Complex Article")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, complexURL)
            XCTAssertEqual(data.title, "Complex Article")
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_ポート番号付きURL_正常処理() {
        let result = Bookmark.create(from: "http://localhost:3000", title: "Local Dev Server")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "http://localhost:3000")
            XCTAssertEqual(data.title, "Local Dev Server")
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_IPアドレスURL_正常処理() {
        let result = Bookmark.create(from: "https://192.168.1.1:8080", title: "Router Admin")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "https://192.168.1.1:8080")
            XCTAssertEqual(data.title, "Router Admin")
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    // MARK: - 異常系テスト（URL関連）
    
    func test_空URL_作成失敗() {
        let result = Bookmark.create(from: "", title: "Empty URL")
        
        switch result {
        case .success:
            XCTFail("期待される失敗結果が得られませんでした")
        case .failure(let error):
            if case .invalidURL(let urlError) = error {
                XCTAssertEqual(urlError, .emptyURL)
            } else {
                XCTFail("期待されるエラータイプではありません: \(error)")
            }
        }
    }
    
    func test_空白のみURL_作成失敗() {
        let result = Bookmark.create(from: "   \n\t   ", title: "Whitespace URL")
        
        switch result {
        case .success:
            XCTFail("期待される失敗結果が得られませんでした")
        case .failure(let error):
            if case .invalidURL(let urlError) = error {
                XCTAssertEqual(urlError, .emptyURL)
            } else {
                XCTFail("期待されるエラータイプではありません: \(error)")
            }
        }
    }
    
    func test_無効な形式URL_作成失敗() {
        let result = Bookmark.create(from: "invalid-url-format", title: "Invalid URL")
        
        switch result {
        case .success:
            XCTFail("期待される失敗結果が得られませんでした")
        case .failure(let error):
            if case .invalidURL(let urlError) = error {
                XCTAssertEqual(urlError, .invalidFormat)
            } else {
                XCTFail("期待されるエラータイプではありません: \(error)")
            }
        }
    }
    
    func test_プロトコルなしURL_作成失敗() {
        let result = Bookmark.create(from: "example.com", title: "No Protocol")
        
        switch result {
        case .success:
            XCTFail("期待される失敗結果が得られませんでした")
        case .failure(let error):
            if case .invalidURL(let urlError) = error {
                XCTAssertEqual(urlError, .invalidFormat)
            } else {
                XCTFail("期待されるエラータイプではありません: \(error)")
            }
        }
    }
    
    func test_非対応プロトコル_FTP_作成失敗() {
        let result = Bookmark.create(from: "ftp://ftp.example.com", title: "FTP Site")
        
        switch result {
        case .success:
            XCTFail("期待される失敗結果が得られませんでした")
        case .failure(let error):
            if case .invalidURL(let urlError) = error {
                XCTAssertEqual(urlError, .unsupportedScheme)
            } else {
                XCTFail("期待されるエラータイプではありません: \(error)")
            }
        }
    }
    
    func test_非対応プロトコル_FILE_作成失敗() {
        let result = Bookmark.create(from: "file:///path/to/file", title: "Local File")
        
        switch result {
        case .success:
            XCTFail("期待される失敗結果が得られませんでした")
        case .failure(let error):
            if case .invalidURL(let urlError) = error {
                XCTAssertEqual(urlError, .unsupportedScheme)
            } else {
                XCTFail("期待されるエラータイプではありません: \(error)")
            }
        }
    }
    
    func test_非対応プロトコル_MAILTO_作成失敗() {
        let result = Bookmark.create(from: "mailto:user@example.com", title: "Email")
        
        switch result {
        case .success:
            XCTFail("期待される失敗結果が得られませんでした")
        case .failure(let error):
            if case .invalidURL(let urlError) = error {
                XCTAssertEqual(urlError, .unsupportedScheme)
            } else {
                XCTFail("期待されるエラータイプではありません: \(error)")
            }
        }
    }
    
    // MARK: - 正規化テスト
    
    func test_URL前後空白除去() {
        let result = Bookmark.create(from: "  https://example.com  ", title: "Trimmed URL")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "https://example.com")
            XCTAssertEqual(data.title, "Trimmed URL")
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_タイトル前後空白除去() {
        let result = Bookmark.create(from: "https://example.com", title: "  Trimmed Title  ")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "https://example.com")
            XCTAssertEqual(data.title, "Trimmed Title")
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_URL改行文字除去() {
        let result = Bookmark.create(from: "https://example.com\n\r", title: "URL with newlines")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "https://example.com")
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    // MARK: - エッジケーステスト
    
    func test_非常に長いURL_処理可能() {
        let longPath = String(repeating: "a", count: 1000)
        let longURL = "https://example.com/\(longPath)"
        let result = Bookmark.create(from: longURL, title: "Very Long URL")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, longURL)
            XCTAssertEqual(data.title, "Very Long URL")
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_非常に長いタイトル_処理可能() {
        let longTitle = String(repeating: "あ", count: 500)
        let result = Bookmark.create(from: "https://example.com", title: longTitle)
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "https://example.com")
            XCTAssertEqual(data.title, longTitle)
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_日本語ドメイン_処理可能() {
        let result = Bookmark.create(from: "https://日本語.example.com", title: "日本語ドメイン")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "https://日本語.example.com")
            XCTAssertEqual(data.title, "日本語ドメイン")
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_特殊文字含むURL_処理可能() {
        let specialURL = "https://example.com/search?q=hello%20world&lang=ja"
        let result = Bookmark.create(from: specialURL, title: "Search Result")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, specialURL)
            XCTAssertEqual(data.title, "Search Result")
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_絵文字含むタイトル_処理可能() {
        let emojiTitle = "My Favorite Site 🚀 すごい！ 👍"
        let result = Bookmark.create(from: "https://example.com", title: emojiTitle)
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "https://example.com")
            XCTAssertEqual(data.title, emojiTitle)
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    // MARK: - 国際化テスト
    
    func test_中国語タイトル_処理可能() {
        let chineseTitle = "这是一个中文网站"
        let result = Bookmark.create(from: "https://example.cn", title: chineseTitle)
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "https://example.cn")
            XCTAssertEqual(data.title, chineseTitle)
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_アラビア語タイトル_処理可能() {
        let arabicTitle = "هذا موقع عربي رائع"
        let result = Bookmark.create(from: "https://example.ae", title: arabicTitle)
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "https://example.ae")
            XCTAssertEqual(data.title, arabicTitle)
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    // MARK: - プロトコル大文字小文字テスト
    
    func test_HTTPS大文字_処理可能() {
        let result = Bookmark.create(from: "HTTPS://example.com", title: "Upper HTTPS")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "HTTPS://example.com")
            XCTAssertEqual(data.title, "Upper HTTPS")
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_混合ケースプロトコル_処理可能() {
        let result = Bookmark.create(from: "HtTpS://example.com", title: "Mixed Case")
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data.url, "HtTpS://example.com")
            XCTAssertEqual(data.title, "Mixed Case")
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    // MARK: - Result型の詳細テスト
    
    func test_成功結果_BookmarkData型() {
        let result = Bookmark.create(from: "https://test.com", title: "Test")
        
        switch result {
        case .success(let data):
            // BookmarkData型の確認
            XCTAssertTrue(type(of: data) == BookmarkData.self)
            XCTAssertFalse(data.url.isEmpty)
            XCTAssertFalse(data.title.isEmpty)
        case .failure:
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_失敗結果_CreationError型() {
        let result = Bookmark.create(from: "", title: "Test")
        
        switch result {
        case .success:
            XCTFail("期待される失敗結果が得られませんでした")
        case .failure(let error):
            // Bookmark.CreationError型の確認
            XCTAssertTrue(type(of: error) == Bookmark.CreationError.self)
            XCTAssertNotNil(error.localizedDescription)
        }
    }
}