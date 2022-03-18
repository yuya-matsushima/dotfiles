#/bin/sh

set -e

brew tap homebrew/cask-fonts
brew tap gjbae1212/gossm

brew install \
          asdf \
          awsume \
          bison \
          colordiff \
          ctags \
          curl \
          direnv \
          gh \
          git \
          git-secrets \
          glow \
          gnu-sed \
          gossm \
          grep \
          htop \
          jq \
          make \
          mysql-client \
          peco \
          plantuml \
          rename \
          the_silver_searcher \
          tig \
          tldr \
          tmux \
          tree \
          wget \
          zsh \
          zsh-completions \
          zsh-git-prompt

brew install --cask \
          font-ricty-diminished \
          iterm2 \
          keycastr \
          macvim
