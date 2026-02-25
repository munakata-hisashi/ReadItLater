# ReadItLater デザイン洗練計画

## 1. 目的
- `docs/design/design-system-research.md` の知見を、ReadItLaterの現実的な実装順に落とし込む。
- 「ポップで親しみやすい」方向性を維持しつつ、可読性・操作性・保守性を同時に改善する。
- 既存のレイヤー分離（Domain / UseCase / Infrastructure / Presentation / View）を壊さず、`View`中心の変更で進める。

## 2. 現状整理（2026-02-25時点）
- 一覧画面（Inbox / Bookmark / Archive）は `List` + `URLItemRow` の標準UI。
- ナビゲーションは `MainTabView.swift` の標準 `TabView`。
- 視覚トークン（色・フォント・余白・角丸）の共通定義が未整備。
- 空状態の専用UIがなく、初回体験の印象を作りにくい。
- スワイプアクションは実装済みで、機能要件として維持が必要。

## 3. デザイン方針
- **Warm & Clear**: 暖色系アクセントで親しみやすく、情報構造は明瞭にする。
- **Token First**: 先に色・フォント・余白のトークンを定義し、画面への適用は段階的に行う。
- **Small Safe Steps**: 既存操作（スワイプ、検索、遷移）を壊さない順番で進める。
- **Accessibility by Default**: Dynamic Type、コントラスト、Reduce Motionに最初から対応する。

## 4. 実装ロードマップ

### Phase 0: ベースライン確立（0.5日）
**目的**
- 改善前後を比較できる状態を作る。

**作業**
- Light / Dark の主要画面スクリーンショットを保存（Inbox/Bookmark/Archive/詳細/追加シート）。
- Dynamic Type（標準、アクセシビリティサイズ）で崩れを確認。
- 現状課題を短く記録（例: 階層が弱い、CTAが埋もれる）。

**完了条件**
- 比較用素材が `docs/design/` に揃っている。

### Phase 1: デザイントークン導入（1日）
**目的**
- 全画面で再利用できる色・タイポ・スペーシングの基礎を作る。

**作業**
- `Assets.xcassets` にセマンティックカラー（例: `BrandPrimary`, `CardBackground`, `TextSecondary`）を追加。
- `ReadItLater/View` 配下にトークンファイルを追加:
  - `AppColor.swift`（Color拡張）
  - `AppFont.swift`（.roundedベースのフォント定義）
  - `AppSpacing.swift`（余白・角丸）
- まずはナビゲーションタイトル、主要ラベル、タブの`tint`に適用。

**完了条件**
- ハードコード色が減り、主要画面でトークン参照に置き換わっている。

### Phase 2: リスト行をカード化（1.5日）
**目的**
- もっとも接触頻度の高い一覧UIを製品らしくする。

**作業**
- `URLItemRow.swift` をカード表現へ更新（角丸16pt、内部余白、補助情報の階層化）。
- `List`は維持し、`listRowBackground(.clear)` / `listRowSeparator(.hidden)` を使ってカード見た目へ寄せる。
- `InboxListView.swift` / `BookmarkListView.swift` / `ArchiveListView.swift` に共通行スタイルを適用。
- スワイプアクションの当たり判定と可読性を再確認。

**完了条件**
- 3タブ一覧で同一カードスタイルが適用され、既存スワイプ操作が維持される。

### Phase 3: タブと主要アクションの改善（1日）
**目的**
- 画面全体の印象を決めるフレーム（タブ・追加導線）を磨く。

**作業**
- `MainTabView.swift` のタブ見た目をトークンに合わせて調整。
- 追加導線（`+`ボタン、`AddInboxSheet`の保存ボタン）を視覚的に強化。
- 必要なら第2段階でカスタムタブバーを検討（このPhaseでは導入可否だけ判断）。

**完了条件**
- 現行の遷移構造を維持したまま、主要アクションの視認性が上がっている。

### Phase 4: 空状態とマイクロインタラクション（1日）
**目的**
- 初回体験と操作フィードバックを改善する。

**作業**
- 各一覧の空状態UIを追加（文言、アイコン、CTA）。
- `symbolEffect` / スプリングを使って、保存・移動など主要イベントに軽い動きを追加。
- `Reduce Motion` 有効時はアニメーションを簡略化。

**完了条件**
- データ0件時でも意図が伝わる画面になり、操作フィードバックが一貫する。

### Phase 5: ダークモード・アクセシビリティ仕上げ（1日）
**目的**
- 見た目の統一を全モードで完成させる。

**作業**
- ダークモード用のカード境界（薄いボーダー/グロー）を調整。
- コントラスト確認（本文、補助テキスト、ボタン）。
- VoiceOverラベル、Dynamic Type、ヒットターゲット（44pt以上）を最終確認。

**完了条件**
- Light/Dark双方で視認性が担保され、アクセシビリティ要件を満たす。

## 5. 変更対象ファイル（初期想定）
- 既存更新:
  - `ReadItLater/View/MainTabView.swift`
  - `ReadItLater/View/InboxListView.swift`
  - `ReadItLater/View/BookmarkListView.swift`
  - `ReadItLater/View/ArchiveListView.swift`
  - `ReadItLater/View/URLItemRow.swift`
  - `ReadItLater/View/AddInboxSheet.swift`
  - `ReadItLater/View/ItemSwipeActions.swift`
- 新規追加（例）:
  - `ReadItLater/View/AppColor.swift`
  - `ReadItLater/View/AppFont.swift`
  - `ReadItLater/View/AppSpacing.swift`
  - `ReadItLater/View/EmptyStateView.swift`

## 6. 実装ルール
- 1PR 1Phaseを基本とし、差分を小さく保つ。
- `List`から`ScrollView`への全面移行は、スワイプ操作の代替手段が固まるまで後回しにする。
- デザイン変更とロジック変更を同時に混ぜない。
- 変更ごとにLight/Darkと主要操作（追加、移動、削除、検索）を手動確認する。

## 7. 検証観点
- 視覚:
  - ブランドカラーが過剰に主張せず、主要CTAに集中しているか。
  - 情報階層（タイトル > URL/メタ情報）が明確か。
- 操作:
  - スワイプやタップの反応が遅くなっていないか。
  - 片手操作で主要導線に届くか。
- 品質:
  - `mise run buildformat`
  - `mise run unit`
  - 必要に応じて `mise run testformat`

## 8. 成功基準
- 新規ユーザーが「追加」「読む」「整理」の3操作を迷わず実行できる。
- 3タブで視覚ルールが統一され、デザインの一貫性がある。
- ダークモードとアクセシビリティ設定時にも、可読性と操作性が劣化しない。

