## dotfiles

requirements:

- XCode from AppStore
- Homebrew

```sh
# install homebrew libraries
sh homebrew.sh
# create synbolic links
sh link.sh
# install plug.vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# install vim plugins
vim + 'PlugInstall --sync' +qa
```
