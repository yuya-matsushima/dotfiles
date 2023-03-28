#!/bin/sh

if [ ! -f $HOME/.vim/autoload/plug.vim ]; then
  echo "Download plug.vim..."
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# install vim plugins
vim + "PlugInstall --sync" +qa
