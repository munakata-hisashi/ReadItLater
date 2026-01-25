# CLAUDE.md

このファイルはClaude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## プロジェクト概要

ReadItLaterは、URL をブックマークするiOSアプリで、AI駆動のコンテンツ要約と翻訳機能を計画しています。SwiftUIとSwiftDataで構築され、CloudKit同期によりデバイス間でのアクセスが可能です。

## 開発コマンド

### miseタスク（推奨）
このプロジェクトは[mise](https://mise.jdx.dev/)をタスク自動化に使用しています。すべてのコマンドは`mise.toml`に定義されており、ローカル開発とCIの両方でSingle Source of Truthとして機能します。

**開発タスク:**
- **整形出力でビルド**: `mise run buildformat` または `mise run b`
- **整形出力で全テスト実行**: `mise run testformat` または `mise run t`
- **ユニットテストのみ実行**: `mise run unit` または `mise run u`
- **ビルド（生出力）**: `mise run build`
- **テスト実行（生出力）**: `mise run test`

**CIタスク（GitHub Actionsで使用）:**
- **CIビルド**: `mise run ci-build`
- **CIテスト**: `mise run ci-test`

**重要な注意事項:**
- 整形ビルドタスクは`SWIFT_TREAT_WARNINGS_AS_ERRORS=YES GCC_TREAT_WARNINGS_AS_ERRORS=YES`を使用し、警告があるとビルドが失敗します
- テストタスクは`build-for-testing` + `test-without-building`パターンを使用して高速化しています
- 並列テストは無効化されています（`-parallel-testing-enabled NO`）。これは競合状態を回避するためです
- CIタスクは`--renderer github-actions`を使用してGitHub Actionsで適切な出力形式を生成します
- すべてのタスクはシミュレータの設定先で明示的に`OS=26.0.1`を指定して一貫性を保っています

### 直接xcodebuildコマンド
- **シミュレータ用ビルド**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' build`
- **汎用ビルド**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater build`（実機ではプロビジョニングの問題で失敗する可能性があります）
- **全テスト実行**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' test`
- **UIテスト実行**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' test -only-testing:ReadItLaterUITests`
- **ユニットテストのみ実行**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' test -only-testing:ReadItLaterTests`

### シミュレータ設定
- **ターゲット**: arm64-apple-ios26.0.1-simulator
- **デプロイメントターゲット**: iOS 26.0.1+
- **デフォルトシミュレータ**: iPhone 16 (iOS 26.0.1)

### ビルドに関する注意事項
- 実機向けビルド時にプロビジョニングプロファイルの問題が発生する可能性があります
- 一貫性のあるビルドのため、特定のシミュレータを設定先として使用してください
- プロジェクトのスキームでCoreData SQLデバッグが有効化されています（`-com.apple.CoreData.SQLDebug 1`）

## アーキテクチャ

### データモデルとマイグレーションシステム
このアプリはSwiftDataマイグレーション用のバージョン管理されたスキーマアーキテクチャを使用しています。

- **現在のスキーマ**: `AppV2Schema`（バージョン2.0.0）`Migration/VersionedSchema.swift`内
  - `Bookmark`: id、createdAt、url、titleを持つ主要モデル
  - `Item`モデルは現在使用されていません
- **レガシースキーマ**: `AppV1Schema`（バージョン1.0.0）マイグレーション履歴のために保持
  - `Item`と`Bookmark`の両モデルを含みます
- **型エイリアス**: `Domain/BookmarkExtensions.swift`で`typealias Bookmark = AppV2Schema.Bookmark`を定義
- **マイグレーションプラン**: `Migration/MigrationPlan.swift`に`AppMigrationPlan`を含む
  - `AppV1Schema`と`AppV2Schema`の両方を含みます
  - 軽量マイグレーションを使用（stagesは空配列 - SwiftDataが自動処理）
- **モデルコンテナ**: `ReadItLaterApp.swift:14-51`でマイグレーションプラン統合と共に設定
  - スキーマは`Bookmark.self`のみを含みます

新しいモデルを追加または既存モデルを変更する場合:
1. 新しいバージョンのスキーマを作成（例: `AppV3Schema`）
2. マイグレーションプランを更新して、schemasアレイに新しいスキーマを含める
3. カスタムマイグレーションロジックが必要な場合はマイグレーションステージを追加（それ以外は軽量マイグレーション用に空配列を使用）
4. 型エイリアスを更新して新しいスキーマバージョンを指すようにする

### CloudKit統合
- **コンテナID**: `iCloud.munakata-hisashi.ReadItLater`（エンタイトルメントで定義）
- **サービス**: データ同期のためエンタイトルメントでCloudKitを有効化
- **設定**: アプリ初期化時にCloudKit同期用のModelContainerを設定
- **デバッグ**: `ReadItLaterApp.swift:22-46`にコメントアウトされたCloudKitスキーマ初期化コードがあります

### プロジェクト構造
```
ReadItLater/
├── Domain/              # ドメインモデルと値オブジェクト
│   ├── BookmarkExtensions.swift  # 型エイリアスと拡張
│   ├── BookmarkData.swift        # ブックマーク作成用DTO
│   ├── BookmarkCreation.swift    # ファクトリメソッド
│   ├── BookmarkURL.swift
│   └── BookmarkTitle.swift
├── Migration/           # SwiftDataスキーマバージョニング
│   ├── VersionedSchema.swift
│   └── MigrationPlan.swift
├── Presentation/        # ViewModelとプレゼンテーションロジック
│   └── AddBookmarkViewModel.swift
└── View/               # SwiftUIビュー
    ├── ContentView.swift
    ├── BookmarkView.swift
    └── AddBookmarkSheet.swift
```

### UI構造
- **ナビゲーション**: マスター・ディテールレイアウトの`NavigationSplitView`パターンを使用
- **ContentView**: ブックマークのCRUD操作を含むマスターリスト
- **BookmarkView**: 個別のブックマーク表示用ディテールビュー
- **AddBookmarkSheet**: 新しいブックマーク追加用のモーダルシート
- **拡張**: `Domain/BookmarkExtensions.swift`でオプショナルプロパティ用の安全なアクセサ（`safeTitle`、`maybeURL`）を定義

## 計画中の機能
README.mdに基づき、アプリは以下の機能を追加予定です:
- サーバーサイド処理によるWebコンテンツの要約
- 保存したコンテンツの翻訳サービス
- URL取得用のSafari共有拡張
- コンテンツ閲覧と管理の強化

## 開発に関する注意事項
- アプリはサンドボックスエンタイトルメント付きでiOSをターゲットにしています
- バックグラウンド処理用にリモート通知が設定されています
- テストターゲットにはユニットテスト（`ReadItLaterTests`）とUIテスト（`ReadItLaterUITests`）の両方が含まれています
- プレビュー設定はSwiftUIプレビュー用にインメモリのモデルコンテナを使用します

## Git Workflow Guidelines

### Branch Management
- **作業ブランチの作成**: Swiftコードの実装作業を開始する前に、必ず作業用ブランチを作成する
- **ブランチ命名規則**:
  - 機能追加: `feature/機能名` または `feature/issue番号-機能名`
  - バグ修正: `fix/バグ内容` または `fix/issue番号-バグ内容`
  - リファクタリング: `refactor/対象範囲`
- **作業の流れ**:
  1. `git checkout -b ブランチ名` で作業ブランチを作成
  2. 実装とテストを実施
  3. コミット作成
  4. プルリクエストを作成してレビュー

### Commit Message Guidelines
- **Language**: Write commit messages in Japanese
- **Format**: Follow conventional commit style with descriptive Japanese messages
- **Structure**:
  - Short summary line in Japanese
  - Detailed bullet points for changes
  - Include Claude Code attribution footer

## GitHub操作ガイドライン

### ツール選択: GitHub MCP vs gh CLI

**書き込み操作には`gh` CLIを使用（推奨）:**
- PR作成/編集: `gh pr create`、`gh pr edit`
- Issue作成/編集: `gh issue create`、`gh issue edit`
- コメント追加: `gh pr comment`、`gh issue comment`
- PRマージ: `gh pr merge`
- レビューリクエスト: `gh pr review`

**読み取り操作にはGitHub MCPを使用:**
- PR詳細取得: `mcp__github__pull_request_read`
- Issue/PR検索: `mcp__github__search_issues`、`mcp__github__search_pull_requests`
- コミット情報取得: `mcp__github__get_commit`、`mcp__github__list_commits`
- コード検索: `mcp__github__search_code`

**理由:**
- `gh` CLIはユーザー認証を使用し、より広い権限を持ちます
- GitHub MCPはPAT制限により書き込み操作で403エラーが発生する可能性があります
- GitHub MCPは構造化されたJSONデータを返すため、複雑なクエリに適しています
- 書き込み操作では常に`gh`を最初に試し、利用できない場合のみMCPにフォールバックします