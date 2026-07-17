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
         ".tmux" \
         ".tmux.conf" \
         ".vim" \
         ".vimrc" \
         ".vimrc.minimal" \
         ".gvimrc" \
         ".zsh" \
         ".zshrc" \
         ".zshenv" \
         ".psqlrc" \
         ".config/alacritty" \
         ".config/ghostty" \
         ".config/nvim" \
         ".config/yazi" \
         ".config/lazygit" \
         ".hammerspoon" \
         ".markdownlint.yml" \
         ".claude/hooks" \
         ".claude/statusline.sh" \
         ".codex/hooks" \
         ".agents/hooks" \
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
    elif [ -e $DEST ]; then
      # 実ファイル / 実ディレクトリが既にある場合、そのまま `ln -s` すると
      # `$DEST/<basename>` が作られてリンク構造が壊れる（例: 実ディレクトリの
      # `~/.codex/hooks` 内に `hooks` symlink が生まれ、agent_hooks.sh の
      # `-e` チェックが通らなくなる）。事故防止のため明示的に fail する。
      echo "error: $DEST exists as a real file/directory. Move or delete it before running link." >&2
      exit 1
    else
      DEST_PARENT=$(dirname "$DEST")
      [ -d "$DEST_PARENT" ] || mkdir -p "$DEST_PARENT"
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
