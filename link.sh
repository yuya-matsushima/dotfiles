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
       )

for TARGET in ${TARGETS[@]}
do
  if [ $TARGET = "gitignore" ]; then
    ln -s $CURRENT_DIR/$TARGET $HOME/.$TARGET
  else
    ln -s $CURRENT_DIR/$TARGET $HOME/$TARGET
  fi
done
