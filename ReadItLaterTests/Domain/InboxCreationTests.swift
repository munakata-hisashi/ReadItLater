//
//  InboxCreationTests.swift
//  ReadItLaterTests
//
//  Created by Claude on 2025/08/14.
//

import Testing
@testable import ReadItLater

@MainActor
@Suite struct InboxCreationTests {
    
    // MARK: - 正常系テスト
    
    @Test func 有効なHTTPSURL_ブックマーク作成成功() {
        let result = InboxCreation.create(from: "https://example.com", title: "Example Site")
        
        switch result {
        case .success(let data):
            #expect(data.url == "https://example.com")
            #expect(data.title == "Example Site")
        case .failure(let error):
            Issue.record("期待される成功結果が得られませんでした: \(error)")
        }
    }
    
    @Test func 有効なHTTPURL_ブックマーク作成成功() {
        let result = InboxCreation.create(from: "http://example.com", title: "Example HTTP")
        
        switch result {
        case .success(let data):
            #expect(data.url == "http://example.com")
            #expect(data.title == "Example HTTP")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    @Test func タイトル省略_URL由来タイトル自動生成() {
        let result = InboxCreation.create(from: "https://github.com")
        
        switch result {
        case .success(let data):
            #expect(data.url == "https://github.com")
            #expect(data.title == "Github.Com")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    @Test func タイトル空文字列_URL由来タイトル自動生成() {
        let result = InboxCreation.create(from: "https://www.example.com", title: "")
        
        switch result {
        case .success(let data):
            #expect(data.url == "https://www.example.com")
            #expect(data.title == "Example.Com")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    @Test func タイトル空白のみ_URL由来タイトル自動生成() {
        let result = InboxCreation.create(from: "https://api.example.com", title: "   \n\t   ")
        
        switch result {
        case .success(let data):
            #expect(data.url == "https://api.example.com")
            #expect(data.title == "Api.Example.Com")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    @Test func 複雑なURL_正常処理() {
        let complexURL = "https://blog.subdomain.example.com/path/to/article?id=123&utm_source=test"
        let result = InboxCreation.create(from: complexURL, title: "Complex Article")
        
        switch result {
        case .success(let data):
            #expect(data.url == complexURL)
            #expect(data.title == "Complex Article")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    @Test func ポート番号付きURL_正常処理() {
        let result = InboxCreation.create(from: "http://localhost:3000", title: "Local Dev Server")
        
        switch result {
        case .success(let data):
            #expect(data.url == "http://localhost:3000")
            #expect(data.title == "Local Dev Server")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    @Test func IPアドレスURL_正常処理() {
        let result = InboxCreation.create(from: "https://192.168.1.1:8080", title: "Router Admin")
        
        switch result {
        case .success(let data):
            #expect(data.url == "https://192.168.1.1:8080")
            #expect(data.title == "Router Admin")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    // MARK: - 異常系テスト（URL関連）
    
    @Test func 空URL_作成失敗() {
        let result = InboxCreation.create(from: "", title: "Empty URL")
        
        switch result {
        case .success:
            Issue.record("期待される失敗結果が得られませんでした")
        case .failure(let error):
            if case .invalidURL(let urlError) = error {
                #expect(urlError == .emptyURL)
            } else {
                Issue.record("期待されるエラータイプではありません: \(error)")
            }
        }
    }
    
    @Test func 空白のみURL_作成失敗() {
        let result = InboxCreation.create(from: "   \n\t   ", title: "Whitespace URL")
        
        switch result {
        case .success:
            Issue.record("期待される失敗結果が得られませんでした")
        case .failure(let error):
            if case .invalidURL(let urlError) = error {
                #expect(urlError == .emptyURL)
            } else {
                Issue.record("期待されるエラータイプではありません: \(error)")
            }
        }
    }
    
    @Test func 無効な形式URL_作成失敗() {
        let result = InboxCreation.create(from: "invalid-url-format", title: "Invalid URL")
        
        switch result {
        case .success:
            Issue.record("期待される失敗結果が得られませんでした")
        case .failure(let error):
            if case .invalidURL(let urlError) = error {
                #expect(urlError == .invalidFormat)
            } else {
                Issue.record("期待されるエラータイプではありません: \(error)")
            }
        }
    }
    
    @Test func プロトコルなしURL_作成失敗() {
        let result = InboxCreation.create(from: "example.com", title: "No Protocol")
        
        switch result {
        case .success:
            Issue.record("期待される失敗結果が得られませんでした")
        case .failure(let error):
            if case .invalidURL(let urlError) = error {
                #expect(urlError == .invalidFormat)
            } else {
                Issue.record("期待されるエラータイプではありません: \(error)")
            }
        }
    }
    
    @Test func 非対応プロトコル_FTP_作成失敗() {
        let result = InboxCreation.create(from: "ftp://ftp.example.com", title: "FTP Site")
        
        switch result {
        case .success:
            Issue.record("期待される失敗結果が得られませんでした")
        case .failure(let error):
            if case .invalidURL(let urlError) = error {
                #expect(urlError == .unsupportedScheme)
            } else {
                Issue.record("期待されるエラータイプではありません: \(error)")
            }
        }
    }
    
    @Test func 非対応プロトコル_FILE_作成失敗() {
        let result = InboxCreation.create(from: "file:///path/to/file", title: "Local File")
        
        switch result {
        case .success:
            Issue.record("期待される失敗結果が得られませんでした")
        case .failure(let error):
            if case .invalidURL(let urlError) = error {
                #expect(urlError == .unsupportedScheme)
            } else {
                Issue.record("期待されるエラータイプではありません: \(error)")
            }
        }
    }
    
    @Test func 非対応プロトコル_MAILTO_作成失敗() {
        let result = InboxCreation.create(from: "mailto:user@example.com", title: "Email")
        
        switch result {
        case .success:
            Issue.record("期待される失敗結果が得られませんでした")
        case .failure(let error):
            if case .invalidURL(let urlError) = error {
                #expect(urlError == .unsupportedScheme)
            } else {
                Issue.record("期待されるエラータイプではありません: \(error)")
            }
        }
    }
    
    // MARK: - 正規化テスト
    
    @Test func URL前後空白除去() {
        let result = InboxCreation.create(from: "  https://example.com  ", title: "Trimmed URL")
        
        switch result {
        case .success(let data):
            #expect(data.url == "https://example.com")
            #expect(data.title == "Trimmed URL")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    @Test func タイトル前後空白除去() {
        let result = InboxCreation.create(from: "https://example.com", title: "  Trimmed Title  ")
        
        switch result {
        case .success(let data):
            #expect(data.url == "https://example.com")
            #expect(data.title == "Trimmed Title")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    @Test func URL改行文字除去() {
        let result = InboxCreation.create(from: "https://example.com\n\r", title: "URL with newlines")
        
        switch result {
        case .success(let data):
            #expect(data.url == "https://example.com")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    // MARK: - エッジケーステスト
    
    @Test func 非常に長いURL_処理可能() {
        let longPath = String(repeating: "a", count: 1000)
        let longURL = "https://example.com/\(longPath)"
        let result = InboxCreation.create(from: longURL, title: "Very Long URL")
        
        switch result {
        case .success(let data):
            #expect(data.url == longURL)
            #expect(data.title == "Very Long URL")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    @Test func 非常に長いタイトル_処理可能() {
        let longTitle = String(repeating: "あ", count: 500)
        let result = InboxCreation.create(from: "https://example.com", title: longTitle)
        
        switch result {
        case .success(let data):
            #expect(data.url == "https://example.com")
            #expect(data.title == longTitle)
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    @Test func 日本語ドメイン_処理可能() {
        let result = InboxCreation.create(from: "https://日本語.example.com", title: "日本語ドメイン")
        
        switch result {
        case .success(let data):
            #expect(data.url == "https://日本語.example.com")
            #expect(data.title == "日本語ドメイン")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    @Test func 特殊文字含むURL_処理可能() {
        let specialURL = "https://example.com/search?q=hello%20world&lang=ja"
        let result = InboxCreation.create(from: specialURL, title: "Search Result")
        
        switch result {
        case .success(let data):
            #expect(data.url == specialURL)
            #expect(data.title == "Search Result")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    @Test func 絵文字含むタイトル_処理可能() {
        let emojiTitle = "My Favorite Site 🚀 すごい！ 👍"
        let result = InboxCreation.create(from: "https://example.com", title: emojiTitle)
        
        switch result {
        case .success(let data):
            #expect(data.url == "https://example.com")
            #expect(data.title == emojiTitle)
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    // MARK: - 国際化テスト
    
    @Test func 中国語タイトル_処理可能() {
        let chineseTitle = "这是一个中文网站"
        let result = InboxCreation.create(from: "https://example.cn", title: chineseTitle)
        
        switch result {
        case .success(let data):
            #expect(data.url == "https://example.cn")
            #expect(data.title == chineseTitle)
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    @Test func アラビア語タイトル_処理可能() {
        let arabicTitle = "هذا موقع عربي رائع"
        let result = InboxCreation.create(from: "https://example.ae", title: arabicTitle)
        
        switch result {
        case .success(let data):
            #expect(data.url == "https://example.ae")
            #expect(data.title == arabicTitle)
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    // MARK: - プロトコル大文字小文字テスト
    
    @Test func HTTPS大文字_処理可能() {
        let result = InboxCreation.create(from: "HTTPS://example.com", title: "Upper HTTPS")
        
        switch result {
        case .success(let data):
            #expect(data.url == "HTTPS://example.com")
            #expect(data.title == "Upper HTTPS")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    @Test func 混合ケースプロトコル_処理可能() {
        let result = InboxCreation.create(from: "HtTpS://example.com", title: "Mixed Case")
        
        switch result {
        case .success(let data):
            #expect(data.url == "HtTpS://example.com")
            #expect(data.title == "Mixed Case")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }
    
    // MARK: - Result型の詳細テスト
    
    @Test func 成功結果_BookmarkData型() {
        let result = InboxCreation.create(from: "https://test.com", title: "Test")

        switch result {
        case .success(let data):
            // BookmarkDataの内容確認（型はswitch文で保証済み）
            #expect(data.url == "https://test.com")
            #expect(data.title == "Test")
        case .failure:
            Issue.record("期待される成功結果が得られませんでした")
        }
    }

    @Test func 失敗結果_CreationError型() {
        let result = InboxCreation.create(from: "", title: "Test")

        switch result {
        case .success:
            Issue.record("期待される失敗結果が得られませんでした")
        case .failure(let error):
            // 具体的なエラー値を確認
            #expect(error == .invalidURL(.emptyURL))
        }
    }
}
