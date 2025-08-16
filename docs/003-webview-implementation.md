# WebView機能実装ドキュメント

## 概要

ブックマークしたページをアプリ内で閲覧できる機能を実装。WKWebViewを使用してネイティブなWebブラウジング体験を提供。

## 実装内容

### 1. WebViewコンポーネントの作成

#### ファイル: `ReadItLater/View/WebView.swift`

```swift
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
```

**特徴:**
- `UIViewRepresentable`を使用してWKWebViewをSwiftUIで利用可能にする
- URLを受け取り、自動的にページを読み込む
- シンプルで再利用可能な設計

### 2. BookmarkViewの改修

#### 変更点: `ReadItLater/View/BookmarkView.swift`

**変更前:**
```swift
var body: some View {
    VStack {
        Text(bookmark.safeTitle)
        Text(bookmark.maybeURL?.absoluteString ?? "No URL")
    }
}
```

**変更後:**
```swift
var body: some View {
    VStack {
        if let url = bookmark.maybeURL {
            WebView(url: url)
        } else {
            VStack {
                Text(bookmark.safeTitle)
                Text("No URL")
            }
        }
    }
    .navigationTitle(bookmark.safeTitle)
    .navigationBarTitleDisplayMode(.inline)
}
```

**改善点:**
- 有効なURLがある場合、WebViewでページ表示
- URLが無効な場合、従来のテキスト表示にフォールバック
- 条件分岐による適切なエラーハンドリング

### 3. プロジェクト構成の整理

#### ディレクトリ構造の改善

```
ReadItLater/
├── View/                    # 新規作成
│   ├── WebView.swift       # 新規追加
│   ├── BookmarkView.swift  # 移動
│   ├── ContentView.swift   # 移動
│   └── AddBookmarkSheet.swift # 移動
├── Domain/
├── Presentation/
└── Migration/
```

**変更内容:**
- すべてのSwiftUIビューファイルを`View/`ディレクトリに集約
- プロジェクトの可読性とメンテナンス性を向上
- レイヤー別のファイル組織化を強化

## 技術的選択理由

### WKWebViewの採用理由

1. **将来拡張性**: 要約・翻訳機能実装時のJavaScript実行が容易
2. **パフォーマンス**: ネイティブSafariエンジンによる高性能
3. **セキュリティ**: 標準的なWebセキュリティ機能を内蔵
4. **統合性**: SwiftUIとの自然な統合

### UIViewRepresentableパターン

- SwiftUIとUIKitの橋渡し
- 宣言的UIでの命令的コンポーネント利用
- 既存UIKitライブラリの活用

## 実装フロー

1. **ブランチ作成**: `feature/webview-display`
2. **WebViewコンポーネント実装**
   - WKWebViewのSwiftUIラッパー作成
   - URLロード機能実装
3. **BookmarkView統合**
   - 条件分岐によるWebView表示
   - エラーハンドリング実装
4. **ビルド検証**: iPhone 15シミュレーターでテスト
5. **プロジェクト整理**: Viewファイルのディレクトリ集約

## 今後の拡張計画

### Phase 2: コンテンツ抽出
- JavaScript実行によるDOM操作
- 記事テキストの抽出機能
- 要約API連携準備

### Phase 3: 翻訳機能
- 多言語サポート
- リアルタイム翻訳表示
- 原文・翻訳文の切り替え

### Phase 4: オフライン対応
- コンテンツキャッシュ機能
- オフライン閲覧サポート
- ストレージ管理

## 使用方法

1. **ブックマーク一覧画面**でブックマークをタップ
2. **BookmarkView**が開く
3. 有効なURLの場合、**WebView**でページが表示される
4. **ナビゲーションタイトル**にブックマークタイトルが表示

## 関連ファイル

- `ReadItLater/View/WebView.swift` - WebViewコンポーネント
- `ReadItLater/View/BookmarkView.swift` - ブックマーク詳細ビュー
- `ReadItLater/Domain/Bookmark.swift` - ブックマークドメインモデル

## Git履歴

- `3a21561`: feat: WebViewを使用したブックマークページ閲覧機能を追加
- `6c95055`: refactor: ViewファイルをViewディレクトリに整理