# CLAUDE.md

このファイルはClaude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## プロジェクト概要

ReadItLaterは、URLを保存してInbox/Bookmarks/Archiveで整理するiOSアプリです。SwiftUIとSwiftDataで構築され、CloudKit同期はエンタイトルメント設定済みです。Share拡張からの保存にも対応しています。サーバーサイド要約や翻訳は計画中です。

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
- すべてのタスクはシミュレータの設定先で明示的に`OS=26.1`を指定して一貫性を保っています

### 直接xcodebuildコマンド
- **シミュレータ用ビルド**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.1' build`
- **汎用ビルド**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater build`（実機ではプロビジョニングの問題で失敗する可能性があります）
- **全テスト実行**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.1' test`
- **UIテスト実行**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.1' test -only-testing:ReadItLaterUITests`
- **ユニットテストのみ実行**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.1' test -only-testing:ReadItLaterTests`

### シミュレータ設定
- **ターゲット**: arm64-apple-ios26.1-simulator
- **デプロイメントターゲット**: iOS 26.1+
- **デフォルトシミュレータ**: iPhone 16 (iOS 26.1)

### ビルドに関する注意事項
- 実機向けビルド時にプロビジョニングプロファイルの問題が発生する可能性があります
- 一貫性のあるビルドのため、特定のシミュレータを設定先として使用してください
- プロジェクトのスキームでCoreData SQLデバッグが有効化されています（`-com.apple.CoreData.SQLDebug 1`）

## アーキテクチャ

### データモデルとマイグレーションシステム
このアプリはSwiftDataマイグレーション用のバージョン管理されたスキーマアーキテクチャを使用しています。

- **現在のスキーマ**: `AppV3Schema`（バージョン3.0.0）`ReadItLater/Migration/VersionedSchema.swift`内
  - `Inbox`、`Bookmark`、`Archive`の3モデル
- **レガシースキーマ**: `AppV1Schema`（Item/Bookmark）、`AppV2Schema`（Bookmarkのみ）
- **型エイリアスと共通プロトコル**: `ReadItLater/Domain/ModelExtensions.swift`で`Inbox`/`Bookmark`/`Archive`の型エイリアスと`URLItem`を定義
- **マイグレーションプラン**: `ReadItLater/Migration/MigrationPlan.swift`に`AppMigrationPlan`を定義（V1〜V3、stagesは空配列）
- **モデルコンテナ**: `ReadItLater/ModelContainerFactory.swift`でApp Groupコンテナを使って生成し、`ReadItLaterApp.swift`と`ShareExtension/ShareViewController.swift`で利用
  - プレビューはin-memoryコンテナを使用

新しいモデルを追加または既存モデルを変更する場合:
1. 新しいバージョンのスキーマを作成（例: `AppV4Schema`）
2. マイグレーションプランを更新して、schemasアレイに新しいスキーマを含める
3. カスタムマイグレーションロジックが必要な場合はマイグレーションステージを追加（それ以外は軽量マイグレーション用に空配列を使用）
4. `ModelExtensions.swift`の型エイリアスと`ModelContainerFactory.swift`のスキーマ配列を更新する

### CloudKit統合
- **コンテナID**: `iCloud.munakata-hisashi.ReadItLater`（エンタイトルメントで定義）
- **サービス**: エンタイトルメントでCloudKitを有効化

### プロジェクト構造
```
ReadItLater/
├── Domain/              # ドメインモデルとバリデーション
│   ├── ModelExtensions.swift     # 型エイリアスとURLItem
│   ├── InboxCreation.swift       # Inbox作成と検証
│   ├── InboxData.swift
│   ├── InboxURL.swift
│   ├── InboxTitle.swift
│   ├── URLValidationError.swift
│   ├── InboxRepositoryProtocol.swift
│   ├── BookmarkRepositoryProtocol.swift
│   ├── ArchiveRepositoryProtocol.swift
│   ├── URLMetadataServiceProtocol.swift
│   ├── ExtensionItemProviderProtocol.swift
│   └── ShareURLUseCaseProtocol.swift
├── UseCase/             # アプリケーションロジック
│   └── ShareURLUseCase.swift
├── Infrastructure/      # SwiftData/サービス実装
│   ├── InboxRepository.swift
│   ├── BookmarkRepository.swift
│   ├── ArchiveRepository.swift
│   ├── ExtensionItemProvider.swift
│   └── URLMetadataService.swift
├── Presentation/        # ViewModel
│   └── AddInboxViewModel.swift
├── View/                # SwiftUIビュー
│   ├── MainTabView.swift
│   ├── InboxListView.swift
│   ├── BookmarkListView.swift
│   ├── ArchiveListView.swift
│   ├── AddInboxSheet.swift
│   ├── URLItemRow.swift
│   ├── URLItemDetailView.swift
│   └── WebView.swift
├── Migration/           # SwiftDataスキーマバージョニング
│   ├── VersionedSchema.swift
│   └── MigrationPlan.swift
├── ModelContainerFactory.swift
└── ReadItLaterApp.swift
ShareExtension/
└── ShareViewController.swift
```

### UI構造
- **ナビゲーション**: `TabView` + 各タブ内の`NavigationStack`構成
- **MainTabView**: Inbox/Bookmarks/Archiveの3タブ
- **InboxListView**: URL一覧と追加シート（`AddInboxSheet`）を提供
- **BookmarkListView / ArchiveListView**: 保存済みURLの一覧と詳細遷移を提供
- **URLItemDetailView**: `URLItem`共通の詳細表示（WebView/タイトル表示）

## 計画中の機能
README.mdに基づく未実装項目は以下です:
- サーバーサイド処理によるWebコンテンツの要約
- 保存したコンテンツの翻訳サービス

## 開発に関する注意事項
- アプリはサンドボックスエンタイトルメント付きでiOSをターゲットにしています
- バックグラウンド処理用にリモート通知が設定されています
- ユニットテストはSwift Testing（`ReadItLaterTests`）、UIテストはXCTest（`ReadItLaterUITests`）を使用します
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
