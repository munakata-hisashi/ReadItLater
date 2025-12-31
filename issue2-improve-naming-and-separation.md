# Issue 2: ファイル命名の改善とDTOの分離

## 優先度
🟡 中優先度

## 概要
Domain層のファイル構成と命名を改善し、DTO（Data Transfer Object）を適切に分離することで、コードベースの可読性と保守性を向上させます。

## 現在の問題点

### 1. `Bookmark.swift` の命名が不適切
**ファイル**: `Domain/Bookmark.swift`

```swift
//
//  Bookmark.swift
//  ReadItLater
//
//  Created by 宗像恒 on 2025/08/14.
//

import Foundation

typealias Bookmark = AppV2Schema.Bookmark

extension Bookmark {
    var safeTitle: String {
        title ?? "No title"
    }

    var maybeURL: URL? {
        URL(string: url ?? "")
    }
}
```

**問題**:
- ファイル名が `Bookmark.swift` であるため、完全なモデル定義を期待させる
- 実際の内容は type alias と extension のみ
- 実際のモデル定義は `Migration/VersionedSchema.swift` にある

### 2. `BookmarkCreation.swift` に複数の責務
**ファイル**: `Domain/BookmarkCreation.swift`

```swift
// SwiftDataの制約によりBookmark直接作成は困難なため、中間データ構造を使用
struct BookmarkData: Equatable {
    let url: String
    let title: String
}

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
        // ... 実装 ...
    }
}
```

**問題**:
- `BookmarkData`（DTO）と `Bookmark` の factory メソッドが同じファイルにある
- `BookmarkData` は独立した概念であり、別ファイルに分離すべき

## リファクタリング手順

### ステップ 1: `BookmarkData` を独立ファイルに分離

**新規ファイル**: `Domain/BookmarkData.swift`

```swift
//
//  BookmarkData.swift
//  ReadItLater
//
//  Data Transfer Object for Bookmark creation
//

import Foundation

/// Bookmarkの作成時に使用するデータ転送オブジェクト
///
/// SwiftDataの制約により、Bookmarkモデルを直接作成することが困難なため、
/// 中間データ構造として使用します。
struct BookmarkData: Equatable {
    let url: String
    let title: String

    init(url: String, title: String) {
        self.url = url
        self.title = title
    }
}
```

### ステップ 2: `BookmarkCreation.swift` を更新

**ファイル**: `Domain/BookmarkCreation.swift`

`BookmarkData` の定義を削除し、factory メソッドのみを残す：

```swift
//
//  BookmarkCreation.swift
//  ReadItLater
//
//  Bookmark creation factory and validation logic
//

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

    /// URL文字列とオプショナルなタイトルからBookmarkDataを作成
    ///
    /// - Parameters:
    ///   - urlString: 検証されるURL文字列
    ///   - title: オプショナルなタイトル。空の場合はURLから生成
    /// - Returns: 成功時は `BookmarkData`、失敗時は `CreationError`
    static func create(
        from urlString: String,
        title: String? = nil
    ) -> Result<BookmarkData, CreationError> {
        do {
            let bookmarkURL = try BookmarkURL(urlString)

            // タイトル処理: 提供されたタイトルが空の場合はURLから生成
            let bookmarkTitle: BookmarkTitle
            if let providedTitle = title, !BookmarkTitle(providedTitle).isEmpty {
                bookmarkTitle = BookmarkTitle(providedTitle)
            } else {
                bookmarkTitle = BookmarkTitle.fromURL(bookmarkURL)
            }

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
```

### ステップ 3: `Bookmark.swift` を `BookmarkExtensions.swift` に改名

**手順**:
1. ファイルを改名: `Domain/Bookmark.swift` → `Domain/BookmarkExtensions.swift`
2. ヘッダーコメントを更新

**新ファイル**: `Domain/BookmarkExtensions.swift`

```swift
//
//  BookmarkExtensions.swift
//  ReadItLater
//
//  Type alias and convenience extensions for Bookmark model
//  Actual model definition is in Migration/VersionedSchema.swift
//

import Foundation

/// 現在のスキーマバージョンのBookmarkモデルへのtype alias
/// 実際の定義は `AppV2Schema.Bookmark` を参照
typealias Bookmark = AppV2Schema.Bookmark

extension Bookmark {
    /// タイトルの安全なアクセサ
    /// - Returns: タイトルが存在する場合はその値、存在しない場合は "No title"
    var safeTitle: String {
        title ?? "No title"
    }

    /// URLの安全なアクセサ
    /// - Returns: 有効なURLの場合はURL、無効な場合はnil
    var maybeURL: URL? {
        URL(string: url ?? "")
    }
}
```

### ステップ 4: Xcodeプロジェクトの更新

Xcodeプロジェクトで以下の操作を実行：

1. **ファイル追加**: `Domain/BookmarkData.swift` をプロジェクトに追加
2. **ファイル改名**: `Domain/Bookmark.swift` を `Domain/BookmarkExtensions.swift` に改名
3. **ビルド確認**: プロジェクトが正常にビルドされることを確認

### ステップ 5: インポートの確認

以下のファイルで `BookmarkData` が正しくインポートされていることを確認：

- `Presentation/AddBookmarkViewModel.swift`
- `View/AddBookmarkSheet.swift`
- `View/ContentView.swift`

必要に応じて、明示的なインポート文を追加：

```swift
import Foundation
```

## ディレクトリ構造（変更後）

```
Domain/
├── Bookmark.swift (削除)
├── BookmarkExtensions.swift (新規/改名)
├── BookmarkData.swift (新規)
├── BookmarkCreation.swift (修正)
├── BookmarkTitle.swift
├── BookmarkURL.swift
└── URLValidationError.swift
```

## 期待される効果

### 1. 責務の明確化
- **BookmarkData**: DTO として独立
- **BookmarkExtensions**: type alias と便利メソッド
- **BookmarkCreation**: factory メソッドとバリデーション

### 2. 可読性の向上
- ファイル名が内容を正確に反映
- 実際のモデル定義の場所が明確（VersionedSchema.swift）

### 3. 保守性の向上
- DTO の変更が独立して管理可能
- extension の追加が容易

## 影響範囲
- `Domain/Bookmark.swift` → `Domain/BookmarkExtensions.swift` (改名)
- `Domain/BookmarkData.swift` (新規作成)
- `Domain/BookmarkCreation.swift` (修正)
- Xcodeプロジェクトファイル (ファイル参照の更新)

## 実装後の確認事項
- [ ] すべてのファイルが正しくインポートされている
- [ ] プロジェクトがエラーなくビルドできる
- [ ] 既存のテストがすべてパスする
- [ ] Xcodeプロジェクトのファイル参照が正しい
- [ ] git で改名履歴が正しく追跡される（`git mv` 使用推奨）

## 補足: git での改名方法

```bash
# ファイルの改名を git に記録
git mv ReadItLater/Domain/Bookmark.swift ReadItLater/Domain/BookmarkExtensions.swift

# 新規ファイルの追加
git add ReadItLater/Domain/BookmarkData.swift

# 変更をコミット
git commit -m "refactor: ファイル命名の改善とDTOの分離

- Bookmark.swift を BookmarkExtensions.swift に改名
- BookmarkData を独立したファイルに分離
- BookmarkCreation.swift から BookmarkData の定義を削除"
```
