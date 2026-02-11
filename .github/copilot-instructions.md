# Copilot Instructions

このリポジトリは macOS 開発環境用の dotfiles です。
Symbolic link を通じて各種ツールやアプリケーションの設定ファイルを管理しています。

## 言語指示

- 回答・コメント・ドキュメントはすべて日本語で記述すること。

## プロジェクト構成

- `bin/` — 基本は POSIX sh だが、一部 (`link.sh` 等) は `#!/bin/bash` を使用。`homebrew.sh`, `link.sh` 等が初期構築を担当。言語別 asdf インストーラーは `bin/asdf/` に配置。
- `.config/nvim/` — Neovim 設定 (Lua)。プラグイン管理は lazy.nvim、プラグイン定義は `lua/plugins/` に 1 プラグイン 1 ファイルで配置。
- `.config/ghostty/` — Ghostty ターミナル設定。
- `.config/yazi/` — Yazi ファイルマネージャ設定。
- `.config/lazygit/` — Lazygit 設定。
- `.hammerspoon/` — Hammerspoon 設定 (Lua)。`hs/` にモジュール分割、`init.lua` がエントリポイント。
- 各設定ファイルは `$HOME` に配置した際のパス構造に基づいて整理されている。
- 例外: `_.gitignore` は Symbolic link 作成時に `.gitignore` としてリンクされる（先頭 `_` はリネーム規則）。

## コーディングスタイル

### シェルスクリプト

- シバンは `/bin/sh` + `set -e` を基本とする。配列等の bash 機能が必要な場合のみ `#!/bin/bash` を使用。
- 4 スペースインデント。
- ファイル名は小文字 + アンダースコア（例: `mac.sh`, `link.sh`）。

### Neovim (Lua)

- プラグインマネージャ: lazy.nvim。
- `lua/plugins/` に 1 ファイル 1 プラグイン（またはプラグイングループ）で配置。
- Neovim 0.11+ のネイティブ LSP API (`vim.lsp.*`) を使用。
- 2 スペースインデント。

### Zsh

- Vi キーバインドを使用。
- 旧来コマンドは Rust 製代替を優先: `eza`（ls）, `fd`（find）, `rg`（grep）, `bat`（cat）, `zoxide`（cd）。
- 2 スペースインデント。

### Hammerspoon (Lua)

- `hs.*` API を使用。
- 日本語コメントで記述。
- 2 スペースインデント。

### 共通

- デフォルトインデントは 2 スペース（シェルスクリプトのみ 4 スペース）。
- Vim キーバインドを多用する環境であることを考慮する。

## 技術スタック

- **OS**: macOS
- **ターミナル**: Ghostty（メイン）, Alacritty（移行中）
- **シェル**: Zsh + Tmux
- **エディタ**: Neovim（メイン）, Vim（互換用）, VimR（GUI）
- **パッケージマネージャ**: Homebrew
- **ランタイム管理**: asdf
- **ファイルマネージャ**: Yazi
- **Git UI**: Lazygit
- **キーボード自動化**: Hammerspoon

## セキュリティ

- トークン・秘密情報・API キーをコードに含めないこと。
- 機密値は `envrc.template` をテンプレートとして使い, Git 管理外のローカル `.envrc` で管理する。
