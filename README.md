# Clock

macOS 向けの時計アプリ。アナログ文字盤とデジタル表示を 1 画面に並べて表示する、SwiftUI 製の土台です。

![layout](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey) ![swift](https://img.shields.io/badge/swift-5.9-orange)

## できること

- アナログ時計とデジタル時計を横並び（ウインドウが狭いときは縦並び）で同時表示
- すりガラス風カード + グラデーションのアクセントによるモダンな外観
- ライト / ダークモードへの自動追従
- 表示設定（⌘, もしくは画面右上のボタン）
  - 24 時間表記 / 12 時間表記
  - 秒の表示・非表示
  - 秒針を滑らかに動かす（スイープ） / 1 秒ごとに刻む
  - 文字盤の数字表示

## 必要なもの

- macOS 14 以降
- Swift 5.9 以降（Xcode 15 以降に同梱）

## 使い方

```sh
# そのまま起動して動きを確認する
make run

# .app バンドルを組み立てて開く（dist/Clock.app）
make open

# ロジックのテスト
make test
```

Xcode で開きたい場合は、このディレクトリを `File > Open` でそのまま開けば
Swift Package として認識されます。

## 構成

```
Sources/
  ClockCore/            UI に依存しない時刻ロジック（テスト対象）
    ClockHands.swift      日時 → 針の角度
    ClockFormatter.swift  日時 → デジタル表示・日付・タイムゾーン文字列
  ClockApp/             SwiftUI アプリ本体
    ClockAppMain.swift    App エントリポイントと Scene 定義
    ClockSettings.swift   ユーザー設定（UserDefaults 永続化）
    DesignSystem/
      Theme.swift         色・角丸・余白の定義。見た目の調整はまずここ
      GlassCard.swift     すりガラス風カード
    Views/
      RootView.swift      画面レイアウトと時刻の供給（TimelineView）
      AnalogClockView.swift
      DigitalClockView.swift
      SettingsView.swift
Tests/ClockCoreTests/   ClockCore のユニットテスト
Resources/Info.plist    .app バンドル用の Info.plist
```

### 設計メモ

- 時刻の更新は `RootView` の `TimelineView` 一箇所だけで行い、アナログ / デジタル
  両方に同じ `Date` を配る。表示のずれが起きず、タイマーの二重管理も避けられる。
- 秒針をスイープさせるときだけ `.animation` スケジュール（毎フレーム更新）を使い、
  それ以外は 1 秒周期に落として無駄な再描画を減らしている。
- 角度計算と文字列生成は `ClockCore` に切り出してあり、UI なしでテストできる。

## これから足せるもの

土台として、次の拡張を想定した作りにしてあります。

- ワールドクロック: `RootView` の `timeZone` は差し替え可能なので、
  タイムゾーンの配列を回して複数カードを並べれば拡張できる
- ストップウォッチ / タイマー: `ClockCore` に計測ロジックを追加し、タブで切り替える
- メニューバー常駐: `MenuBarExtra` シーンを `ClockAppMain` に追加する
- アプリアイコン: `Resources/` に `.icns` を置き、`Info.plist` に `CFBundleIconFile` を追加
