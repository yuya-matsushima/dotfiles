# Recording Guide (Hammerspoon 版) 追加計画

## ステータス: 未着手

**予定ブランチ**: `feat/add-recording-guide`
**由来**: `fillin/recording-guide-app` リポジトリの Swift 版 spec (`docs/specs/recording-guide-app.md`) を Hammerspoon に移植したもの。

## 概要

32 インチ 4K ディスプレイ上に、YouTube 録画用の 1920×1080 ピクセル相当の作業領域を常時表示する Hammerspoon モジュールを追加する。OBS では 4K ディスプレイ全体をキャプチャし、本モジュールが示す 1920×1080 領域だけをクロップして録画する。

Swift + Xcode で新規アプリを立ち上げる代わりに、既存の Hammerspoon 設定 (`.hammerspoon/init.lua`) にモジュールを 1 本足すだけで実現する。

## 背景

### 元の要求（Swift 版 spec のサマリ）

- 画面上に物理ピクセル換算で 1920×1080 の録画領域を表示
- 録画領域外を半透明の黒で暗くする
- 領域内はクリック透過（背面の VS Code / Terminal / ブラウザを通常操作可能）
- 常時最前面
- メニューバー常駐（Dock 非表示）
- OBS クロップ値（Left/Top/Right/Bottom）をクリップボードにコピー
- Retina スケーリング対応

### なぜ Hammerspoon 版か

- Swift/SwiftUI + AppKit で新規アプリを立ち上げるより、Hammerspoon の `hs.canvas` / `hs.menubar` / `hs.screen` を使う方が実装量・環境コストが桁違いに少ない
- 既存の `~/.hammerspoon/init.lua` に既に IME 切替やアプリトグルが載っており、dotfiles で管理されている
- Xcode / xcodebuild / コード署名まわりの手間がゼロ
- 100〜150 行程度の Lua 1 ファイルで MVP が閉じる

## 設定構造

```
.hammerspoon/
├── init.lua              # 末尾に require("recording_guide") を追加
└── recording_guide.lua   # 新規モジュール（本 spec の実装対象）
```

Spoon 化はしない。既存 `init.lua` と同じ「素の Lua モジュール + `require`」パターンに寄せる。

## MVP 機能

### 1. 録画領域の表示

- 対象ディスプレイ全体を覆う `hs.canvas` を 1 枚生成
- 中央に 1920×1080 相当の透明な抜き領域を描画
- 抜き領域外は半透明の黒（デフォルト opacity 0.55）
- 抜き領域の境界線を表示（デフォルト 3pt）

### 2. クリック透過

`hs.canvas` の `canvasMouseEvents` を全 false に設定し、背面アプリへマウスイベントを完全に透過させる。

```lua
canvas:canvasMouseEvents(false, false, false, false)
```

### 3. 常時最前面 + 全 Space 表示

```lua
canvas:level(hs.canvas.windowLevels.overlay)
canvas:behavior({
    hs.canvas.windowBehaviors.canJoinAllSpaces,
    hs.canvas.windowBehaviors.stationary,
    hs.canvas.windowBehaviors.fullScreenAuxiliary,
})
```

### 4. メニューバー常駐

`hs.menubar.new()` でアイコンを作成し、以下の項目を提供する:

- Show Guide
- Hide Guide
- Center Guide
- Toggle Outside Dimming
- Copy OBS Crop Values
- (Quit は Hammerspoon 自体の常駐なので不要)

### 5. Retina 対応

`hs.screen` から `frame`（ポイント）と物理解像度（`mode().w` / `mode().h`）を取得し、両者の比率でスケール係数を求める。録画領域は物理ピクセルで 1920×1080 になるようポイント換算する。

```lua
local screen = hs.screen.mainScreen()
local frame  = screen:frame()          -- ポイント単位
local mode   = screen:currentMode()    -- mode.w / mode.h が物理ピクセル
local scaleX = mode.w / frame.w
local scaleY = mode.h / frame.h
local guideWpt = 1920 / scaleX
local guideHpt = 1080 / scaleY
```

macOS の「拡大表示」でも `currentMode()` から実サイズを取れるため、単純な `backingScaleFactor` より安全。

### 6. OBS クロップ値のコピー

対象ディスプレイのキャプチャ解像度と録画領域の位置から Left / Top / Right / Bottom をピクセル単位で算出し、以下の書式で `hs.pasteboard.setContents()` にセットする。

```text
OBS Crop
Left: 960
Top: 540
Right: 960
Bottom: 540
Output: 1920x1080
```

### 7. 設定の永続化

`hs.settings.set()` / `hs.settings.get()` を使い、以下を保存する:

- `dimOutside` (bool, default true)
- `dimOpacity` (float, default 0.55)
- `borderWidth` (float, default 3)
- `outputWidth` (int, default 1920)
- `outputHeight` (int, default 1080)

MVP では設定 UI は用意せず、値の変更は init.lua 内で定数を書き換える運用でよい。

## モジュール API 案

`recording_guide.lua` は require 時に即座にメニューバーを常駐させる副作用型モジュールとし、テーブルを返して外部から `show()` / `hide()` / `toggle()` / `copyCrop()` を叩けるようにする。

```lua
local M = require("recording_guide")
M.show()
M.hide()
M.toggle()
M.copyCrop()
```

## init.lua 変更

末尾に 1 行追加するだけ。

```lua
require("recording_guide")
```

既存のコードには一切触らない。

## bin/link.sh 変更

`.hammerspoon` は既に TARGETS に含まれているはずなので、変更は不要。念のため確認する（含まれていなければ追加）。

## 手動テスト項目

### 起動

- [ ] `hs.reload()` でエラーが出ない
- [ ] メニューバーにアイコンが表示される
- [ ] Dock アイコンが増えない

### ガイド表示

- [ ] Show Guide で 1920×1080 相当の透明領域 + 半透明暗幕が表示される
- [ ] Hide Guide で消える
- [ ] Center Guide でメインディスプレイ中央に移動する
- [ ] 境界線が視認できる
- [ ] Toggle Outside Dimming で暗幕の on/off が切り替わる
- [ ] 録画領域内をクリックしても背面アプリ（VS Code / Terminal / ブラウザ）が通常操作できる
- [ ] 録画領域外の暗幕部分をクリックしても背面が反応する（完全透過）

### ディスプレイ

- [ ] 4K ディスプレイ中央に配置される
- [ ] Space を切り替えてもガイドが表示され続ける
- [ ] フルスクリーンアプリを開いても消えない（`fullScreenAuxiliary`）
- [ ] ディスプレイを抜き差ししてもクラッシュしない（`hs.screen.watcher` で再計算するのが理想、MVP では手動 `hs.reload()` でも可）

### OBS 連携

- [ ] Copy OBS Crop Values でクリップボードに指定書式がコピーされる
- [ ] コピーされた値を OBS の Crop に貼って、ガイド枠と録画範囲が一致する
- [ ] OBS 出力が 1920×1080 になり、文字がぼやけない

## ファイル一覧

### 新規作成（2 ファイル）

- `.hammerspoon/recording_guide.lua` — モジュール本体（100〜150 行想定）
- `docs/plans/add-recording-guide.md` — 本計画ドキュメント

### 変更（1 ファイル）

- `.hammerspoon/init.lua` — 末尾に `require("recording_guide")` を 1 行追加

## 設計判断

### なぜ Spoon にしないか

- 既存の `.hammerspoon/hs/spaces.lua` や `init.lua` は素の Lua モジュールで統一されている
- Spoons/ ディレクトリは現状空で、Spoon の慣例に従うメリットが薄い
- 個人利用の単一機能を配布する意図がない
- `require` 1 行で無効化できるシンプルさを優先

### なぜ `hs.canvas` か（`hs.drawing` ではなく）

- `hs.drawing` は deprecated 扱いで、公式は `hs.canvas` を推奨
- `canvas:canvasMouseEvents()` で完全なクリック透過制御が可能
- 抜き領域（even-odd fill）を素直に描ける

### なぜ `currentMode()` ベースのスケーリングか

- `backingScaleFactor` だけだと macOS の「拡大表示」で物理ピクセルと一致しない
- Retina 環境下でも `mode.w / frame.w` は実際のスケール比を返すため、OBS のクロップ値と一致しやすい

### なぜ MVP に設定 UI を作らないか

- 個人利用のため、値の変更は init.lua で定数を書き換えれば十分
- メニューバーに設定項目を並べ始めるとメニュー階層が膨らむ
- 必要になった時点で `hs.dialog` などで追加可能

## 元 spec との差分

`fillin/recording-guide-app` の Swift 版 spec からスコープを外した項目:

- **Xcode プロジェクト構成** — Hammerspoon には不要
- **AppDelegate / NSPanel サブクラス** — `hs.canvas` に置換
- **UserDefaults** — `hs.settings` に置換
- **README / アーキテクチャドキュメント** — 本 plan ドキュメントに集約
- **Quit メニュー** — Hammerspoon 本体が常駐するため不要

Swift 版 spec の「12. Claude Code への実装指示」以降は Hammerspoon 版では読み替え不要。

## ロールバック方法

問題が発生した場合:

1. `.hammerspoon/init.lua` から `require("recording_guide")` の 1 行を削除
2. `.hammerspoon/recording_guide.lua` を削除
3. `hs.reload()`

依存追加は無いため、`brew` 側の変更は発生しない。

## 参考リンク

- [Hammerspoon hs.canvas](https://www.hammerspoon.org/docs/hs.canvas.html)
- [Hammerspoon hs.menubar](https://www.hammerspoon.org/docs/hs.menubar.html)
- [Hammerspoon hs.screen](https://www.hammerspoon.org/docs/hs.screen.html)
- [Hammerspoon hs.pasteboard](https://www.hammerspoon.org/docs/hs.pasteboard.html)
- [Hammerspoon hs.settings](https://www.hammerspoon.org/docs/hs.settings.html)
- 元 spec: `../../fillin/recording-guide-app/docs/specs/recording-guide-app.md`
