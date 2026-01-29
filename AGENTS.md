# リポジトリガイドライン

## プロジェクト構成とモジュール編成
ReadItLaterはSwiftUIとSwiftDataで構築されたiOSアプリです。中核のソースは`ReadItLater/`配下にあり、`ReadItLater/Domain`（ドメインモデルとバリデーション）、`ReadItLater/UseCase`（アプリケーションロジック）、`ReadItLater/Infrastructure`（SwiftData/サービス実装）、`ReadItLater/Presentation`（ViewModel）、`ReadItLater/View`（SwiftUIビュー）のレイヤーで構成されています。SwiftDataのマイグレーションロジックは`ReadItLater/Migration`にあり、アセットは`ReadItLater/Assets.xcassets`にあります。テストは`ReadItLaterTests/`（ユニット）と`ReadItLaterUITests/`（UI）にあります。Share拡張のコードは`ShareExtension/`にあります。

## ディレクトリ別の配置ルール
- `ReadItLater/Domain`: ドメインモデル、値オブジェクト、バリデーション、リポジトリ/サービスのプロトコル定義。SwiftUIやSwiftDataの具体実装は置かない。
- `ReadItLater/UseCase`: ユースケース（アプリケーションロジック）。Domainとプロトコルに依存し、Infrastructureの具体実装には依存しない。
- `ReadItLater/Infrastructure`: SwiftDataリポジトリや外部サービスなどの具体実装。Domainのプロトコルに適合させ、UIに依存しない。
- `ReadItLater/Presentation`: ViewModelや画面状態の管理。UseCaseを呼び出し、Viewとは分離する（SwiftUI Viewは置かない）。
- `ReadItLater/View`: SwiftUIビューのみ。表示とユーザー入力に集中し、ビジネスロジックはViewModel/UseCaseへ委譲する。
- `ReadItLater/Migration`: SwiftDataスキーマ定義とマイグレーションプラン。既存スキーマを直接編集せず、新しいバージョン型を追加する。
- `ReadItLater/Assets.xcassets`: 画像・色などのアセットのみ。
- `ReadItLater/ReadItLaterApp.swift`/`ReadItLater/ModelContainerFactory.swift`: アプリ起動時のDIやModelContainer生成など、アプリ全体の初期化コード。
- `ShareExtension/`: Share拡張の受け取り処理とUI。共有コンテナを使った保存処理はここに置く。
- `ReadItLaterTests/`: Swift Testingによるユニットテスト（Domain/UseCase/Infrastructure/Presentationの検証）。
- `ReadItLaterUITests/`: XCTestによるUIテスト。
- `docs/`: 設計メモ、仕様、Issue関連資料。

## ビルド、テスト、開発コマンド
出力を揃えるためにmiseタスクを使用します。
- `mise run buildformat`（エイリアス`mise run b`）は`xcbeautify`で整形してビルドします。
- `mise run testformat`（エイリアス`mise run t`）は整形されたログで全テストを実行します。
- `mise run unit`（エイリアス`mise run u`）はユニットテストのみを実行します。
直接コマンドも利用できます。例: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' build`。

## コーディングスタイルと命名規約
標準的なSwiftの規約に従います。インデントは4スペース、型は`UpperCamelCase`、プロパティと関数は`lowerCamelCase`です。ファイル名と型名は対応させてください（例: `InboxURL.swift`は`InboxURL`を定義）。SwiftDataのスキーマバージョンは`ReadItLater/Migration/VersionedSchema.swift`にあり、その場で編集するのではなく新しいスキーマ型を追加してインクリメントします。自動フォーマッタやリンタは設定されていないため、差分は整然と一貫性を保ってください。
Inbox作成やURL検証では、モデルを直接構築するのではなく`ReadItLater/Domain/InboxCreation.swift`の`Inbox.create(from:title:)`ファクトリを優先してください。

## アーキテクチャとデータ
SwiftDataは`ReadItLater/Migration/MigrationPlan.swift`のバージョン付きスキーマ計画を使用します。現在のスキーマは`AppV3Schema`で、`Inbox`、`Bookmark`、`Archive`モデルを定義しています。新しいスキーマを導入する際はマイグレーション計画を更新してください。共有永続化は`ReadItLater/ModelContainerFactory.swift`でApp Groupコンテナ`group.munakata-hisashi.ReadItLater`を使って作成され、プレビューはインメモリコンテナを使用します。Share拡張は同じ共有コンテナを使って受け取ったURLを保存します。

## テストガイドライン
ユニットテストはSwift Testing（`import Testing`）を使用し、`ReadItLaterTests/`にあります。UIテストはXCTestで`ReadItLaterUITests/`にあります。テストメソッドは既存の命名パターンに従ってください（例: `ReadItLaterTests/Domain/InboxCreationTests.swift`の`@Test func 空URL_作成失敗()`）。全テストは`mise run testformat`、特定ターゲットのテストは`xcodebuild ... -only-testing:ReadItLaterTests`で実行します。

## コミットとPRガイドライン
コミットメッセージは日本語で、Conventional Commits風のスタイルに従います。短い要約行を付け、詳細は箇条書きで記載してください。PRでは挙動の変更点を明確に説明し、`docs/`内の関連Issueやドキュメントへリンクし、UI変更がある場合はスクリーンショットを含めてください。

## セキュリティと構成の注意点
CloudKitは`ReadItLater/ReadItLater.entitlements`で`iCloud.munakata-hisashi.ReadItLater`コンテナを使って有効化されています。エンタイトルメントやCloudKitの挙動を調整する場合は、まずシミュレータビルドで検証し、Xcodeによるデバイス固有のプロビジョニング変更をコミットしないでください。
