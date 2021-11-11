[ -n "$ZSH_PROFILE" ] && zmodload zsh/zprof && zprof

typeset -U path

# GPG
export GPG_TTY=$(tty)

# Set Editor
export EDITOR=vim

export PATH=/usr/local/sbin:$PATH

export HOMEBREW_PREFIX=$(/usr/local/bin/brew --prefix)

# anyenv
if which anyenv > /dev/null; then
  export PATH=$HOME/.anyenv/bin:$PATH
  eval "$(anyenv init -)"
fi
if which go > /dev/null; then
  export GOPATH=$(go env GOPATH)
  export PATH=$GOPATH/bin:$PATH
fi

which python > /dev/null && export PATH=$HOMEBREW_PREFIX/opt/python/libexec/bin:$PATH
which direnv > /dev/null && eval "$(direnv hook zsh)"

# grep
which ggrep > /dev/null && alias grep="$HOMEBREW_PREFIX/bin/ggrep"

# sed
if which gsed > /dev/null; then
  export PATH=$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin:$PATH
  export MANPATH=$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnuman:$MANPATH
fi

# curl
[ -d $HOMEBREW_PREFIX/opt/curl/bin ] && export PATH=$HOMEBREW_PREFIX/opt/curl/bin:$PATH

# mysql-client
[ -d $HOMEBREW_PREFIX/opt/mysql-client ] && export PATH=$HOMEBREW_PREFIX/opt/mysql-client/bin:$PATH

# set fpath
[ -f $HOMEBREW_PREFIX/share/zsh/site-functions ] && fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)
[ -f $HOMEBREW_PREFIX/share/zsh-completions ] && fpath=($HOMEBREW_PREFIX/share/zsh-completions $fpath)
[ -f $HOME/.awsume/zsh-autocomplete ] && fpath=($HOME/.awsume/zsh-autocomplete/ $fpath)
