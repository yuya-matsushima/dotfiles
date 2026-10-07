#!/bin/sh

# Linux (omarchy / Arch) bootstrap for this dotfiles repository.
# macOS 側の bin/homebrew*.sh に相当する Linux 版。
# Package 導入とログインシェルの zsh 化を行う。

set -e

if [ "$(uname -s)" != "Linux" ]; then
    echo "omarchy.sh: this script is for Linux only" >&2
    exit 1
fi

# .zshrc / .vimrc 等が必要とする CLI ツール
# (go は mise 管理のためここには含めない)
PACKAGES="zsh direnv git-delta colordiff"

if command -v omarchy >/dev/null 2>&1; then
    omarchy pkg add $PACKAGES
elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm $PACKAGES
else
    echo "omarchy.sh: no supported package manager (omarchy/pacman) found" >&2
    exit 1
fi

# ログインシェルを zsh に変更
ZSH_PATH=$(command -v zsh || true)
if [ -n "$ZSH_PATH" ]; then
    if [ "$SHELL" != "$ZSH_PATH" ]; then
        if grep -qx "$ZSH_PATH" /etc/shells; then
            chsh -s "$ZSH_PATH"
        else
            echo "omarchy.sh: add $ZSH_PATH to /etc/shells before chsh" >&2
        fi
    fi
else
    echo "omarchy.sh: zsh not found after install" >&2
fi

echo "omarchy bootstrap done. Run 'make link' to create symlinks."
