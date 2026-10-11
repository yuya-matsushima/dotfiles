#!/bin/sh

# Linux (omarchy / Arch) bootstrap for this dotfiles repository.
# macOS 側の bin/homebrew*.sh に相当する Linux 版。
# Package 導入とログインシェルの zsh 化を行う。

set -e

if [ "$(uname -s)" != "Linux" ]; then
    echo "omarchy.sh: this script is for Linux only" >&2
    exit 1
fi

# .zshrc / .vimrc 等が必要とする CLI ツールを導入する
# (go は mise 管理のため含めない)
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
sh "$SCRIPT_DIR/omarchy/cli.sh"

# fcitx5 の IM 構成 (keyboard-us + mozc) を配置
sh "$SCRIPT_DIR/omarchy/fcitx5.sh"

# ログインシェルを zsh に変更
ZSH_PATH=$(command -v zsh || true)
if [ -z "$ZSH_PATH" ]; then
    echo "omarchy.sh: zsh not found after install" >&2
    exit 1
fi

CURRENT_LOGIN_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [ "$CURRENT_LOGIN_SHELL" = "$ZSH_PATH" ]; then
    echo "omarchy.sh: login shell is already $ZSH_PATH"
elif ! grep -qx "$ZSH_PATH" /etc/shells; then
    echo "omarchy.sh: add $ZSH_PATH to /etc/shells before chsh" >&2
elif [ -t 0 ]; then
    # chsh は PAM でパスワードを要求するため対話端末で実行する必要がある
    chsh -s "$ZSH_PATH"
else
    echo "omarchy.sh: run 'chsh -s $ZSH_PATH' in an interactive shell to change the login shell" >&2
fi

echo "omarchy bootstrap done. Run 'make link' to create symlinks."
