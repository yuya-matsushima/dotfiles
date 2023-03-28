#!/bin/sh

if [ -f ~/.zsh/git-prompt.zsh ]; then
  rm ~/.zsh/git-prompt.zsh
fi

wget -P ~/.zsh/ https://raw.githubusercontent.com/woefe/git-prompt.zsh/master/git-prompt.zsh
