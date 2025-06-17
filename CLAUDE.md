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

🤖 Generated with Claude Code
```

**注意**: リンクやCo-Authored-Byは追加しないでください。

### Pull Request 作成時の設定

Claude Code で PR を作成する際は、以下の設定を行ってください:

* Assignee に作業者を追加（pushしたユーザーとPRの作業者を一致させる）
* label に `Claude Code` を追加
* GitHub Copilot をレビュワーとして追加（Web UIで手動設定）

```bash
gh pr create --title "タイトル" --body "本文" --assignee @me --label "Claude Code"
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