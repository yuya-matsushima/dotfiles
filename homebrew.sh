#/bin/sh

set -e

brew install \
          anyenv \
          awscli \
          awsume \
          colordiff \
          ctags \
          curl \
          direnv \
          gh \
          git \
          git-secrets \
          glow \
          gnu-sed \
          go \
          golangci-lint \
          gossm \
          grep \
          htop \
          jq \
          make \
          mysql-client \
          peco \
          plantuml \
          rename \
          terraformer \
          tfenv \
          tflint \
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


if [ ! -d $HOME/.config/anyenv/anyenv-install ]; then
  anyenv install --init
fi
# ruby
if [ ! -d $HOME/.anyenv/envs/rbenv ]; then
  anyenv install rbenv
  exec $SHELL -l
fi
RUBY_VERSION=`rbenv install --list-all | grep -v - | tail -1`
if [ ! -d $HOME/.anyenv/envs/rbenv/versions/$RUBY_VERSION ]; then
  rbenv install $RUBY_VERSION
  rbenv global $RUBY_VERSION
fi

# node
if [ ! -d $HOME/.anyenv/envs/nodenv ]; then
  anyenv install nodenv
  exec $SHELL -l
fi
NODE_VERSION=`nodenv install -l | grep -v - | grep -v nightly | grep -v rc | tail -1`
if [ ! -d $HOME/.anyenv/envs/nodenv/versions/$NODE_VERSION ]; then
  nodenv install $NODE_VERSION
  nodenv global $NODE_VERSION
fi
