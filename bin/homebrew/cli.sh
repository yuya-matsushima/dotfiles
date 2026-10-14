#!/bin/sh

set -e

brew tap gjbae1212/gossm

# OpenCode 2 は公式タップ (anomalyco/tap) の opencode-v2 を使う。core の `opencode`
# も V2 だが Homebrew チーム管理で更新が遅いため、公式のプリビルトバイナリを配る
# opencode-v2 を選ぶ。core の `opencode` とは conflicts_with のため、既に core を
# 入れている環境では先に `brew uninstall opencode` が必要。
brew install \
          mise \
          ast-grep \
          awsume \
          bat \
          colordiff \
          ctags \
          curl \
          diff-pdf \
          copilot-cli \
          git-delta \
          direnv \
          fd \
          eza \
          ffmpeg \
          gh \
          git \
          gitleaks \
          gnu-sed \
          gossm \
          grep \
          font-symbols-only-nerd-font \
          fzf \
          htop \
          lazygit \
          imagemagick \
          pngpaste \
          jq \
          jnv \
          yq \
          libpq \
          anomalyco/tap/opencode-v2 \
          pi-coding-agent \
          make \
          mysql-client \
          ncurses \
          neovim \
          poppler \
          qrencode \
          resvg \
          ripgrep \
          erdtree \
          sd \
          sevenzip \
          stern \
          tldr \
          tmux \
          tree-sitter-cli \
          uv \
          wget \
          zsh \
          zsh-completions \
          zsh-git-prompt \
          zoxide
