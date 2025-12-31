# Issue 1: View層からビジネスロジックを分離

## 優先度
🔴 高優先度

## 概要
`AddBookmarkSheet.swift` (View層) にビジネスロジックとデバウンス処理が混在しており、View の責務を超えています。これらのロジックを `AddBookmarkViewModel` (Presentation層) に移動することで、責務を明確に分離します。

## 現在の問題点

### 1. デバウンス処理がViewに存在
**ファイル**: `View/AddBookmarkSheet.swift:88-104`

```swift
.onChange(of: viewModel.urlString) { oldValue, newValue in
    // 前回のタスクをキャンセル
    fetchTask?.cancel()

    fetchTask = Task {
        // 0.5秒のデバウンス
        try? await Task.sleep(nanoseconds: 500_000_000)

        // キャンセルされていないか確認
        guard !Task.isCancelled else { return }

        // URL文字列が変更されていないか確認
        if viewModel.urlString == newValue {
            await viewModel.fetchMetadataIfNeeded()
        }
    }
}
```

**問題**: デバウンス処理はビジネスロジックであり、Viewではなく ViewModel で管理すべきです。

### 2. ドメインロジックの直接呼び出し
**ファイル**: `View/AddBookmarkSheet.swift:117-128`

```swift
@MainActor
private func saveBookmark() async {
    let success = viewModel.createBookmark()
    if success {
        // ドメインモデルから成功時のBookmarkDataを取得
        let trimmedTitle = viewModel.titleString.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? viewModel.fetchedTitle : trimmedTitle
        let result = Bookmark.create(from: viewModel.urlString, title: finalTitle)
        if case .success(let bookmarkData) = result {
            onSave(bookmarkData)
        }
    }
}
```

**問題**: View が直接 `Bookmark.create()` を呼び出しており、ViewModel の `createBookmark()` と重複した処理を行っています。

## リファクタリング手順

### ステップ 1: ViewModelにデバウンス処理を追加

**ファイル**: `Presentation/AddBookmarkViewModel.swift`

1. `fetchTask` プロパティを追加
2. `startFetchingMetadataWithDebounce()` メソッドを追加

```swift
@MainActor
@Observable
final class AddBookmarkViewModel {

    // MARK: - Published Properties

    var urlString: String = "" {
        didSet {
            if urlString != oldValue {
                clearErrorMessage()
                fetchedTitle = nil
                // URL変更時にデバウンス付きでメタデータ取得を開始
                startFetchingMetadataWithDebounce()
            }
        }
    }

    // ... 既存のプロパティ ...

    // MARK: - Private Properties

    private var fetchTask: Task<Void, Never>?

    // MARK: - Public Methods

    /// デバウンス付きでメタデータ取得を開始
    func startFetchingMetadataWithDebounce() {
        // 前回のタスクをキャンセル
        fetchTask?.cancel()

        fetchTask = Task {
            // 0.5秒のデバウンス
            try? await Task.sleep(nanoseconds: 500_000_000)

            // キャンセルされていないか確認
            guard !Task.isCancelled else { return }

            await fetchMetadataIfNeeded()
        }
    }

    // ... 既存のメソッド ...
}
```

### ステップ 2: ViewModelの `createBookmark()` メソッドを改善

**ファイル**: `Presentation/AddBookmarkViewModel.swift`

`createBookmark()` メソッドを `BookmarkData?` を返すように変更：

```swift
func createBookmark() -> BookmarkData? {
    isLoading = true
    defer { isLoading = false }

    let trimmedTitle = titleString.trimmingCharacters(in: .whitespacesAndNewlines)
    let finalTitle = trimmedTitle.isEmpty ? fetchedTitle : trimmedTitle
    let result = Bookmark.create(from: urlString, title: finalTitle)

    switch result {
    case .success(let bookmarkData):
        clearErrorMessage()
        return bookmarkData

    case .failure(let error):
        handleCreationError(error)
        return nil
    }
}
```

### ステップ 3: Viewをシンプルに修正

**ファイル**: `View/AddBookmarkSheet.swift`

1. `fetchTask` プロパティを削除
2. `.onChange` モディファイアを削除
3. `saveBookmark()` メソッドを簡素化

```swift
struct AddBookmarkSheet: View {
    @State private var viewModel = AddBookmarkViewModel()
    @FocusState private var isURLFieldFocused: Bool
    // ❌ 削除: @State private var fetchTask: Task<Void, Never>?

    let onSave: (BookmarkData) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            Form {
                // ... 既存のフォーム内容 ...
            }
            .navigationTitle("Add Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBookmark()
                    }
                    .disabled(viewModel.urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
            }
        }
        .onAppear {
            isURLFieldFocused = true
        }
        // ❌ 削除: .onChange(of: viewModel.urlString) { ... }
    }

    // ... 既存のヘルパープロパティ ...

    // ✅ 簡素化
    private func saveBookmark() {
        if let bookmarkData = viewModel.createBookmark() {
            onSave(bookmarkData)
        }
    }
}
```

## 期待される効果

### 1. 責務の明確化
- **View**: UI表示とユーザーインタラクションのみ
- **ViewModel**: ビジネスロジック、状態管理、デバウンス処理

### 2. テスタビリティの向上
- デバウンス処理を含むロジックがViewModelにあるため、単体テストが容易

### 3. コードの可読性向上
- Viewのコード量が削減され、UIロジックに集中できる
- ViewModelが完全な状態管理を担当

## 影響範囲
- `View/AddBookmarkSheet.swift` (修正)
- `Presentation/AddBookmarkViewModel.swift` (修正)
- `ReadItLaterTests/AddBookmarkViewModelTests.swift` (テスト追加推奨)

## 実装後の確認事項
- [ ] URL入力時のデバウンスが正常に動作する
- [ ] タイトル自動取得が引き続き機能する
- [ ] ブックマーク保存が正常に動作する
- [ ] 既存のテストがすべてパスする
- [ ] デバウンス処理の単体テストを追加
