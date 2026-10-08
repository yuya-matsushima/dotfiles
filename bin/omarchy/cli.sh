#!/bin/sh

# Linux (omarchy / Arch) 向け CLI ツール導入。
# macOS 側 bin/homebrew/cli.sh (および app.sh の formula) と同じ CLI 環境を
# omarchy に用意するための Linux 版。パッケージ名は Arch 側の名称に読み替える。
#
# omarchy base (`/usr/share/omarchy/install/omarchy-base.packages`) が既に導入する
# パッケージは二重管理を避けるため含めない。ここに列挙するのは base に無いものだけ。
#
# 使い方: sh bin/omarchy/cli.sh  (通常は make omarchy 経由で実行される)

set -e

if [ "$(uname -s)" != "Linux" ]; then
    echo "cli.sh: this script is for Linux only" >&2
    exit 1
fi

# 公式リポジトリ (core / extra / omarchy) のパッケージを導入する。
install_official() {
    if command -v omarchy >/dev/null 2>&1; then
        omarchy pkg add "$@"
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm "$@"
    else
        echo "cli.sh: no supported package manager (omarchy/pacman) found" >&2
        exit 1
    fi
}

# AUR のパッケージを導入する。AUR ヘルパー (omarchy/yay) が無ければ skip する。
install_aur() {
    if command -v omarchy >/dev/null 2>&1; then
        omarchy pkg aur add "$@"
    elif command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm "$@"
    else
        echo "cli.sh: omarchy/yay not found; skip AUR packages: $*" >&2
        return 0
    fi
}

# Homebrew (bin/homebrew/cli.sh) のうち, omarchy base に無い Arch パッケージ。
# Arch 名 (対応する Homebrew ツール):
#   erdtree (erdtree)
#
# omarchy base が導入するため含めないもの:
#   bat eza fd fzf imagemagick jq nvim(neovim) postgresql-libs(libpq)
#   qrencode ripgrep tldr(tealdeer 相当) tmux tree-sitter-cli zoxide
#   ffmpeg poppler: base パッケージ (ffmpegthumbnailer / evince 等) の依存で導入済み
#
# その他の除外:
#   git curl make grep ncurses: base / base-devel で導入済み
#   gnu-sed: Linux の sed は GNU sed のため不要
#   mise: omarchy の mise-bin で導入済み
#   direnv: mise で代替するため不要
#   gh opencode uv: mise (.config/mise/config.toml) で管理
#   htop mariadb-clients: 未使用のため不要
#   zsh-git-prompt: bin/zsh_plugin.sh が woefe 版 git-prompt.zsh を取得
#   pngpaste font-symbols-only-nerd-font: macOS 専用
install_official \
    zsh \
    zsh-completions \
    colordiff \
    ctags \
    erdtree \
    git-delta \
    gitleaks \
    jnv \
    resvg \
    sd \
    stern \
    wget \
    7zip

# 公式リポジトリに無いツールは AUR から導入する。
# Arch (対応する Homebrew ツール):
#   diff-pdf-git (diff-pdf) / github-copilot-cli-bin (cask copilot-cli)
install_aur \
    diff-pdf-git \
    github-copilot-cli-bin
