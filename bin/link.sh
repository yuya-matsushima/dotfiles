#/bin/sh

set -e

CURRENT_DIR=`pwd`
TARGETS=( \
         ".asdfrc" \
         ".gemrc" \
         ".git-templates" \
         ".gitconfig" \
         "gitignore" \
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
  if [ $TARGET = "gitignore" ]; then
    if [ -e $HOME/.$TARGET ]; then
      echo "exist: $HOME/.$TARGET"
    else
      echo "create: $HOME/.$TARGET"
      ln -s $CURRENT_DIR/$TARGET $HOME/.$TARGET
    fi
  else
    if [ -e $HOME/$TARGET ]; then
      echo "exist: $HOME/$TARGET"
    else
      echo "create: $HOME/$TARGET"
      ln -s $CURRENT_DIR/$TARGET $HOME/$TARGET
    fi
  fi
done
