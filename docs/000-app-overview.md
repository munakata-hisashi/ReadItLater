# ReadItLater アプリ概要

## 目的
ReadItLaterは、あとで読みたいWebページのURLを保存し、後から一覧・詳細閲覧できるiOSアプリです。将来的には要約・翻訳などの拡張も想定されています（README記載）。

## 現在の主な機能（実装済み）
- アプリ内でURLを入力して保存（タイトルは任意）
- URLのバリデーション（http/httpsのみ、空・不正形式はエラー）
- タイトル自動取得（LinkPresentationによるページタイトルの取得）
- ブックマーク一覧表示と削除
- ブックマーク詳細でWebView表示
- Safari共有シートからの保存（Share Extension）
  - 共有されたURLをInboxに追加
  - タイトルがない場合はメタデータ取得を試行
  - Inboxが上限に達した場合はエラー表示

## 画面構成（現状）
- `ContentView`: ブックマーク一覧と追加シートの起動
- `AddBookmarkSheet`: URL/タイトル入力、エラー表示、保存
- `BookmarkView`: WebViewでページ表示（URL不正時はテキスト表示）

## データモデルと永続化
- SwiftData + CloudKitを利用
- App Groupsの共有ストアを使用し、メインアプリとShare Extensionで同じデータベースを参照
- スキーマはバージョン管理され、現行はAppV3Schema
  - `Inbox` / `Bookmark` / `Archive` の3モデルを定義
  - 既存データは軽量マイグレーションで移行

## アーキテクチャ
- Domain層
  - Value Object: `BookmarkURL`, `BookmarkTitle`
  - ファクトリ: `Bookmark.create(from:title:)`
  - DTO: `BookmarkData`
  - バリデーションエラー: `URLValidationError`
- Presentation層
  - `AddBookmarkViewModel`: 入力状態、バリデーション、メタデータ取得、エラー制御
- Infrastructure層
  - `BookmarkRepository` / `InboxRepository`: 永続化操作
  - `URLMetadataService`: LinkPresentationのラッパー
  - `ModelContainerFactory`: App Group対応のModelContainer生成
- View層
  - `ContentView`, `AddBookmarkSheet`, `BookmarkView`, `WebView`

## Share Extensionの保存フロー
1. 共有シートからURLとタイトル（あれば）を取得
2. タイトルがない場合はメタデータ取得を試行
3. `Bookmark.create`でURL検証とタイトル正規化
4. Inboxの上限を確認し、保存

## 既存ドキュメントで示される今後の拡張
- Inbox/Bookmark/Archiveの3タブUI実装（docs/009）
- 状態移動ロジックの拡充とテスト（docs/008）
- Inbox上限や整理のUX強化（docs/006, docs/007）
- タイトル自動取得の強化やUI改善（docs/004）
- 共有機能の拡張とShare Extensionの整備（docs/005）
- ドメイン駆動の整理（docs/001, docs/002, docs/issues/*）

## 関連ファイル
- アプリエントリ: `ReadItLater/ReadItLaterApp.swift`
- UI: `ReadItLater/View/ContentView.swift`, `ReadItLater/View/AddBookmarkSheet.swift`, `ReadItLater/View/BookmarkView.swift`
- Share Extension: `ShareExtension/ShareViewController.swift`
- ドメイン/アーキテクチャ: `ReadItLater/Domain/*`, `ReadItLater/Presentation/*`, `ReadItLater/Infrastructure/*`, `ReadItLater/Migration/*`
