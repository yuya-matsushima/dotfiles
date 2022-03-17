typeset -U path
typeset -U fpath

# GPG
export GPG_TTY=$(tty)

# Editor
export EDITOR=vim

export HOMEBREW_PREFIX=$(/usr/local/bin/brew --prefix)

which asdf > /dev/null && . $(brew --prefix asdf)/libexec/asdf.sh
which direnv > /dev/null && eval "$(direnv hook zsh)"
which go > /dev/null && export GOPATH=$(go env GOPATH)
which ggrep > /dev/null && alias grep="$HOMEBREW_PREFIX/bin/ggrep"

# kubectl
which kubectl > /dev/null && source <(kubectl completion zsh)

# additional path
local add_path_dirs=(
  /usr/local/sbin
  $GOPATH/bin
  $HOMEBREW_PREFIX/opt/python/libexec/bin
  $HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin
  $HOMEBREW_PREFIX/opt/curl/bin
  $HOMEBREW_PREFIX/opt/mysql-client/bin
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
