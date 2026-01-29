# Issue 4: classをstructに変換してバリューセマンティクスを活用

## 優先度
🟡 中優先度

## 概要
現在classで定義されているが、参照セマンティクスを必要としない型をstructに変換します。structはバリューセマンティクスを持ち、コピーオンライトによるメモリ効率の向上、スレッドセーフティの向上、Swiftの慣用的なコードスタイルへの準拠が期待できます。

## 現在の問題点

### 1. 不要な参照セマンティクス
以下のclassは状態変更を行わず、参照の同一性も不要であるため、structで十分です：

**変換対象（本番コード）**:
- `ShareURLUseCase` (`ReadItLater/UseCase/ShareURLUseCase.swift`)
- `InboxRepository` (`ReadItLater/Infrastructure/InboxRepository.swift`)
- `BookmarkRepository` (`ReadItLater/Infrastructure/BookmarkRepository.swift`)
- `ArchiveRepository` (`ReadItLater/Infrastructure/ArchiveRepository.swift`)

**変換対象（テストコード）**:
- `MockURLMetadataService` (`ReadItLaterTests/Mocks/MockURLMetadataService.swift`)
- `MockExtensionItemProvider` (`ReadItLaterTests/Mocks/MockExtensionItemProvider.swift`)

### 2. 変換不可なclass
以下のclassは参照セマンティクスが必要なため変換対象外です：

| class名 | 理由 |
|---------|------|
| **AddInboxViewModel** | `@Observable`マクロはclassでのみ使用可能 |
| **URLMetadataService** | `currentProvider`を非同期メソッド内で変更 |
| **ExtensionItemProvider** | `weak var`を使用（structでは不可） |
| **ShareViewController** | `UIViewController`を継承 |
| **MockInboxRepository** | 呼び出し状態を記録するため参照セマンティクスが必要 |
| **UIテスト** | `XCTestCase`の継承が必要 |

## リファクタリング手順

### ステップ 1: ShareURLUseCaseをstructに変換

**ファイル**: `ReadItLater/UseCase/ShareURLUseCase.swift`

```swift
// Before
final class ShareURLUseCase: ShareURLUseCaseProtocol {
    private let repository: any InboxRepositoryProtocol
    private let itemProvider: any ExtensionItemProviderProtocol
    private let metadataService: any URLMetadataServiceProtocol

    init(
        repository: any InboxRepositoryProtocol,
        itemProvider: any ExtensionItemProviderProtocol,
        metadataService: any URLMetadataServiceProtocol
    ) {
        self.repository = repository
        self.itemProvider = itemProvider
        self.metadataService = metadataService
    }

    // ... メソッド ...
}

// After
struct ShareURLUseCase: ShareURLUseCaseProtocol {
    private let repository: any InboxRepositoryProtocol
    private let itemProvider: any ExtensionItemProviderProtocol
    private let metadataService: any URLMetadataServiceProtocol

    init(
        repository: any InboxRepositoryProtocol,
        itemProvider: any ExtensionItemProviderProtocol,
        metadataService: any URLMetadataServiceProtocol
    ) {
        self.repository = repository
        self.itemProvider = itemProvider
        self.metadataService = metadataService
    }

    // ... メソッド（変更なし）...
}
```

**変更点**:
- `final class` を `struct` に変更
- ロジックは一切変更なし

### ステップ 2: Repository層をstructに変換

**ファイル**: `ReadItLater/Infrastructure/InboxRepository.swift`

```swift
// Before
final class InboxRepository: InboxRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // ... メソッド ...
}

// After
struct InboxRepository: InboxRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // ... メソッド（変更なし）...
}
```

**変更点**:
- `final class` を `struct` に変更
- `ModelContext`は参照型だが、Repository自身は状態変更しないためstructで問題なし

**同様の変更を以下にも適用**:
- `ReadItLater/Infrastructure/BookmarkRepository.swift`
- `ReadItLater/Infrastructure/ArchiveRepository.swift`

### ステップ 3: テストのMockをstructに変換

**ファイル**: `ReadItLaterTests/Mocks/MockURLMetadataService.swift`

```swift
// Before
final class MockURLMetadataService: URLMetadataServiceProtocol {
    var metadataToReturn: LPLinkMetadata?
    var errorToThrow: Error?

    // ... メソッド ...
}

// After
struct MockURLMetadataService: URLMetadataServiceProtocol {
    var metadataToReturn: LPLinkMetadata?
    var errorToThrow: Error?

    // ... メソッド（変更なし）...
}
```

**変更点**:
- `final class` を `struct` に変更
- テストでモック設定が必要な場合は `var mock` として保持する

**同様の変更を以下にも適用**:
- `ReadItLaterTests/Mocks/MockExtensionItemProvider.swift`

### ステップ 4: 使用箇所の確認と必要に応じた修正

struct変換後、以下の点を確認：

1. **初期化方法**: structはletで宣言してもプロパティアクセス可能
2. **テストコード**: モックがvarで宣言されているか確認
3. **プロトコル適合**: 変更なし（structもプロトコルに適合可能）

**確認が必要なファイル**:
- `ShareExtension/ShareViewController.swift` (ShareURLUseCaseの使用)
- 各Viewファイル (Repository の使用)
- テストファイル (Mockの使用)

## 期待される効果

### 1. パフォーマンスの向上
- structは値型のため、スタック上に配置される（小さい構造体の場合）
- コピーオンライトによるメモリ効率の向上

### 2. スレッドセーフティの向上
- 値型のため、複数スレッド間での共有時にデータ競合のリスクが低減
- 各スレッドが独立したコピーを持つ

### 3. Swiftの慣用的なコードスタイル
- Swiftでは状態を持たない型やバリューセマンティクスが望ましい型にはstructを使用するのが推奨
- Apple の公式ガイドラインに準拠

### 4. コードの意図の明確化
- classからstructへの変更により、「参照の同一性が不要」であることが明示される
- コードレビュー時の理解が容易になる

## 影響範囲

### 本番コード
- `ReadItLater/UseCase/ShareURLUseCase.swift` (修正)
- `ReadItLater/Infrastructure/InboxRepository.swift` (修正)
- `ReadItLater/Infrastructure/BookmarkRepository.swift` (修正)
- `ReadItLater/Infrastructure/ArchiveRepository.swift` (修正)

### テストコード
- `ReadItLaterTests/Mocks/MockURLMetadataService.swift` (修正)
- `ReadItLaterTests/Mocks/MockExtensionItemProvider.swift` (修正)
- 各テストファイル（モックの使用箇所を確認）

### 使用箇所（確認のみ）
- `ShareExtension/ShareViewController.swift`
- 各Viewファイル
- 各テストファイル

## 実装後の確認事項
- [ ] すべてのファイルがエラーなくビルドできる
- [ ] 既存のユニットテストがすべてパスする
- [ ] UIテストがすべてパスする
- [ ] Share Extension が正常に動作する
- [ ] Inbox/Bookmark/Archive の追加・削除・移動が正常に動作する
- [ ] メモリ使用量に変化がないか確認（期待: 若干の改善）

## 技術的背景

### structとclassの違い

| 特性 | struct | class |
|------|--------|-------|
| **セマンティクス** | 値型（コピー） | 参照型（共有） |
| **継承** | 不可 | 可能 |
| **メモリ管理** | スタック（小さい場合） | ヒープ |
| **スレッドセーフティ** | 高い | 低い（ロック必要） |
| **パフォーマンス** | 一般的に高速 | 参照カウント管理が必要 |

### Swiftの設計思想
Appleの公式ガイドラインでは、以下の場合にstructを使用することを推奨：
- 主な目的がシンプルなデータの格納である
- インスタンスの同一性よりも値の等価性が重要
- プロパティ自体も値型である
- 継承を必要としない

今回の変換対象はすべてこの条件に該当します。

## 参考資料
- [Swift Programming Language - Structures and Classes](https://docs.swift.org/swift-book/LanguageGuide/ClassesAndStructures.html)
- [WWDC 2015 - Protocol-Oriented Programming in Swift](https://developer.apple.com/videos/play/wwdc2015/408/)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
