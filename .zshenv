typeset -U path
typeset -U fpath

# GPG
export GPG_TTY=$(tty)

# Editor
export EDITOR=vim


if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export HOMEBREW_PREFIX=$(/opt/homebrew/bin/brew --prefix)
else
  export HOMEBREW_PREFIX=$(/usr/local/bin/brew --prefix)
fi

# additional path
local add_path_dirs=(
  /usr/local/sbin
  $GOPATH/bin
  $HOME/.local/share/vim-lsp-settings/servers/bash-language-server
  $HOMEBREW_PREFIX/opt/python/libexec/bin
  $HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin
  $HOMEBREW_PREFIX/opt/curl/bin
  $HOMEBREW_PREFIX/opt/mysql-client/bin
  $HOMEBREW_PREFIX/opt/libpq/bin
)
for dir in $add_path_dirs; do
  [ -d $dir ] && export PATH=$dir:$PATH
done

# additional fpath
local add_fpath_dirs=(
  $HOMEBREW_PREFIX/share/zsh/site-functions
  $HOMEBREW_PREFIX/share/zsh-completions
  $HOME/.awsume/zsh-autocomplete
)
for dir in $add_fpath_dirs; do
  [ -d $dir ] && fpath=($dir $fpath)
done
