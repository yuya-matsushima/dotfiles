if [ -n "$ZSH_PROFILE" ]; then
  zmodload zsh/zprof && zprof
fi
typeset -U path

# GPG
export GPG_TTY=$(tty)

# Set Editor
export EDITOR=vim

# export HOMEBREW_GITHUB_API_TOKEN=your-token

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

if which python > /dev/null; then
  export PATH=$HOMEBREW_PREFIX/opt/python/libexec/bin:$PATH
fi

if [ -d $HOMEBREW_PREFIX/opt/curl/bin ]; then
  export PATH=$HOMEBREW_PREFIX/opt/curl/bin:$PATH
fi

# sed
if which gsed > /dev/null; then
  export PATH=$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin:$PATH
  export MANPATH=$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnuman:$MANPATH
fi

# mysql-client
if [ -d $HOMEBREW_PREFIX/opt/mysql-client ]; then
  export PATH=$HOMEBREW_PREFIX/opt/mysql-client/bin:$PATH
fi

# direnv
if which direnv > /dev/null; then
  eval "$(direnv hook zsh)"
fi
