# Handoff: Clock — アナログ & デジタル（macOS デスクトップアプリ）

## Overview
常時デスクトップに表示しておく前提の macOS 時計アプリ。1ウィンドウ内に大径アナログ時計（左）と
デジタル時計＋日付・残時間インジケーター（右）を並べる。長時間見続けても疲れず、遠目でも読める
高コントラスト・太字の視認性を最優先している。

## About the Design Files
このフォルダ内の HTML は **デザインリファレンス（プロトタイプ）** です。見た目と挙動の意図を示すもので、
そのまま製品コードとして流用する前提ではありません。実装タスクは、この HTML デザインを
**ターゲットのコードベースの既存環境（SwiftUI / Electron+React / Tauri など）の作法・ライブラリで再現すること**です。
環境が未定の場合は、macOS ネイティブなら SwiftUI、Web 技術なら Electron または Tauri + React を推奨します。
（アナログ文字盤は CSS の絶対配置＋rotate で作られていますが、SwiftUI なら Canvas/Shape、
Web なら SVG または Canvas での実装が自然です。）

## Fidelity
**High-fidelity (hifi)**。色・タイポグラフィ・寸法・余白はすべて確定値です。下記の数値どおりピクセル単位で再現してください。
（デザイン確認のためのフォント比較セクション `5f` は仕様外の検討用パーツです。実装対象は `5a` のメインウィンドウのみ。）

---

## Screens / Views

### Main window（唯一の画面）
- **Name**: Clock — Main window
- **Purpose**: 現在時刻をアナログ／デジタル両方で常時確認する。あわせて「今日の残り」「今年の残り」を把握する。
- **Window size**: 980 × 620 px（デザイン基準サイズ。リサイズ対応は「Responsive behavior」参照）
- **Window chrome**: 角丸 12px、背景 `#141618`、境界 1px `rgba(255,255,255,0.12)`、
  影 `0 60px 110px -30px rgba(0,0,0,0.9)`、`overflow: hidden`
- **Layout**: 縦3段の flex column
  1. タイトルバー 高さ 44px（固定）
  2. コンテンツ（flex:1）— 横並び flex row、`gap: 22px`、`padding: 8px 22px 8px 10px`、`align-items: center`
     - 左: アナログ文字盤 512 × 512px（`flex: none`）
     - 右: デジタル情報カラム（`flex: 1`、実効幅 約412px）
  3. フッター 高さ 46px（固定）

#### 1. タイトルバー
- 背景 `#17191c`、下境界 1px `rgba(255,255,255,0.08)`、`padding: 0 14px`、`gap: 8px`
- 信号機ボタン: 直径 11px の円 × 3 —閉じる `#ff5f57` / 最小化 `#febc2e` / 最大化 `#28c840`
- 中央タイトル: `CLOCK` — 11px / weight 600 / letter-spacing 0.16em / `#9aa1a7`
  （中央揃えのため右側に 66px のスペーサーを置いてバランスを取っている）

#### 2-A. アナログ文字盤（512 × 512px）
- 円形。背景 `radial-gradient(75% 75% at 50% 30%, #1c1f22 0%, #131518 100%)`、
  境界 1px `rgba(255,255,255,0.14)`、`border-radius: 50%`
- **目盛り（60本）**: 中心から回転 `i * 6deg`。円の上端から `top: 10px` の位置に配置
  - 5分ごと（`i % 5 === 0`）: 幅 3px / 高さ 16px / `#ffffff`
  - それ以外: 幅 1px / 高さ 8px / `rgba(255,255,255,0.4)`
- **数字（12個）**: 12, 1, 2 … 11。中心からの半径 **194px** の円周上に配置（`translate(-50%,-50%)` 後に x/y オフセット）
  - font-size 42px / weight は設定値（既定 700）/ 色 `#ffffff` / `font-variant-numeric: tabular-nums`
  - 位置計算: `angle = i / 12 * 2π - π/2`、`x = cos(angle) * 194`、`y = sin(angle) * 194`（四捨五入）
- **針**（すべて `transform-origin: 50% 100%`、中心から上向きに伸ばして回転）
  - 時針: 幅 10px / 長さ 112px / 角丸 5px / `#ffffff`
  - 分針: 幅 6px / 長さ 158px / 角丸 3px / `#ffffff`
  - 秒針: 幅 2px / 長さ 168px / 角丸なし / アクセント色 `#E5372C`
  - 針の先端は数字リング（内側エッジ 約173px）に触れない長さに調整済み。数字サイズ・半径を変える場合は必ずクリアランスを再確認する
  - 中心の丸（キャップ）は **置かない**（意図的に削除）
- **角度計算**
  - 時針 `((hour % 12) + minute / 60) * 30`
  - 分針 `(minute + second / 60) * 6`
  - 秒針 `secondsWithFraction * 6`（スムーズ運針時は `second + ms/1000`、ティック運針時は整数秒）

#### 2-B. デジタルカラム（右、幅 約412px）
縦 flex column / `gap: 18px`。意味のある2ブロックに分かれ、間に 1px `rgba(255,255,255,0.14)` の区切り線。

**ブロック1「現在」**（`gap: 12px`）
1. `TOKYO · JST · UTC+09:00` — 11px / weight 600 / letter-spacing 0.18em / `#969da3`
2. 時刻行（`align-items: baseline`, `gap: 10px`）
   - `HH:MM` — **font-size 104px** / weight は設定値（既定700）/ line-height 0.82 / letter-spacing -0.05em / `#ffffff` / tabular-nums
   - `SS` — font-size 36px / weight 同上 / line-height 1 / アクセント色 `#E5372C` / tabular-nums（秒表示OFF時は非表示）
   - 秒は時刻と同じ1行に収まるサイズにしてある（"SEC" などのラベルは付けない）
3. ラベル行（`justify-content: space-between`）
   - 左 `REMAINING TODAY` — 10px / weight 600 / letter-spacing 0.22em / `#7d848a`
   - 右 残時間 `12H 45M` 形式 — 15px / weight 600 / `#ffffff` / tabular-nums
4. バー: 高さ 4px / 角丸 2px / トラック `rgba(255,255,255,0.1)` / `overflow: hidden`
   - **塗り = 残り**、`justify-content: flex-end` で **右寄せ**。幅 = `残り分 / 1440 * 100%`、色 `#E5372C`
5. 軸ラベル（`space-between`）: `24` `18` `12` `06` `0` — 9.5px / weight 500 / letter-spacing 0.14em / `#6f767c`
   - 左が24時間、右が0（残りが右に向かって減っていく向き）

**ブロック2「日付・年」**（`gap: 12px`）
1. 曜日 `MONDAY`（英語・大文字）— 20px / weight 600 / letter-spacing 0.02em / `#ffffff`
2. 日付 `August 31, 2026`（en-US）— 15px / weight 400 / `#c3c9ce`
3. `WEEK 35 · DAY 243 OF 365` — 11px / weight 500 / letter-spacing 0.12em / `#7d848a`
4. `REMAINING IN 2026` — 10px / weight 600 / letter-spacing 0.22em / `#7d848a`（上に 4px の余白）
5. 数値2つ（`gap: 26px`、各 `align-items: baseline`, `gap: 7px`）
   - 数値 40px / weight 600 / line-height 0.9 / `#ffffff` / tabular-nums
   - 単位 `WEEKS` `DAYS` — 12px / weight 500 / letter-spacing 0.14em / `#969da3`
6. バー: ブロック1と同一仕様。幅 = `残り日数 / 年の日数 * 100%`、右寄せ、色 `#E5372C`
7. 軸ラベル: 左 `JAN` / 右 `DEC` — 9.5px / weight 500 / letter-spacing 0.14em / `#6f767c`

#### 3. フッター
- 高さ 46px、背景 `#17191c`、上境界 1px `rgba(255,255,255,0.08)`、`padding: 0 22px`、`justify-content: space-between`
- 左: **フォントウェイト切替**
  - ラベル `FONT WEIGHT` — 10px / weight 600 / letter-spacing 0.2em / `#7d848a`
  - セグメント: 外枠 `padding: 3px` / 角丸 8px / 背景 `rgba(255,255,255,0.06)` / `gap: 4px`
  - 各ボタン `400 / 500 / 600 / 700 / 800` — `padding: 5px 11px` / 角丸 6px / 11px / weight 600 / letter-spacing 0.06em
    - 選択中: 背景 `#ffffff` / 文字 `#141618`
    - 非選択: 背景 transparent / 文字 `#9aa1a7`
    - hover（非選択時）: 背景 `rgba(255,255,255,0.12)`
- 右: `24H · SWEEP`（設定に応じて `12H` / `TICK` に変化）— 11px / weight 500 / letter-spacing 0.12em / `#8b9298`、
  続けて `NTP OK` — アクセント色 `#E5372C`

---

## Interactions & Behavior
- **時刻更新**: 50ms 間隔で現在時刻を取得し再描画（秒針のスムーズ運針のため）。
  実装時は `requestAnimationFrame` / SwiftUI の `TimelineView(.animation)` などを推奨。
- **秒針の運針**: `smoothSweep = true` で連続運針（`second + ms/1000`）、`false` で1秒ごとのステップ。
  CSS transition は使わず、毎フレーム角度を再計算する（359°→0° の巻き戻りを避けるため）。
- **フォントウェイト切替**: フッターのセグメントをクリックすると、デジタル時刻・秒・文字盤の数字の
  font-weight が即座に変わる（アニメーションなし）。選択状態は永続化して次回起動時に復元する。
- **hover**: フッターのウェイトボタンのみ（上記の色）。他はホバー状態を持たない。
- **ローディング／エラー状態**: なし（ローカル時刻のみで完結）。`NTP OK` は同期状態の表示で、
  同期失敗時は同じ位置に `NTP —` を `#8b9298` で表示する想定。
- **Responsive behavior**: 980×620 が基準。リサイズを許可する場合は
  文字盤サイズとデジタル文字サイズを同じ倍率でスケールする（レイアウトの再配置はしない）。
  最小サイズは 980×620 の 0.7 倍程度まで。

## State Management
| State | 型 | 初期値 | 説明 |
|---|---|---|---|
| `now` | Date | 現在時刻 | 50ms ごとに更新 |
| `weight` | number | 700 | フッターの切替で変更、永続化 |

設定（ユーザー設定として永続化する項目）
| 設定 | 型 | 既定値 | 選択肢 | 効果 |
|---|---|---|---|---|
| `weight` | enum | `700` | 400 / 500 / 600 / 700 / 800 | デジタル時刻・秒・文字盤数字の太さ |
| `accent` | color | `#E5372C` | `#E5372C` / `#F0522B` / `#3B7DD8` / `#2FA36B` | 秒針・秒数字・残りバー・`NTP OK` の色 |
| `showSeconds` | boolean | `true` | — | 秒針とデジタル秒表示の ON/OFF |
| `smoothSweep` | boolean | `true` | — | 秒針のスムーズ運針 ON/OFF（フッター表示 `SWEEP`/`TICK`） |
| `use24h` | boolean | `true` | — | 24時間／12時間表記（フッター表示 `24H`/`12H`） |

派生値（毎フレーム計算）
- `remainToday` = `1440 - (hour*60 + minute)` 分 →`H`/`M` 表記
- `dayRemainPct` = `残り分 / 1440 * 100`
- `dayNo` = 元日からの経過日数 + 1、`daysInYear` = 365 or 366、`daysLeft` = `daysInYear - dayNo`
- `weeksLeft` = `floor(daysLeft / 7)`、`weekNo` = `ceil(dayNo / 7)`
- `yearRemainPct` = `daysLeft / daysInYear * 100`
- 曜日・日付は `en-US` ロケール（`weekday: long` を大文字化 / `month long, day numeric, year numeric`）

## Design Tokens
**色**
| 用途 | 値 |
|---|---|
| ウィンドウ背景 | `#141618` |
| タイトルバー／フッター背景 | `#17191c` |
| 文字盤背景 | `radial-gradient(75% 75% at 50% 30%, #1c1f22, #131518)` |
| 境界（強） | `rgba(255,255,255,0.14)` |
| 境界（弱） | `rgba(255,255,255,0.08)` / `rgba(255,255,255,0.12)` |
| 主要テキスト・針・目盛り | `#ffffff` |
| 副テキスト | `#c3c9ce` |
| 三次テキスト | `#969da3` |
| ラベル | `#7d848a` |
| 軸ラベル | `#6f767c` |
| アクセント（既定・赤） | `#E5372C` |
| バートラック | `rgba(255,255,255,0.1)` |
| 信号機 | `#ff5f57` / `#febc2e` / `#28c840` |

**タイポグラフィ** — 全体を1書体で統一: **Archivo**（Google Fonts、weight 400–800）
| 用途 | サイズ / weight / letter-spacing |
|---|---|
| 時刻 HH:MM | 104 / 設定値 / -0.05em |
| 秒 SS | 36 / 設定値 / 標準 |
| 文字盤数字 | 42 / 設定値 / 標準 |
| 曜日 | 20 / 600 / 0.02em |
| 数値（WEEKS/DAYS） | 40 / 600 / 標準 |
| 日付・残時間値 | 15 / 400–600 |
| タイムゾーン | 11 / 600 / 0.18em |
| セクションラベル | 10 / 600 / 0.22em |
| 軸ラベル | 9.5 / 500 / 0.14em |
| タイトルバー／フッター | 11 / 500–600 / 0.12–0.16em |

数字は必ず `font-variant-numeric: tabular-nums`（等幅数字）を有効にする — 桁の揺れを防ぐため必須。

**スペーシング**: 4 / 8 / 10 / 12 / 18 / 22 / 26 px
**角丸**: 2（バー）/ 3・5（針）/ 6・8（セグメント）/ 12（ウィンドウ）/ 50%（文字盤）
**影**: ウィンドウ `0 60px 110px -30px rgba(0,0,0,0.9)`

## Assets
画像アセットはなし。すべて図形とテキストで構成。
フォントのみ外部依存: Google Fonts の **Archivo**（400/500/600/700/800）。
ネイティブ実装ではフォントをバンドルすること（ライセンス: SIL Open Font License 1.1）。
検討用セクション `5f` では比較のため Sora / Saira / JetBrains Mono も読み込んでいるが、製品では不要。

## Files
- `screenshots/main-window.png` — メインウィンドウ（実装対象）の実寸2倍キャプチャ
- `screenshots/font-weight-comparison.png` — 書体・ウェイト比較（検討記録。実装対象外）
- `Clock Mac App.dc.html` — デザイン本体。`5a` がメインウィンドウ（実装対象）、`5f` は書体比較用の検討パーツ
- `support.js` — HTML をブラウザで開くためのランタイム。実装には不要（同じフォルダに置けばそのまま開ける）

ブラウザで `Clock Mac App.dc.html` を開くと実時刻で動作し、フッターでウェイトを切り替えられます。
