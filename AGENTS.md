# Repository Guidelines

このドキュメントは macOS 向け dotfiles リポジトリに貢献する際の指針です。作業前に各セクションを確認し, ローカル環境での検証結果を明記してください。

## リポジトリ概要

これは macOS 開発環境用の dotfiles リポジトリです。
Symbolic link を通じて各種ツールやアプリケーションの設定ファイルを管理し, 自動インストールスクリプトを提供しています。

## Language Instruction
- すべての回答は日本語で記述すること。
- 内部の思考プロセスやメモ, 構成検討は英語で行ってよいが, ユーザー向けレスポンスには含めないこと。
- 特定の言語やツールに対応した回答を求められた場合は, その言語やツールに関する知識を活用して回答してください。

## プロジェクト構成とモジュール整理
- ルートの `Makefile` がセットアップ全体を統括します。利用可能なターゲットは `make help` で確認します。
- `bin/` には POSIX 準拠のシェルスクリプトを配置し, `homebrew.sh` や `link.sh` が初期構築を担当します。言語別の asdf インストーラーは `bin/asdf/` にまとめます。
- `coding-agents/` は AI コーディングエージェント (Claude, Codex, Gemini) の設定を管理する private submodule です。取得には SSH 認証が必要です。
- UI 設定は `iterm2/`, `KensingtonWorks/`, キーボードレイアウトは `via/` に置きます。
- 環境変数テンプレートは `envrc.template` にあり, 機密値は Git 管理外のローカル `.envrc` へ記録します。
- `tmp/` や `feature/` は作業用ディレクトリです。生成物や個人設定はコミット対象から除外してください。
- それぞれのツールの設定ファイルは `$HOME` ディレクトリに配置した際のファイル名やディレクトリ構造に基づいて配置されています。
- 例外として `_.gitignore` は Symbolic link 作成時に `.gitignore` としてリンクされます。

## ビルド・テスト・開発コマンド
- `make help` : サポートされるターゲットと概要を一覧表示します。
- `make setup` : 本機用フルセットアップ (Homebrew, アプリ, シンボリックリンク, asdf 一式) を実行します。
- `make setup_develop` : 開発機向けの軽量構成を導入します。
- `make link` / `make unlink` : `$HOME` 配下へシンボリックリンクを張る／解除します。
- `make asdf_update` : asdf プラグインを最新化します。ランタイム更新時に再実行してください。

## コーディングスタイルと命名規則
- スクリプトは `/bin/sh` シバンと `set -e` を基本とし, 四スペースインデントを推奨します。
- ファイル名は小文字 + アンダースコアで統一し, コマンド名は動作を端的に表す (例: `mac.sh`, `link.sh`) ようにします。
- シンボリックリンク時のリネームが必要な場合は `_.gitignore` のように先頭アンダースコアで表現し, リンク後の実ファイル名を推測しやすくします。

## テスト方針
- 新規スクリプトは `sh -n bin/<script>.sh` で文法チェックし, `make <target>` による実行検証を行います。
- 設定ファイル変更後は `make link` で再リンクし, `source ~/.zshrc` や iTerm2 プロファイル再読み込みなど対象ツールで動作確認します。
- 可能であれば `shellcheck` を走らせ, 手動検証が必要な場合は PR に再現手順と結果を添えてください。

## 設定ファイル変更時の注意点
- 設定ファイルを変更した場合, そのツールの設定として問題ないか必ず確認してください。
  - 例えば `.zshrc` の場合 zsh 上で `source ~/.zshrc` を実行しエラーがないことを確認する必要があります。

## ローカル設定ファイル

マシン固有の設定や dotfiles リポジトリで管理したくない設定は, ローカル設定ファイルで管理できます。

### Vim

`~/.vimrc_local` を作成すると, `.vimrc` の読み込み後に自動的に source されます。

```vim
" 例: マシン固有のキーマップ
nnoremap <leader>local :echo "Local setting"<CR>
```

### Neovim

`~/.nvim_local.lua` を作成すると, `init.lua` の読み込み後に自動的に実行されます。

```lua
-- 例: オプションの上書き
local opt = vim.opt
opt.number = false

-- 例: カスタムキーマップ
local map = vim.keymap.set
map('n', '<leader>local', ':echo "Local setting"<CR>', { noremap = true })

-- 例: オートコマンド
local autocmd = vim.api.nvim_create_autocmd
autocmd('BufWritePre', {
  pattern = '*.custom',
  callback = function()
    -- カスタム処理
  end,
})
```

**注意事項**:
- これらのファイルはローカル環境専用であり, git 管理対象外です
- `.nvim_local.lua` は Lua 構文で記述する必要があります (VimScript は使用できません)
- プラグインの追加は lazy.nvim の仕組み上困難です (既存プラグインの設定上書きは可能)

### VimR

`~/.ginit_local.vim` を作成すると, `ginit.vim` の読み込み後に自動的に source されます。

```vim
" 例: VimR 固有のフォント設定
VimRSetFontAndSize "SF Mono", 16
VimRSetLinespacing 1.2
```

**注意事項**:
- VimR は Neovim の GUI クライアントのため, `~/.config/nvim/init.lua` の設定を共有します
- `ginit.vim` は VimScript で記述する必要があります (Lua は使用できません)
- VimR 固有のコマンドは `VimRSetFontAndSize` と `VimRSetLinespacing` のみです

## コミットとプルリクエスト指針
- ブランチは用途別に `feature/<slug>`, `fix/<slug>`, `docs/<slug>`, `refactor/<slug>` を使用します。
- コミットメッセージは履歴に倣い `feat:` や `fix:` などの種別プレフィックスを付け, 必要に応じてチケット番号を `(例: feat: add new fzf helpers (#42))` の形式で追記します。
- 1 行目は 50 文字以内に収め, 詳細は箇条書きで記述します。英語／日本語いずれも可ですが統一性を意識してください。
- PR ではセットアップや検証手順を明記し, 関連 Issue, UI 変更時のスクリーンショットやログを添付します。
- PR 作成時は以下のコマンドを利用できます。

```bash
gh pr create --title "タイトル" --body "本文" --assignee @me
```

## Git 運用ルール
- main ブランチへの直接 push は禁止
- 機能追加の場合には `feature/${branch_name}` ブランチを作成
- バグ修正の場合には `fix/${branch_name}` ブランチを作成
- ドキュメント更新の場合には `docs/${branch_name}` ブランチを作成
- リファクタリングの場合には `refactor/${branch_name}` ブランチを作成

## 開発フロー
1. main ブランチから新しいブランチを作成
2. 変更を実施
3. Pull Request を作成
4. レビュー完了後に main ブランチへマージ

## セキュリティと設定のヒント
- トークンや生成ファイルをコミットしないでください。秘密情報はローカル `.envrc` または未追跡ディレクトリで管理します。
- インストーラースクリプトの外部ダウンロードはバージョン固定を検討し, ブートストラップの再現性を保ってください。
