# Neovim Cheat Sheet

このドキュメントは、現在の設定ファイル（`.config/nvim/`）に基づいたショートカットキーのまとめです。

**Leader Key:** `\` (デフォルト)

## 基本操作

| キー操作 | モード | 動作 | 設定元 |
|---|---|---|---|
| `Esc` `Esc` | Normal | 検索ハイライトをクリア | `config/keymaps.lua` |
| `;` ↔ `:` | Normal, Visual | `;` と `:` を入れ替え (US キーボード接続時のみ) | `config/keymaps.lua` |
| `:Sudow` | Command | sudo 権限でファイルを保存 | `config/keymaps.lua` |

## ファイル検索・移動 (Telescope)

| キー操作 | モード | 動作 | 設定元 |
|---|---|---|---|
| `<leader>ff` | Normal | ファイル検索 | `plugins/telescope.lua` |
| `<leader>fg` | Normal | テキスト全文検索 (Live Grep) | `plugins/telescope.lua` |
| `<leader>fb` | Normal | バッファ一覧 | `plugins/telescope.lua` |
| `<leader>fh` | Normal | ヘルプタグ検索 | `plugins/telescope.lua` |

## ファイラー (Oil)

| キー操作 | モード | 動作 | 設定元 |
|---|---|---|---|
| `-` | Normal | 親ディレクトリを開く | `plugins/oil.lua` |

## LSP (言語サーバー)

LSP がアタッチされたバッファでのみ有効です。

### ナビゲーション

| キー操作 | モード | 動作 | 設定元 |
|---|---|---|---|
| `gd` | Normal | 定義へジャンプ | `plugins/lsp.lua` |
| `gr` | Normal | 参照一覧を表示 | `plugins/lsp.lua` |
| `gi` | Normal | 実装へジャンプ | `plugins/lsp.lua` |
| `gt` | Normal | 型定義へジャンプ | `plugins/lsp.lua` |

### ドキュメント・アクション

| キー操作 | モード | 動作 | 設定元 |
|---|---|---|---|
| `K` | Normal | ホバードキュメントを表示 | `plugins/lsp.lua` |
| `F2` | Normal | シンボルをリネーム | `plugins/lsp.lua` |

### Diagnostics

| キー操作 | モード | 動作 | 設定元 |
|---|---|---|---|
| `gp` | Normal | 前の diagnostic へ移動 | `plugins/lsp.lua` |
| `gn` | Normal | 次の diagnostic へ移動 | `plugins/lsp.lua` |

## Git 操作

### Gitsigns (Hunk ナビゲーション)

| キー操作 | モード | 動作 | 設定元 |
|---|---|---|---|
| `]c` | Normal | 次の hunk へ移動 | `plugins/git.lua` |
| `[c` | Normal | 前の hunk へ移動 | `plugins/git.lua` |

### Diffview

| キー操作 | モード | 動作 | 設定元 |
|---|---|---|---|
| `<leader>gd` | Normal | Diffview を開く | `plugins/git.lua` |
| `<leader>gh` | Normal | ファイル履歴を表示 | `plugins/git.lua` |

## 補完 (nvim-cmp)

Insert モードで動作します。`<Tab>` は Copilot → スニペット → 補完メニュー → 手動トリガーの順でスマートに動作します。

| キー操作 | モード | 動作 | 設定元 |
|---|---|---|---|
| `Tab` | Insert, Select | Smart Tab: Copilot 受け入れ → スニペット展開 → 次の候補 → 補完トリガー | `plugins/completion.lua` |
| `Shift+Tab` | Insert, Select | 前の候補 / スニペットの前のプレースホルダーへ | `plugins/completion.lua` |
| `Ctrl+n` | Insert, Select | 次の補完候補 | `plugins/completion.lua` |
| `Ctrl+p` | Insert, Select | 前の補完候補 | `plugins/completion.lua` |
| `Enter` | Insert | 選択中の候補を確定 (未選択時は改行) | `plugins/completion.lua` |
| `Ctrl+Space` | Insert | 補完を手動トリガー | `plugins/completion.lua` |

## スニペット (LuaSnip)

| キー操作 | モード | 動作 | 設定元 |
|---|---|---|---|
| `Ctrl+K` | Insert, Select | スニペットを展開 | `plugins/snippets.lua` |
| `Ctrl+L` | Insert, Select | スニペット展開 / 次のプレースホルダーへジャンプ | `plugins/snippets.lua` |
| `Ctrl+H` | Insert, Select | 前のプレースホルダーへジャンプ | `plugins/snippets.lua` |

## Copilot

### サジェスト操作

| キー操作 | モード | 動作 | 設定元 |
|---|---|---|---|
| `Alt+]` | Insert | 次のサジェスト | `plugins/copilot.lua` |
| `Alt+[` | Insert | 前のサジェスト | `plugins/copilot.lua` |
| `Ctrl+]` | Insert | サジェストを却下 | `plugins/copilot.lua` |

> **Note:** サジェストの受け入れは `Tab` (Smart Tab) で行います。

### Copilot Chat

| キー操作 | モード | 動作 | 設定元 |
|---|---|---|---|
| `<leader>cc` | Normal | Copilot Chat の表示/非表示 | `plugins/copilot.lua` |
| `<leader>ce` | Normal, Visual | コードの説明 | `plugins/copilot.lua` |
| `<leader>cr` | Normal, Visual | コードレビュー | `plugins/copilot.lua` |
| `<leader>cf` | Normal, Visual | バグ修正 | `plugins/copilot.lua` |
| `<leader>co` | Normal, Visual | コード最適化 | `plugins/copilot.lua` |
| `<leader>cd` | Normal, Visual | ドキュメント生成 | `plugins/copilot.lua` |
| `<leader>ct` | Normal, Visual | テスト生成 | `plugins/copilot.lua` |

## Treesitter (選択範囲)

Operator-pending / Visual モードで動作します。

| キー操作 | モード | 動作 | 設定元 |
|---|---|---|---|
| `Ctrl+n` | Operator, Visual | 選択を開始 / 構文ノード単位で拡大 | `plugins/treesitter.lua` |
| `Ctrl+s` | Operator, Visual | スコープ単位で拡大 | `plugins/treesitter.lua` |
| `Ctrl+p` | Operator, Visual | 構文ノード単位で縮小 | `plugins/treesitter.lua` |

## Markdown

| キー操作 | モード | 動作 | 設定元 |
|---|---|---|---|
| `<leader>mp` | Normal | Markdown プレビューを開始 | `plugins/editor.lua` |
| `<leader>ms` | Normal | Markdown プレビューを停止 | `plugins/editor.lua` |
| `<leader>mt` | Normal | Markdown プレビューを切替 | `plugins/editor.lua` |
| `<leader>ml` | Normal | クリップボードの URL を Markdown リンクとしてペースト (Markdown ファイルのみ) | `config/keymaps.lua` |

## その他

| キー操作 | モード | 動作 | 設定元 |
|---|---|---|---|
| `qq` | Normal | QuickRun (現在のファイルを実行) | `plugins/editor.lua` |
| `Alt+e` | Insert | ペア文字で高速ラッピング (nvim-autopairs) | `plugins/editor.lua` |

---
**Configuration Files:**
- Entry point: `.config/nvim/init.lua`
- Options: `.config/nvim/lua/config/options.lua`
- Keymaps: `.config/nvim/lua/config/keymaps.lua`
- Plugins: `.config/nvim/lua/plugins/*.lua`
