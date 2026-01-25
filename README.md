## dotfiles

このリポジトリは Yuya MATSUSHIMA の個人用 dotfiles を管理しています。
macOS 上での開発環境構築や設定の自動化を目的としています。

## コーディングスタイル

- ターミナルアプリは Ghostty がメインで、Alacritty から移行中です。
- Zsh 上で Tmux を使って作業します。
- CLI 上でもリッチな配色より、シンプルで見やすい表示を好みます。
- テキストエディタは Neovim をメインに使用し、互換性のため Vim 設定も保持しています。
- Vim キーバインドを多用します (Zsh, Tmux, Neovim など)。
- よく使うアプリケーションには Hammerspoon でキーボードショートカットを割り当てています。
- 旧来のコマンドは eza や dexide のような Rust 製アプリへ置き換える方針で、メリットがある場合は新しいツールを積極的に採用します。

## Submodule について

このリポジトリは private submodule を含んでいます。

### 初回クローン時

```sh
git clone --recursive git@github.com:yuya-matsushima/dotfiles.git
```

### 既存のクローンに submodule を取得

```sh
git submodule update --init --recursive
```

## セットアップ

```sh
# for Main Machine
make setup

# for Dev Machine
make develop
```
