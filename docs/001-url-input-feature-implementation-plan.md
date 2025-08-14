# URL入力機能実装計画

## 概要
ReadItLaterアプリにユーザーからURLを受け取って、Bookmarkオブジェクトとして保存する機能を追加する。

## 現在の状態分析

### 既存コードベース
- **Bookmarkモデル** (`VersionedSchema.swift:28-39`)
  - `url: String?`、`title: String?`、`createdAt: Date`
  - 既にURL保存の基盤は整備済み
- **ContentView** (`ContentView.swift:45-50`)
  - ハードコードされたURL("https://example.com")でのブックマーク作成
  - SwiftDataによるCRUD操作実装済み
- **データ基盤**
  - SwiftDataのバージョンシステム対応
  - CloudKit同期設定済み

### 問題点
- ユーザーからのURL入力機能が存在しない
- `addBookmark()`関数が固定URLのみ対応

## 実装設計

### 1. UI設計方針
**採用アプローチ：Sheet/Modal方式**
- 現在の「+」ボタンタップでURL入力シートを表示
- iOS設計パターンに準拠したユーザビリティ重視

### 2. 新規作成コンポーネント

#### AddBookmarkSheet.swift
```swift
struct AddBookmarkSheet: View {
    @State private var urlText: String = ""
    @State private var title: String = ""
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    
    var onSave: (String, String) -> Void
    var onCancel: () -> Void
    
    // URL入力フォーム、バリデーション、保存/キャンセル処理
}
```

### 3. 修正対象ファイル

#### ContentView.swift
- **修正箇所**: `addBookmark()`関数 (行45-50)
- **追加要素**: 
  - `@State private var showingAddSheet = false`
  - シート表示制御
  - URL/タイトル受け取り処理

### 4. 機能仕様

#### 必須機能
- [x] URLテキスト入力フィールド
- [x] 基本的なURL形式検証
- [x] Bookmarkオブジェクト作成・保存
- [x] エラーハンドリング

#### 追加機能（Phase 2）
- [ ] タイトル自動取得（Web scraping）
- [ ] リアルタイム入力バリデーション
- [ ] URL正規化（http://→https://変換など）
- [ ] 重複URL検出

### 5. 実装手順

1. **AddBookmarkSheet.swift作成**
   - URL入力用SwiftUIビュー
   - バリデーションロジック
   - エラー表示機能

2. **URL検証ロジック実装**
   - `URL(string:)`を使用した基本検証
   - プロトコル確認（http/https）
   - エラーメッセージ定義

3. **ContentView.swift修正**
   - `addBookmark()`関数の引数対応
   - シート表示状態管理
   - ユーザー入力データの処理

4. **統合テスト**
   - 各種URL形式での動作確認
   - エラーケースのテスト
   - UX確認

### 6. テストケース

#### 正常系
- `https://example.com` - 標準的なURL
- `http://test.com` - HTTPプロトコル
- `https://subdomain.example.com/path?query=value` - 複雑なURL

#### 異常系
- `invalid-url` - 無効な形式
- `ftp://example.com` - 非対応プロトコル
- 空文字列入力

## 技術的考慮事項

### データモデル
- 現在の`Bookmark`モデル構造を維持
- 追加のマイグレーションは不要

### パフォーマンス
- URL検証は軽量な`URL(string:)`を使用
- Web scraping機能は将来的にバックグラウンド処理で実装

### セキュリティ
- URL検証によるインジェクション対策
- 信頼できないURLへのアクセス制限

## 将来の拡張計画
- Safari Share Extension連携
- Web content summarization
- Translation services
- Bulk URL import機能