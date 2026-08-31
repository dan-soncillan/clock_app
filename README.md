# Clock

macOS 向けの時計アプリ。1 ウィンドウ内に大径アナログ時計（左）とデジタル時計＋日付・残時間
インジケーター（右）を並べる。常時デスクトップに表示しておく前提で、遠目でも読める
高コントラスト・太字の視認性を最優先している。

SwiftUI + Swift Package Manager 製。デザインハンドオフ「Clock — アナログ & デジタル」の
確定値（980 × 620、Archivo、アクセント `#E5372C`）をそのまま実装している。

## できること

- アナログ文字盤（512px）とデジタル情報カラムを 1 画面に同時表示
- 「今日の残り」「今年の残り」「目標年齢までの残り」を数値と残量バーで表示
  （バーはいずれも右端から減っていく向き）

  一番下のバーの基準になる生年月日と目標年齢は、ネイティブ版は
  `Views/RootView.swift`、Web 版は `web/index.html` の先頭にある定数で変えられる。
- フッターでフォントウェイトを 400 / 500 / 600 / 700 / 800 に即時切替。選択は永続化
- 表示設定（⌘,）
  - 24 時間表記 / 12 時間表記
  - 秒の表示・非表示
  - 秒針のスムーズ運針 / 1 秒刻み
  - アクセント色 4 色

## 必要なもの

- macOS 14 以降
- Swift 5.9 以降（Xcode 15 以降に同梱）

## Web 版

`web/index.html` が同じデザインの Web 実装。ブラウザで開くだけで動くので、
署名も Gatekeeper も関係ない。

- **Dock に入れて使う**: Safari で開いて **ファイル → Dock に追加**。
  Chrome なら **︙ → キャスト、保存、共有 → ショートカットを作成**
- **公開する**: リポジトリの **Settings → Pages** で Source を
  **GitHub Actions** にすると、`main` への push で自動的に公開される
  （`.github/workflows/pages.yml`）
- **手元で見る**: `web/index.html` をブラウザにドラッグしても動く

### ネイティブ版との差分

- **信号機ボタン**はブラウザに窓枠が無いので置いていない。タイトルバーの
  帯と中央の `CLOCK` は残してある
- **時刻同期**は NTP（UDP）をブラウザから使えないため、HTTP の `Date`
  ヘッダーで代用している。精度が約 1 秒と粗く、NTP ではないので
  表示も `NTP OK` ではなく `SYNC OK` にしてある
- **設定**はすべてフッターに置いてある。`24H` / `SEC` / `SWEEP` のクリックで
  表記・秒表示・運針を切り替え、`ACCENT` の4色でアクセントを変える。
  選択はこの端末のブラウザにだけ保存される

## ネイティブ版を入手して起動する

### ビルド済みのアプリをダウンロードする（ターミナル不要）

1. GitHub のリポジトリで **Actions** タブを開く
2. 最新の成功したビルド（緑のチェック）をクリック
3. ページ下部の **Artifacts** から `Clock-macOS` をダウンロード
4. ダウンロードした zip を開くと `Clock.app` が出てくるので、
   アプリケーションフォルダに入れてダブルクリック

初回だけ「開発元を確認できないため開けません」と出る。署名がアドホックのため。
**システム設定 → プライバシーとセキュリティ** を開き、下の方に出ている
`Clock.app` の項目で **このまま開く** を押すと、以降はダブルクリックで起動する。

タグ（`v1.0.0` など）を打つと、同じものが **Releases** にも並ぶ。

### 自分でビルドする

```sh
make open   # .app を組み立てて開く（dist/Clock.app）
make test   # ClockCore のユニットテスト
make run    # 実行ファイルを直接起動（Dock アイコンが出ないなど簡易的）
```

Xcode で開きたい場合は、このディレクトリを `File > Open` でそのまま開けば
Swift Package として認識されます。

## 構成

```
Sources/
  ClockCore/              UI に依存しない純粋なロジック（テスト対象）
    ClockHands.swift        日時 → 針の角度
    ClockFormatter.swift    日時 → HH:MM / SS / 曜日 / 日付 / タイムゾーン行
    CalendarProgress.swift  今日の残り・今年の残りの派生値
    LifeProgress.swift      目標年齢までの残りの派生値
    TimeSyncStatus.swift    フッター右端の同期表示の状態
    NTPPacket.swift         SNTP パケットの組み立て・解析とずれの計算
    SNTPClient.swift        時刻サーバーへの問い合わせ
  ClockApp/               SwiftUI アプリ本体
    ClockAppMain.swift      App エントリポイントと Scene 定義
    ClockSettings.swift     ユーザー設定（UserDefaults 永続化）
    TimeSyncMonitor.swift   時刻同期の定期確認
    DesignSystem/
      Theme.swift           色・寸法のデザイントークン。見た目の調整はまずここ
      AppFont.swift         Archivo の可変ウェイト指定とフォント登録
      TextStyle.swift       letter-spacing / line-height 相当の補助
    Views/
      RootView.swift        画面レイアウト、時刻の供給、拡大縮小
      TitleBarView.swift
      AnalogClockView.swift
      DigitalPanelView.swift
      RemainingBar.swift
      FooterView.swift
      WindowConfigurator.swift
      SettingsView.swift
    Fonts/                  Archivo（可変フォント）と OFL.txt
Tests/ClockCoreTests/     ClockCore のユニットテスト
Resources/Info.plist      .app バンドル用の Info.plist
design/                   デザインハンドオフ一式（実装の基準）
web/index.html            同じデザインの Web 実装
.github/workflows/        macOS ランナーでのテストと .app のビルド
```

### 設計メモ

- **時刻の供給は 1 箇所だけ。** `RootView` の `TimelineView` が配る `Date` を
  アナログとデジタルの両方が受け取る。表示のずれが起きず、タイマーの二重管理もない。
  秒針をスムーズ運針させるときだけ毎フレーム更新のスケジュールを使い、
  それ以外は 1 秒周期に落として無駄な再描画を減らしている。
- **レイアウトは 980 × 620 の座標系で固定し、ウィンドウ側にまとめて拡大縮小をかける。**
  デザイン指定の「リサイズしても再配置はせず、文字盤と文字を同じ倍率でスケールする」に
  そのまま対応する。最小サイズは 0.7 倍。
- **数値の計算と文字列の生成は `ClockCore` に閉じている。** 針の角度、通日、残り時間、
  タイムゾーン行の組み立てはすべて UI なしでテストできる。
- **フォントは可変フォントの `wght` 軸を直接指定する。** `Font.weight(_:)` の記号的な
  指定では 500 / 600 のような中間ウェイトを正確に出せないため。

### デザインからの意図的な差分

- **信号機ボタン**はハンドオフでは図形として描かれているが、実装では macOS 本体が描く
  ものを使う（`.windowStyle(.hiddenTitleBar)`）。アプリ側では一切描かないので二重にならない。
  ウィンドウの角丸・影も OS 側のものになる。タイトルバーの背景・境界・中央の `CLOCK` は
  指定どおりに描いている。ボタンの縦位置は macOS の標準位置（上端から約 14pt）で、
  44px バーの中央にはならない。
- **12 時間表記**の時刻は `01`〜`12` と 2 桁で出す。等幅数字の桁数が変わると
  隣の秒の位置が動いてしまうため。

### 時刻同期の表示について

フッター右端の `NTP OK` は、**この Mac の時計が実際の時刻と合っているか**を示す。
起動時と 15 分ごとに `time.apple.com` へ SNTP（UDP 123）で問い合わせ、
往復の遅延を差し引いたずれを測る。

- ずれが 2 秒以内 → `NTP OK`（アクセント色）
- ずれが大きい / 応答なし / 未確認 → `NTP —`（副色）

表示にカーソルを合わせると実測のずれがミリ秒で出る。クリックすると即座に再確認する。
時計を合わせに行くわけではない（それは macOS の仕事）。あくまで確認だけを行う。

アプリをサンドボックス化する場合は、entitlements に
`com.apple.security.network.client` が必要になる。

### 未実装

- アプリアイコン。`Resources/` に `.icns` を置き、`Info.plist` に
  `CFBundleIconFile` を追加する。

## 検証のしかた

手元の Mac で以下を順に確認する。

### 1. ロジック

```sh
make test
```

針の角度、通日・残り時間の派生値、表示文字列、SNTP のパケット組み立てとずれの計算を
UI なしで検証する。デザインのスクリーンショットと同じ 2026-08-31 11:25 JST を
テストケースに入れてあるので、`12H 35M` / `WEEK 35 · DAY 243 OF 365` / `17 WEEKS` /
`122 DAYS` が一致することを確認できる。

### 2. 画面

```sh
make run
```

- ウィンドウが 980 × 620 で開き、`design/design_handoff_mac_clock/screenshots/main-window.png` と並べて見比べる
- **フォント**: 起動時に標準エラーへ `[ClockApp] 同梱フォントが…` と出ていなければ
  Archivo が読めている。フッターのウェイトを 400 と 800 で切り替えて、
  文字盤の数字と時刻の太さが変わることを確認する
- **秒針**: 既定はスムーズ運針。⌘, で「秒針を滑らかに動かす」を切ると 1 秒刻みになり、
  フッターの表示も `SWEEP` → `TICK` に変わる
- **リサイズ**: ウィンドウの端をドラッグして、配置が組み替わらずに全体が
  同じ倍率で拡大縮小することを確認する（0.7 倍で止まる）
- **ウィンドウ**: 信号機ボタンが 1 組だけ出ていること（アプリ側では描いていない）。
  背景をドラッグしてウィンドウを動かせること

### 3. 時刻同期

- フッター右端の表示にカーソルを合わせると、実測のずれがミリ秒で出る
- クリックすると再確認する
- Terminal で `sntp -d time.apple.com` を実行し、そこに出るオフセットと
  近い値になっていれば正しく測れている
- ネットワークを切ると、次の確認で `NTP —` に変わる（ツールチップに理由が出る）
- システム設定で時刻の自動設定を切って時計をずらすと `NTP —`（ずれの値つき）になる

## これから足せるもの

- ワールドクロック: `RootView` の `timeZone` は差し替え可能なので、
  タイムゾーンを切り替える／複数並べる形に広げられる
- ストップウォッチ / タイマー: `ClockCore` に計測ロジックを追加する
- メニューバー常駐: `MenuBarExtra` シーンを `ClockAppMain` に追加する

## デザインの基準

`design/design_handoff_mac_clock/` にハンドオフ一式を置いてある。
色・寸法・余白はすべてここの確定値に従う。

- `README.md` — 仕様（画面構成、インタラクション、デザイントークン）
- `screenshots/main-window.png` — 実装対象の実寸 2 倍キャプチャ
- `Clock Mac App.dc.html` — デザイン本体。`support.js` と同じ場所に置いて
  ブラウザで開くと実時刻で動く（`5a` が実装対象、`5f` は書体比較用の検討パーツ）

## サードパーティ

- **Archivo**（Omnibus-Type）— SIL Open Font License 1.1。
  `Sources/ClockApp/Fonts/` に可変フォント本体とライセンス原文を同梱している。
