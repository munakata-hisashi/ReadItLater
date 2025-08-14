# ドメイン駆動設計によるURL入力機能リファクタリング計画

## 概要
現在のAddBookmarkSheet.swiftのViewとロジック混在を解決し、ドメイン駆動設計アプローチでTestableなアーキテクチャにリファクタリングする。

## 現在の問題点

### アーキテクチャ上の課題
- **関心の混在**: UIロジックとビジネスロジックがView内で混在
- **テスト困難性**: privateメソッドによりロジックの単体テストが不可能
- **再利用性の低さ**: URL検証・タイトル抽出が他画面で再利用できない
- **型安全性不足**: 文字列ベースのURL処理で実行時エラーの可能性

### 技術的負債
```swift
// 現在の問題のあるコード例
private func isValidURL(_ urlString: String) -> Bool {
    guard let url = URL(string: urlString) else { return false }
    return url.scheme == "http" || url.scheme == "https"
}
```

## ドメイン分析

### コアドメイン
**「後で読むためのURL管理」** - URLブックマーク機能がアプリケーションの中核

### ドメイン概念
1. **BookmarkURL**: 有効なWebリソースへの参照
2. **BookmarkTitle**: ブックマークの識別可能な名前
3. **Bookmark**: URL管理の集約ルート

## リファクタリング設計

### 1. Value Objects設計

#### BookmarkURL Value Object
```swift
// BookmarkURL.swift
import Foundation

struct BookmarkURL {
    private let rawURL: String
    
    init(_ urlString: String) throws {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw URLValidationError.emptyURL
        }
        
        guard let url = URL(string: trimmed) else {
            throw URLValidationError.invalidFormat
        }
        
        guard ["http", "https"].contains(url.scheme?.lowercased()) else {
            throw URLValidationError.unsupportedScheme
        }
        
        self.rawURL = trimmed
    }
    
    var value: String { rawURL }
    
    var extractedTitle: String {
        guard let url = URL(string: rawURL),
              let host = url.host else {
            return "Untitled Bookmark"
        }
        
        let cleanHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return cleanHost.capitalized
    }
    
    var normalizedURL: String {
        // 正規化処理（必要に応じて）
        return rawURL
    }
}

enum URLValidationError: Error, LocalizedError, Equatable {
    case emptyURL
    case invalidFormat
    case unsupportedScheme
    
    var errorDescription: String? {
        switch self {
        case .emptyURL: return "URLを入力してください"
        case .invalidFormat: return "有効なURL形式で入力してください"
        case .unsupportedScheme: return "http://またはhttps://のURLのみ対応しています"
        }
    }
}
```

#### BookmarkTitle Value Object
```swift
// BookmarkTitle.swift
import Foundation

struct BookmarkTitle {
    private let value: String
    
    init(_ title: String = "") {
        self.value = title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var displayValue: String {
        value.isEmpty ? "Untitled Bookmark" : value
    }
    
    var isEmpty: Bool { value.isEmpty }
    
    static func fromURL(_ url: BookmarkURL) -> BookmarkTitle {
        BookmarkTitle(url.extractedTitle)
    }
}
```

### 2. Rich Domain Model

#### Bookmark集約の拡張
```swift
// BookmarkCreation.swift - 新しいファイル
import Foundation

extension Bookmark {
    enum CreationError: Error, LocalizedError, Equatable {
        case invalidURL(URLValidationError)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL(let urlError):
                return urlError.errorDescription
            }
        }
    }
    
    static func create(
        from urlString: String,
        title: String? = nil
    ) -> Result<BookmarkData, CreationError> {
        do {
            let bookmarkURL = try BookmarkURL(urlString)
            let bookmarkTitle = title.map(BookmarkTitle.init) ?? BookmarkTitle.fromURL(bookmarkURL)
            
            return .success(BookmarkData(
                url: bookmarkURL.value,
                title: bookmarkTitle.displayValue
            ))
        } catch let error as URLValidationError {
            return .failure(.invalidURL(error))
        } catch {
            return .failure(.invalidURL(.invalidFormat))
        }
    }
}

// SwiftDataの制約によりBookmark直接作成は困難なため、中間データ構造を使用
struct BookmarkData {
    let url: String
    let title: String
}
```

### 3. Observable Macro ViewModel

#### AddBookmarkViewModel
```swift
// AddBookmarkViewModel.swift
import SwiftUI

@Observable 
class AddBookmarkViewModel {
    var urlInput: String = ""
    var titleInput: String = ""
    private var validationResult: Result<BookmarkData, Bookmark.CreationError>?
    
    // Computed properties for UI binding
    var validationError: Bookmark.CreationError? {
        if case .failure(let error) = validationResult {
            return error
        }
        return nil
    }
    
    var isInputValid: Bool {
        if case .success = validationResult {
            return true
        }
        return false
    }
    
    var shouldShowError: Bool {
        validationError != nil && !urlInput.isEmpty
    }
    
    var canSave: Bool {
        isInputValid && !urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func validateInput() {
        guard !urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationResult = nil
            return
        }
        
        validationResult = Bookmark.create(from: urlInput, title: titleInput.isEmpty ? nil : titleInput)
    }
    
    func createBookmarkData() -> BookmarkData? {
        validateInput()
        if case .success(let data) = validationResult {
            return data
        }
        return nil
    }
    
    func reset() {
        urlInput = ""
        titleInput = ""
        validationResult = nil
    }
}
```

### 4. View層の簡素化

#### AddBookmarkSheet リファクタリング
```swift
// AddBookmarkSheet.swift
import SwiftUI

struct AddBookmarkSheet: View {
    @State private var viewModel = AddBookmarkViewModel()
    @FocusState private var isURLFieldFocused: Bool
    
    let onSave: (BookmarkData) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                BookmarkInputSection(
                    urlInput: $viewModel.urlInput,
                    titleInput: $viewModel.titleInput,
                    isURLFieldFocused: $isURLFieldFocused
                )
                .onChange(of: viewModel.urlInput) { _, _ in
                    viewModel.validateInput()
                }
                
                if viewModel.shouldShowError {
                    ErrorSection(error: viewModel.validationError)
                }
            }
            .navigationTitle("ブックマーク追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                BookmarkToolbar(
                    onSave: {
                        if let data = viewModel.createBookmarkData() {
                            onSave(data)
                        }
                    },
                    onCancel: onCancel,
                    canSave: viewModel.canSave
                )
            }
        }
        .onAppear {
            isURLFieldFocused = true
        }
    }
}

// MARK: - Sub Views
struct BookmarkInputSection: View {
    @Binding var urlInput: String
    @Binding var titleInput: String
    @FocusState.Binding var isURLFieldFocused: Bool
    
    var body: some View {
        Section {
            TextField("URL", text: $urlInput)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isURLFieldFocused)
            
            TextField("タイトル (任意)", text: $titleInput)
                .autocapitalization(.words)
        } header: {
            Text("ブックマーク詳細")
        } footer: {
            Text("有効なURL (http://またはhttps://) を入力してください")
        }
    }
}

struct ErrorSection: View {
    let error: Bookmark.CreationError?
    
    var body: some View {
        if let error = error {
            Section {
                Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
            }
        }
    }
}

struct BookmarkToolbar: ToolbarContent {
    let onSave: () -> Void
    let onCancel: () -> Void
    let canSave: Bool
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("キャンセル", action: onCancel)
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("保存", action: onSave)
                .disabled(!canSave)
        }
    }
}
```

#### ContentView更新
```swift
// ContentView.swift - onSave部分の更新
.sheet(isPresented: $showingAddSheet) {
    AddBookmarkSheet(
        onSave: { bookmarkData in
            addBookmark(url: bookmarkData.url, title: bookmarkData.title)
            showingAddSheet = false
        },
        onCancel: {
            showingAddSheet = false
        }
    )
}
```

## テスト戦略

### 1. Value Object Tests
```swift
// BookmarkURLTests.swift
import XCTest
@testable import ReadItLater

final class BookmarkURLTests: XCTestCase {
    func test_有効なHTTPSURL_成功() throws {
        let url = try BookmarkURL("https://example.com")
        XCTAssertEqual(url.value, "https://example.com")
    }
    
    func test_無効なURL_失敗() {
        XCTAssertThrowsError(try BookmarkURL("invalid-url")) { error in
            XCTAssertEqual(error as? URLValidationError, .invalidFormat)
        }
    }
    
    func test_タイトル抽出_www除去() throws {
        let url = try BookmarkURL("https://www.example.com/path")
        XCTAssertEqual(url.extractedTitle, "Example.com")
    }
}
```

### 2. Domain Model Tests
```swift
// BookmarkCreationTests.swift
final class BookmarkCreationTests: XCTestCase {
    func test_ブックマーク作成_成功() {
        let result = Bookmark.create(from: "https://example.com", title: "Example Site")
        
        if case .success(let data) = result {
            XCTAssertEqual(data.url, "https://example.com")
            XCTAssertEqual(data.title, "Example Site")
        } else {
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
    
    func test_タイトル自動生成() {
        let result = Bookmark.create(from: "https://github.com")
        
        if case .success(let data) = result {
            XCTAssertEqual(data.url, "https://github.com")
            XCTAssertEqual(data.title, "Github.com")
        } else {
            XCTFail("期待される成功結果が得られませんでした")
        }
    }
}
```

### 3. ViewModel Tests
```swift
// AddBookmarkViewModelTests.swift
@testable import ReadItLater
import Testing

@Suite("AddBookmarkViewModel Tests")
struct AddBookmarkViewModelTests {
    @Test("有効なURL入力で検証成功")
    func validURLInput() {
        let viewModel = AddBookmarkViewModel()
        viewModel.urlInput = "https://example.com"
        viewModel.validateInput()
        
        #expect(viewModel.isInputValid == true)
        #expect(viewModel.validationError == nil)
    }
    
    @Test("無効なURL入力で検証失敗")
    func invalidURLInput() {
        let viewModel = AddBookmarkViewModel()
        viewModel.urlInput = "invalid-url"
        viewModel.validateInput()
        
        #expect(viewModel.isInputValid == false)
        #expect(viewModel.validationError != nil)
    }
}
```

## 実装順序

### フェーズ1: ドメインモデル構築
1. `BookmarkURL` Value Object作成
2. `BookmarkTitle` Value Object作成  
3. `Bookmark.create` 集約メソッド作成
4. エラー型定義

### フェーズ2: ViewModel層
1. `AddBookmarkViewModel` (@Observable) 作成
2. リアクティブなバリデーション実装

### フェーズ3: View層リファクタリング
1. `AddBookmarkSheet` 簡素化
2. Sub Viewコンポーネント分割
3. `ContentView` 統合更新

### フェーズ4: テスト追加
1. Value Object単体テスト
2. Domain Model単体テスト
3. ViewModel単体テスト
4. 統合テスト

### フェーズ5: 最終検証
1. 既存機能回帰テスト実行
2. UI/UXの確認
3. パフォーマンステスト

## 期待される効果

### アーキテクチャ改善
- **Single Responsibility**: 各クラスが単一責任を持つ
- **Testability**: 全レイヤーで単体テスト可能
- **Type Safety**: コンパイル時の型安全性向上
- **Maintainability**: 変更影響範囲の明確化

### 開発効率向上
- **再利用性**: ドメインロジックの他画面での再利用
- **拡張性**: 新機能追加時の影響範囲限定
- **デバッグ容易性**: レイヤー分離によるバグ特定の簡素化

### 技術的品質向上
- **Modern SwiftUI**: @Observable Macroによる最新SwiftUI活用
- **DDD適用**: ドメイン駆動設計によるビジネスロジック整理
- **Clean Architecture**: 依存関係の適切な制御