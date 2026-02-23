# SwiftUIアプリを「ポップでデザインされた製品」に仕上げる実践ガイド

SwiftUIの標準コンポーネントを**10のカスタマイズ領域**で手を入れるだけで、「あとで読む」アプリは驚くほど製品らしくなる。鍵となるのは、丸みのあるフォント、鮮やかなアクセントカラー、カード型レイアウト、そしてスプリングアニメーションの4要素だ。Pocket・Raindrop.io・GoodLinksなどの既存アプリと2024〜2025年のiOSデザイントレンドを分析した結果、「ポップで親しみやすい」仕上がりには**SF Pro Rounded + コーラル系アクセント + 角丸16ptカード + バウンスアニメーション**の組み合わせが最も効果的であることがわかった。以下、すぐに実装できる具体的なテクニックをコード付きで解説する。

---

## 1. ポップな雰囲気を生むカラーパレット設計

### 色選びの原則

2024〜2025年のモバイルデザインでは、**明るいアクセントカラー＋ニュートラルな背景**の組み合わせがトレンドだ。Pocketはコーラルレッド(`#EF4056`)とティール(`#50BCB6`)の補色関係で活気を出し、Raindrop.ioはミニマルな白背景にブルー系アクセントで清潔感を保っている。ポップな雰囲気には暖色系（コーラル、オレンジ、イエロー）をプライマリに、寒色系（ティール、スカイブルー）をセカンダリに配置するのが効果的だ。

### 推奨パレット

| 役割 | カラー名 | Hex | 用途 |
|------|---------|-----|------|
| Primary | コーラルレッド | `#FF6B6B` | メインアクション、ブランドカラー |
| Secondary | ブライトティール | `#4ECDC4` | 補助アクション、タグ |
| Accent | サニーイエロー | `#FFE66D` | ハイライト、バッジ |
| Success | フレッシュグリーン | `#2ECC71` | 既読マーク |
| Background Light | ウォームホワイト | `#F7F7F7` | ライトモード背景 |
| Background Dark | ディープネイビー | `#1A1A2E` | ダークモード背景（真っ黒は避ける） |
| Card Light | ホワイト | `#FFFFFF` | カード背景 |
| Card Dark | ダークインディゴ | `#242540` | ダークモードカード |

### SwiftUIでの定義方法

Asset Catalogとコード拡張の2つのアプローチがある。**ダークモード対応にはAsset Catalogが最適**（Any AppearanceとDark Appearanceを個別設定可能）、開発スピード優先ならコード拡張が便利だ。

```swift
// MARK: - Color+Extension.swift
extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
    
    // ブランドカラー
    static let brandPrimary = Color(hex: 0xFF6B6B)
    static let brandSecondary = Color(hex: 0x4ECDC4)
    static let brandAccent = Color(hex: 0xFFE66D)
    
    // セマンティックカラー（Asset Catalogで定義推奨）
    static let cardBackground = Color("CardBackground")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
}
```

Asset Catalogでは`CardBackground`というColor Setを作成し、Any Appearanceに`#FFFFFF`、Dark Appearanceに`#242540`を設定する。これだけで`Color("CardBackground")`が自動的にモードに応じて切り替わる。

---

## 2. 丸みのあるタイポグラフィで親しみやすさを演出

### SF Pro Roundedが最強の選択肢

ポップな雰囲気の最短ルートは**`.rounded`デザインのシステムフォント**だ。カスタムフォントのインストール不要で、Dynamic Typeにも完全対応する。Pocketはタイポグラフィを「第一級のインターフェースコンポーネント」として扱っており、フォント選びはアプリの印象を大きく左右する。

```swift
// MARK: - AppFont.swift（アプリ全体のフォントシステム）
struct AppFont {
    static func largeTitle() -> Font {
        .system(.largeTitle, design: .rounded).weight(.bold)
    }
    static func title() -> Font {
        .system(.title2, design: .rounded).weight(.semibold)
    }
    static func headline() -> Font {
        .system(.headline, design: .rounded).weight(.semibold)
    }
    static func body() -> Font {
        .system(.body, design: .rounded)
    }
    static func caption() -> Font {
        .system(.caption, design: .rounded)
    }
    static func tag() -> Font {
        .system(size: 12, weight: .medium, design: .rounded)
    }
}

// 使用例
Text("My Library").font(AppFont.largeTitle())
Text("5 min read").font(AppFont.caption())
```

### カスタムフォントを使う場合

NunitoやPoppinsなどのGoogle Fontsを使いたい場合、`.ttf`ファイルをXcodeプロジェクトに追加し、Info.plistの`UIAppFonts`に登録する。**`relativeTo:`パラメータでDynamic Type対応を忘れずに**。

```swift
// Info.plistに登録後
Text("タイトル")
    .font(.custom("Nunito-Bold", size: 24, relativeTo: .title))

// Dynamic Type対応でアイコンサイズも追従させる
@ScaledMetric(relativeTo: .body) private var iconSize = 20
```

### 推奨フォントサイズ

記事タイトルは**17〜19pt / Medium**、メタデータ（サイト名、読了時間）は**12〜13pt / Regular**、タグは**11〜12pt / Medium**が読みやすい。ヘッダーには**22〜28pt / Semibold**を使い、明確な視覚的階層を作る。

---

## 3. 標準Listからカスタムカードレイアウトへ

### ScrollView + LazyVStack が正解

標準の`List`ではカスタマイズに限界がある。**`ScrollView` + `LazyVStack`に切り替えることで、カードデザインの自由度が飛躍的に上がる**。スワイプアクションが必要な場合は、`List`の`.listRowBackground(Color.clear)`と`.listRowSeparator(.hidden)`で透明化する方法もある。

### カードデザインの推奨値

| プロパティ | 値 | 補足 |
|-----------|-----|------|
| 角丸 | **16pt**（`.continuous`スタイル） | 大きめカードはポップ感が出る |
| 影の半径 | 8pt | ダークモードでは0に |
| 影の色 | `black.opacity(0.08)` | 軽めが今のトレンド |
| 影のオフセット | `x: 0, y: 4` | 下方向のみ |
| 内部パディング | 14〜16pt | コンテンツの余白 |
| カード間スペーシング | 12pt | `LazyVStack(spacing: 12)` |
| 左右マージン | 16pt | `.padding(.horizontal, 16)` |

### 記事カードの完全実装

```swift
struct ArticleCardView: View {
    let article: Article
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // サムネイル
            AsyncImage(url: article.thumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.brandSecondary.opacity(0.15))
                    .overlay(
                        Image(systemName: "doc.richtext")
                            .foregroundStyle(Color.brandSecondary)
                    )
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(AppFont.headline())
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "globe").font(.caption2)
                    Text(article.siteName).font(AppFont.caption())
                    Text("·")
                    Text("\(article.readTime) min").font(AppFont.caption())
                }
                .foregroundStyle(.secondary)
                
                // タグ（ピル型）
                HStack(spacing: 6) {
                    ForEach(article.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(AppFont.tag())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.brandSecondary.opacity(0.12)))
                            .foregroundStyle(Color.brandSecondary)
                    }
                }
            }
            
            Spacer(minLength: 0)
            
            Image(systemName: article.isRead ? "checkmark.circle.fill" : "bookmark.fill")
                .foregroundStyle(article.isRead ? .green : Color.brandPrimary)
                .symbolEffect(.bounce, value: article.isRead)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBackground)
                .shadow(
                    color: colorScheme == .dark ? .clear : .black.opacity(0.06),
                    radius: 8, x: 0, y: 3
                )
        )
    }
}
```

### 再利用可能なカードModifier

```swift
struct CardBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.cardBackground)
                    .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.08),
                            radius: 8, x: 0, y: 4)
            )
    }
}
extension View {
    func cardStyle() -> some View { modifier(CardBackground()) }
}
```

---

## 4. SF Symbolsでアイコンに命を吹き込む

### レンダリングモードを使い分ける

SF Symbols 6では**6,000以上のシンボル**が利用可能だ。ポップなアプリでは`.palette`モードや`.hierarchical`モードを使うことで、単色よりもはるかにリッチな表現ができる。

```swift
// パレットモード：複数色を割り当て
Image(systemName: "bookmark.circle.fill")
    .symbolRenderingMode(.palette)
    .foregroundStyle(Color.brandPrimary, Color.brandPrimary.opacity(0.2))
    .font(.system(size: 28))

// 階層モード：自動で濃淡がつく
Image(systemName: "square.stack.3d.down.right.fill")
    .symbolRenderingMode(.hierarchical)
    .foregroundStyle(.indigo)
```

### symbolEffect()でアニメーション（iOS 17+）

iOS 17で追加された`symbolEffect`は、**アイコンに物理的な動きを加える最も簡単な方法**だ。

```swift
// ブックマークボタン：タップでバウンス
struct BookmarkButton: View {
    @State private var isBookmarked = false
    var body: some View {
        Button {
            isBookmarked.toggle()
        } label: {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .symbolEffect(.bounce, value: isBookmarked)
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(isBookmarked ? Color.brandPrimary : .secondary)
                .font(.title2)
        }
    }
}
```

### Read It Laterアプリで使えるSF Symbolsリスト

- **保存**: `bookmark` / `bookmark.fill`
- **ライブラリ**: `books.vertical` / `text.book.closed`
- **リンク**: `link` / `link.circle.fill`
- **既読**: `checkmark.circle` / `checkmark.circle.fill`
- **タグ**: `tag` / `tag.fill`
- **アーカイブ**: `archivebox` / `archivebox.fill`
- **検索**: `magnifyingglass`
- **追加**: `plus.circle.fill`
- **読了時間**: `clock` / `timer`
- **設定**: `gearshape`

---

## 5. スプリングアニメーションで「気持ちいい」を作る

### 基本のスプリングプリセット（iOS 17+）

SwiftUIのアニメーションで**最もポップ感が出るのはスプリングアニメーション**だ。iOS 17以降は3つの便利なプリセットが用意されている。

```swift
withAnimation(.bouncy) { }  // 弾むような動き → ポップに最適
withAnimation(.snappy) { }  // キビキビした動き → UIフィードバック向き
withAnimation(.smooth) { }  // なめらかな動き → フェード系向き
```

### カードのタップアニメーション

```swift
struct TappableCard: View {
    @State private var isPressed = false
    var body: some View {
        ArticleCardView(article: article)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .shadow(color: .black.opacity(isPressed ? 0.05 : 0.1),
                    radius: isPressed ? 4 : 8, y: isPressed ? 2 : 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
            .sensoryFeedback(.impact(weight: .light), trigger: isPressed)
    }
}
```

**ポイント**: `scaleEffect(0.97)`のわずかな縮小と、影の変化、そして**触覚フィードバック（`.sensoryFeedback`）** の3つを組み合わせることで、物理的な「押した感」が生まれる。

### matchedGeometryEffectでヒーロートランジション

記事一覧からデタイルへの遷移に使うと、カードが拡大して詳細画面になるような演出ができる。

```swift
struct ArticleListView: View {
    @Namespace private var animation
    @State private var selectedArticle: Article?
    
    var body: some View {
        ZStack {
            ScrollView {
                ForEach(articles) { article in
                    ArticleCardView(article: article)
                        .matchedGeometryEffect(id: article.id, in: animation)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedArticle = article
                            }
                        }
                }
            }
            if let article = selectedArticle {
                ArticleDetailView(article: article)
                    .matchedGeometryEffect(id: article.id, in: animation)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedArticle = nil
                        }
                    }
            }
        }
    }
}
```

### PhaseAnimatorで多段階アニメーション（iOS 17+）

URL保存完了時の「ポンッ」という演出に最適だ。

```swift
enum SavePhase: CaseIterable {
    case initial, scaleUp, settle
    var scale: Double {
        switch self { case .initial: 0.5; case .scaleUp: 1.1; case .settle: 1.0 }
    }
    var opacity: Double {
        switch self { case .initial: 0; case .scaleUp, .settle: 1.0 }
    }
}

NewArticleCard()
    .phaseAnimator(SavePhase.allCases, trigger: saveTrigger) { content, phase in
        content.scaleEffect(phase.scale).opacity(phase.opacity)
    } animation: { phase in
        switch phase {
        case .initial: .spring(duration: 0.2)
        case .scaleUp: .spring(duration: 0.3, bounce: 0.4)
        case .settle: .smooth(duration: 0.2)
        }
    }
```

---

## 6. カスタムタブバーとナビゲーションの洗練

### フローティングタブバー

2024〜2025年のトレンドである**フローティングタブバー**は、標準TabViewを完全にカスタムで置き換える。選択中タブのインジケーターが`matchedGeometryEffect`でスライドする演出がポップ感を高める。

```swift
enum AppTab: Int, CaseIterable {
    case home, favorites, archive, settings
    var icon: String {
        switch self {
        case .home: "house.fill"; case .favorites: "heart.fill"
        case .archive: "archivebox.fill"; case .settings: "gearshape"
        }
    }
    var title: String {
        switch self {
        case .home: "ホーム"; case .favorites: "お気に入り"
        case .archive: "アーカイブ"; case .settings: "設定"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selected: AppTab
    @Namespace private var ns
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                            .symbolEffect(.bounce, value: selected == tab)
                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(selected == tab ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selected == tab {
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [Color.brandPrimary, .pink],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .matchedGeometryEffect(id: "indicator", in: ns)
                                .shadow(color: Color.brandPrimary.opacity(0.4), radius: 8, y: 4)
                        }
                    }
                }
                .sensoryFeedback(.selection, trigger: selected)
            }
        }
        .padding(8)
        .background(Capsule().fill(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10))
        .padding(.horizontal, 20)
    }
}
```

### ナビゲーションバーのカスタマイズ

```swift
NavigationStack {
    ArticleListView()
        .navigationTitle("あとで読む")
        .toolbarBackground(Color.brandPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
}
```

---

## 7. 空状態デザインで第一印象を決める

保存記事がゼロの時の画面は**ユーザーが最初に見る画面**だ。Pocketは手描き風のウィットに富んだイラストで空状態を演出している。iOS 17の`ContentUnavailableView`をベースにカスタマイズするか、完全にオリジナルで作る。

```swift
struct PopEmptyState: View {
    let onAdd: () -> Void
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.brandPrimary.opacity(0.2), Color.brandAccent.opacity(0.1)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 160, height: 160)
                    .scaleEffect(animate ? 1.05 : 0.95)
                
                Image(systemName: "books.vertical")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.brandPrimary, .pink],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .offset(y: animate ? -5 : 5)
            }
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: animate)
            
            VStack(spacing: 8) {
                Text("まだ記事がありません")
                    .font(AppFont.title())
                Text("気になる記事を保存して\nいつでも読み返しましょう")
                    .font(AppFont.body())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button { onAdd() } label: {
                Label("最初の記事を追加", systemImage: "plus.circle.fill")
                    .font(AppFont.headline())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(LinearGradient(
                            colors: [Color.brandPrimary, .pink],
                            startPoint: .leading, endPoint: .trailing
                        ))
                    )
                    .shadow(color: Color.brandPrimary.opacity(0.4), radius: 10, y: 5)
            }
        }
        .padding(40)
        .onAppear { animate = true }
    }
}
```

**ポイント**: アイコンのゆるやかな上下アニメーションと背景円のスケールアニメーションが、静的な画面に生命感を与える。CTAボタンはグラデーション＋影で視線を集める。

---

## 8. ポップなボタンとFABの実装

### ButtonStyleプロトコルで統一的なスタイルを

```swift
struct PopButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline())
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(
                Capsule().fill(LinearGradient(
                    colors: [Color.brandPrimary, .pink],
                    startPoint: .leading, endPoint: .trailing
                ))
                .shadow(color: Color.brandPrimary.opacity(configuration.isPressed ? 0.2 : 0.4),
                        radius: configuration.isPressed ? 4 : 10,
                        y: configuration.isPressed ? 2 : 5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// 使い方
Button("記事を保存") { save() }
    .buttonStyle(PopButtonStyle())
```

### FAB（Floating Action Button）

```swift
struct FABButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle().fill(LinearGradient(
                        colors: [Color.brandPrimary, .pink],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .shadow(color: Color.brandPrimary.opacity(0.5), radius: 12, y: 6)
                )
        }
    }
}

// View拡張で簡単に配置
extension View {
    func withFAB(action: @escaping () -> Void) -> some View {
        ZStack(alignment: .bottomTrailing) {
            self
            FABButton(action: action)
                .padding(.trailing, 20)
                .padding(.bottom, 100)
        }
    }
}
```

### タグ/チップスタイルボタン

```swift
struct ChipButton: ButtonStyle {
    var isSelected: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .padding(.horizontal, 16).padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(
                Capsule().fill(isSelected
                    ? AnyShapeStyle(LinearGradient(colors: [Color.brandPrimary, .pink],
                        startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(Color(.systemGray6)))
            )
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}
```

---

## 9. ダークモードでもポップ感を維持する5つのコツ

ダークモード対応で最も多い失敗は、**影が消えて平坦になること**と、**鮮やかな色が眩しくなること**だ。以下の5つの原則を守れば、ダークモードでもポップな雰囲気を保てる。

**1. 影をカラードグローに置き換える。** ダークモードでは黒い影は見えない。代わりにブランドカラーの淡いグロー（`Color.brandPrimary.opacity(0.15)`）を使うと、暗い背景でもカードに浮遊感が出る。

**2. グラデーションの不透明度を20%下げる。** ライトモードと同じグラデーションはダークモードでは眩しい。`.opacity(0.7〜0.8)`で少し抑える。

**3. 真っ黒（`#000000`）は使わない。** GoodLinksの「Night」テーマが好評なのは、ディープグレー（`#1A1A2E`）を採用しているからだ。真っ黒はコントラストがきつすぎる。

**4. 影の代わりにボーダーで階層を表現する。** `RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.1), lineWidth: 1)`で、ダークモードでもカード同士の境界を示せる。

**5. `.ultraThinMaterial`を活用する。** マテリアル背景はライト/ダークで自動適応し、ガラスモーフィズム的な表現ができる。2025年のiOS 26「Liquid Glass」デザインの方向性とも合致する。

```swift
struct AdaptiveCard: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack { /* content */ }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.1) : .clear,
                                  lineWidth: 1)
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color.brandPrimary.opacity(0.15) // カラードグロー
                    : .black.opacity(0.08),             // 通常の影
                radius: colorScheme == .dark ? 12 : 8,
                y: colorScheme == .dark ? 0 : 4
            )
    }
}

// プレビューで両モードを同時確認
#Preview("Light") { ContentView().environment(\.colorScheme, .light) }
#Preview("Dark")  { ContentView().environment(\.colorScheme, .dark) }
```

---

## 既存アプリから学ぶデザインの方向性

**Pocket**は「ポップ＆ウォーム」の好例だ。コーラル/ティール/ミントの「レインボーバー」、丸みのある太線のカスタムアイコン、手描きイラスト、そして**「読書空間のような落ち着き」**を意識したデザイン原則を持つ。ポップだが騒がしくない、絶妙なバランスが参考になる。

**Raindrop.io**は「ミニマル＆機能美」のアプローチだ。リスト/カード/グリッド/マソンリーの**4種類のビューモード**を提供し、ユーザーが好みの表示を選べる。情報密度と視覚的整理の両立に優れている。

**GoodLinks**は「ネイティブiOS最適化」の模範だ。iCloudだけでアカウント不要、Shortcuts/Widget/VoiceOver完全対応、iOS 26のLiquid Glass対応など、**プラットフォーム機能を最大限に活かす**哲学がある。カスタムアクセントカラーや4種類のテーマ（Light/Sepia/Dark/Night）でパーソナライゼーションも強い。

---

## まとめ：最小の変更で最大のインパクトを得る優先順位

すべてを一度に実装する必要はない。以下の順番で手を付けると、少ない工数で最大の視覚的変化が得られる。

1. **カラーとフォント**（工数：小、効果：大）：`Color`拡張と`AppFont`構造体を定義し、全画面に適用するだけでアプリ全体の印象が変わる
2. **カードレイアウト**（工数：中、効果：大）：`List`から`ScrollView + LazyVStack`に切り替え、角丸16pt＋影のカードViewを作る
3. **タブバーカスタマイズ**（工数：中、効果：大）：フローティングタブバーでアプリ全体のフレームが一気にオリジナルになる
4. **アニメーション追加**（工数：小、効果：中）：`.symbolEffect(.bounce)`とカードの`.scaleEffect`だけでも動きのあるUIになる
5. **空状態デザイン**（工数：小、効果：中）：ゼロ状態の画面がプロダクトの第一印象を決める
6. **ダークモード最適化**（工数：中、効果：中）：Asset Catalogでのカラー定義と影/ボーダーの切り替えで完成度が上がる

2025年のiOSデザインは**丸みのある形状、スプリングアニメーション、ガラスモーフィズム素材**が3大トレンドだ。SwiftUIはこれらすべてをネイティブAPIで直接サポートしており、上記のコードスニペットをそのまま組み合わせるだけで、標準コンポーネントの域を超えた「デザインされたプロダクト」に仕上げることができる。