# Copilot Instructions

このリポジトリは macOS 開発環境用の dotfiles です。
Symbolic link を通じて各種ツールやアプリケーションの設定ファイルを管理しています。

## 言語指示

- 回答・コメント・ドキュメントはすべて日本語で記述すること。
- 内部の思考プロセスやメモ、構成検討は英語で行ってよいが、ユーザー向けレスポンスには含めないこと。

## セットアップとビルドコマンド

### 初回セットアップ

```sh
# 本機用フルセットアップ (Homebrew, アプリ, シンボリックリンク, asdf 一式)
make setup

# 開発機向けの軽量構成
make setup_develop
```

### よく使うコマンド

```sh
make help              # 利用可能なターゲットと概要を一覧表示
make link              # $HOME 配下へシンボリックリンクを作成
make unlink            # シンボリックリンクを解除
make asdf_update       # asdf プラグインを最新化
make nvim_plugin       # Neovim プラグインをインストール
make nvim_test         # Neovim 設定の健全性チェック
```

### 設定ファイル変更後の検証

```sh
# スクリプト文法チェック
sh -n bin/<script>.sh

# Zsh 設定の再読み込み
source ~/.zshrc

# Neovim 設定の健全性チェック
nvim --headless "+checkhealth" +qa
```

## プロジェクト構成と設計原則

### ディレクトリ構造

- `bin/` — セットアップスクリプト群。`homebrew.sh`, `link.sh` が初期構築を担当。言語別 asdf インストーラーは `bin/asdf/` に配置。
- `.config/nvim/` — Neovim 設定 (Lua)。プラグイン管理は lazy.nvim、プラグイン定義は `lua/plugins/` に 1 プラグイン 1 ファイルで配置。
- `.config/ghostty/` — Ghostty ターミナル設定 (メイン端末)。
- `.config/yazi/` — Yazi ファイルマネージャ設定。
- `.config/lazygit/` — Lazygit 設定。
- `.hammerspoon/` — Hammerspoon 設定 (Lua)。`hs/` にモジュール分割、`init.lua` がエントリポイント。
- `iterm2/`, `KensingtonWorks/`, `via/` — UI 設定やキーボードレイアウト。
- `tmp/`, `feature/` — 作業用ディレクトリ。生成物や個人設定はコミット対象外。

### 設計原則

- 各設定ファイルは `$HOME` に配置した際のパス構造に基づいて整理されている。
- **例外**: `_.gitignore` は Symbolic link 作成時に `.gitignore` としてリンクされる（先頭 `_` はリネーム規則）。
- Submodule を含むため、クローン時は `git clone --recursive` または `git submodule update --init --recursive` を実行。

### ローカル設定ファイル

マシン固有の設定や dotfiles リポジトリで管理したくない設定は、ローカル設定ファイルで管理できます:

- **Vim**: `~/.vimrc_local` (VimScript)
- **Neovim**: `~/.nvim_local.lua` (Lua のみ、VimScript 不可)
- **VimR**: `~/.ginit_local.vim` (VimScript のみ)
- **環境変数**: `.envrc` (Git 管理外、`envrc.template` をテンプレートとして使用)

これらのファイルはローカル環境専用であり、Git 管理対象外です。

## コーディングスタイル

### シェルスクリプト

- シバンは `/bin/sh` + `set -e` を基本とする。配列等の bash 機能が必要な場合のみ `#!/bin/bash` を使用。
- 4 スペースインデント。
- ファイル名は小文字 + アンダースコア (例: `mac.sh`, `link.sh`)。

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

### 共通ルール

- デフォルトインデントは 2 スペース（シェルスクリプトのみ 4 スペース）。
- Vim キーバインドを多用する環境であることを考慮する。
- コメントは必要最小限に (明らかでないロジックのみ)。

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

## Git 運用ルール

- main ブランチへの直接 push は禁止。
- **コードや設定ファイルに変更を加える前に、必ず適切なブランチを作成すること** (main 上での変更開始は禁止)。
- ブランチ命名規則: `feature/<slug>`, `fix/<slug>`, `docs/<slug>`, `refactor/<slug>`
- コミットメッセージは `feat:`, `fix:`, `docs:`, `refactor:` などのプレフィックスを付ける。
- 1 行目は 50 文字以内、詳細は箇条書きで記述。英語／日本語いずれも可。
- PR 作成: `gh pr create --title "タイトル" --body "本文" --assignee @me`

## テストと検証

- 新規スクリプトは `sh -n bin/<script>.sh` で文法チェック、`make <target>` で動作検証。
- 設定ファイル変更後は `make link` で再リンクし、対象ツールで動作確認:
  - Zsh: `source ~/.zshrc`
  - Neovim: `nvim --headless "+checkhealth" +qa` または `make nvim_test`
  - iTerm2: プロファイル再読み込み
- 可能であれば `shellcheck` を実行。

## セキュリティ

- トークン・秘密情報・API キーをコードに含めないこと。
- 機密値は `envrc.template` をテンプレートとして使い、Git 管理外のローカル `.envrc` で管理する。
- インストーラースクリプトの外部ダウンロードはバージョン固定を検討し、ブートストラップの再現性を保つ。

## 関連ドキュメント

- `@AGENTS.md` — リポジトリ全体の貢献ガイドライン (詳細版)
- `@CLAUDE.md` — Claude Code 固有の推奨設定
- `@README.md` — プロジェクト概要とセットアップ手順
