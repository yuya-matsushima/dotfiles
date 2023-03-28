#!/bin/bash

set -e

CURRENT_DIR=`pwd`
TARGETS=( \
         ".asdfrc" \
         ".gemrc" \
         ".git-templates" \
         ".gitconfig" \
         "_.gitignore" \
         ".tigrc" \
         ".tmux.conf" \
         ".vim" \
         ".vimrc" \
         ".gvimrc" \
         ".zsh" \
         ".zshrc" \
         ".zshenv" \
         ".config/alacritty" \
         ".hammerspoon" \
       )

for TARGET in ${TARGETS[@]}
do
  SOURCE=$CURRENT_DIR/$TARGET
  DEST=$HOME/$TARGET
  # _. 始まりのファイルは . 始まりに変換
  if [[ ${TARGET:0:2} == "_." ]]; then
    DEST=$HOME/${TARGET:1}
  fi

  if [ -e $DEST ]; then
    echo "exist: $DEST"
  else
    echo "create: $DEST"
    ln -s $SOURCE $DEST
  fi
done
