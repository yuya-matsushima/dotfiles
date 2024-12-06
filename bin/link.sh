#!/bin/bash

set -e

MODE=$1
if [[ $MODE == "" ]]; then
  MODE="link"
elif [[ $MODE != "unlink" ]]; then
  echo "link.sh: Invalid Argument"
  exit 1
fi

if [ ! -d $HOME/.config ]; then
  mkdir -p $HOME/.config
fi

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
         ".psqlrc" \
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

  if [[ $MODE == "link" ]]; then
    if [ -L $DEST ]; then
      echo "exist: $DEST"
    else
      echo "link: $DEST"
      ln -s $SOURCE $DEST
    fi
  else
    if [ -L $DEST ]; then
      echo "unlink: $DEST"
      unlink $DEST
    else
      echo "not-exist: $DEST"
    fi
  fi
done
