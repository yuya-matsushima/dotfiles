# CLAUDE.md

このファイルは, このリポジトリでコードを扱う際のClaude Code (claude.ai/code) への指針を提供します。

## リポジトリ概要

これは MacOS 開発環境用の dotfiles リポジトリです。
Symbolic link を通じて各種ツールやアプリケーションの設定ファイルを管理し, 自動インストールスクリプトを提供しています。

### 設定用コマンド

`make help` コマンドを実行すると, 利用可能なコマンドの一覧が表示されます。

### ディレクトリ構造

それぞれのツールの設定ファイルは `$HOME`  ディレクトリに配置した際のファイル名やディレクトリ構造に基づいて配置されています。
例外として `_.gitignore` は Symbolic link 作成時に `.gitignore` としてリンクされます。

### 設定ファイル変更時の注意点

* 設定ファイルを変更した場合, そのツールの設定として問題ないか必ず確認してください。
    * 例えば `.zshrc` の場合 zsh 上で `source ~/.zshrc` を実行しエラーがないことを確認する必要があります。

### ローカル設定ファイル

マシン固有の設定や dotfiles リポジトリで管理したくない設定は, ローカル設定ファイルで管理できます。

#### Vim

`~/.vimrc_local` を作成すると, `.vimrc` の読み込み後に自動的に source されます。

```vim
" 例: マシン固有のキーマップ
nnoremap <leader>local :echo "Local setting"<CR>
```

#### Neovim

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

#### VimR

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

## Git 運用ルール

### ブランチ運用

* main ブランチへの直接 push は禁止
* 機能追加の場合には `feature/${branch_name}` ブランチを作成
* バグ修正の場合には `fix/${branch_name}` ブランチを作成
* ドキュメント更新の場合には `docs/${branch_name}` ブランチを作成
* リファクタリングの場合には `refactor/${branch_name}` ブランチを作成

### 開発フロー

1. main ブランチから新しいブランチを作成
2. 変更を実施
3. Pull Request を作成
4. レビュー完了後に main ブランチへマージ

### コミットメッセージのフォーマット

**重要**: Claude Codeでコミット作成時は必ずこのフォーマットに従ってください:

```
タイトル (50文字以内)

- 変更内容の詳細説明
- 箇条書きで記載
```

### Pull Request 作成時の設定

Claude Code で PR を作成する際は、以下の設定を行ってください:

* Assignee に作業者を追加（pushしたユーザーとPRの作業者を一致させる）
* GitHub Copilot をレビュワーとして追加（Web UIで手動設定）

```bash
gh pr create --title "タイトル" --body "本文" --assignee @me
```

**注意**: GitHub CopilotのレビュワーはCLIから設定できないため、PR作成後にWeb UIで手動追加してください。

## Claude Code の推奨設定

新しい環境でClaude Codeをセットアップする際は以下の設定を推奨:

```bash
# ターミナルベル通知を有効化
claude config set --global preferredNotifChannel terminal_bell

# Vimモードを有効化
claude config set --global editorMode vim
```
