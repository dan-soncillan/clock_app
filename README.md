# Clock

macOS 向けの時計アプリ。1 ウィンドウ内に大径アナログ時計（左）とデジタル時計＋日付・残時間
インジケーター（右）を並べる。常時デスクトップに表示しておく前提で、遠目でも読める
高コントラスト・太字の視認性を最優先している。

SwiftUI + Swift Package Manager 製。デザインハンドオフ「Clock — アナログ & デジタル」の
確定値（980 × 620、Archivo、アクセント `#E5372C`）をそのまま実装している。

## できること

- アナログ文字盤（512px）とデジタル情報カラムを 1 画面に同時表示
- 「今日の残り」「今年の残り」を数値と残量バーで表示（バーは右端から減っていく向き）
- フッターでフォントウェイトを 400 / 500 / 600 / 700 / 800 に即時切替。選択は永続化
- 表示設定（⌘,）
  - 24 時間表記 / 12 時間表記
  - 秒の表示・非表示
  - 秒針のスムーズ運針 / 1 秒刻み
  - アクセント色 4 色

## 必要なもの

- macOS 14 以降
- Swift 5.9 以降（Xcode 15 以降に同梱）

## 使い方

```sh
make run    # そのまま起動して動きを確認する
make open   # .app バンドルを組み立てて開く（dist/Clock.app）
make test   # ClockCore のユニットテスト
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
    TimeSyncStatus.swift    フッター右端の同期表示（下記「未実装」を参照）
  ClockApp/               SwiftUI アプリ本体
    ClockAppMain.swift      App エントリポイントと Scene 定義
    ClockSettings.swift     ユーザー設定（UserDefaults 永続化）
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
      SettingsView.swift
    Fonts/                  Archivo（可変フォント）と OFL.txt
Tests/ClockCoreTests/     ClockCore のユニットテスト
Resources/Info.plist      .app バンドル用の Info.plist
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
  ものを使う（`.windowStyle(.hiddenTitleBar)`）。ウィンドウの角丸・影も OS 側のものになる。
  タイトルバーの背景・境界・中央の `CLOCK` は指定どおりに描いている。
- **12 時間表記**の時刻は `01`〜`12` と 2 桁で出す。等幅数字の桁数が変わると
  隣の秒の位置が動いてしまうため。

### 未実装

- **フッター右端の同期表示**は、実際の時刻同期を確認していないため既定で `NTP —`
  （副色）を表示する。デザインの既定状態である `NTP OK` にするには、
  `ClockCore/TimeSyncStatus.swift` の `TimeSyncStatusProviding` に
  実際の確認（SNTP 問い合わせなど）を実装して差し替える。
- アプリアイコン。`Resources/` に `.icns` を置き、`Info.plist` に
  `CFBundleIconFile` を追加する。

## これから足せるもの

- ワールドクロック: `RootView` の `timeZone` は差し替え可能なので、
  タイムゾーンを切り替える／複数並べる形に広げられる
- ストップウォッチ / タイマー: `ClockCore` に計測ロジックを追加する
- メニューバー常駐: `MenuBarExtra` シーンを `ClockAppMain` に追加する

## サードパーティ

- **Archivo**（Omnibus-Type）— SIL Open Font License 1.1。
  `Sources/ClockApp/Fonts/` に可変フォント本体とライセンス原文を同梱している。
