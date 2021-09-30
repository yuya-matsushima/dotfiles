# zmodload zsh/zprof && zprof
typeset -U path

export PATH=/usr/local/sbin:$PATH

# export HOMEBREW_GITHUB_API_TOKEN=your-token

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
  export PATH=$(/usr/local/bin/brew --prefix)/opt/python/libexec/bin:$PATH
fi

if [ -d $(/usr/local/bin/brew --prefix)/opt/curl/bin ]; then
  export PATH=$(/usr/local/bin/brew --prefix)/opt/curl/bin:$PATH
fi

# sed
if which gsed > /dev/null; then
  export PATH=$(/usr/local/bin/brew --prefix)/opt/gnu-sed/libexec/gnubin:$PATH
  export MANPATH=$(/usr/local/bin/brew --prefix)/opt/gnu-sed/libexec/gnuman:$MANPATH
fi

# mysql-client
if [ -d $(/usr/local/bin/brew --prefix)/opt/mysql-client ]; then
  export PATH=$(/usr/local/bin/brew --prefix)/opt/mysql-client/bin:$PATH
fi

# direnv
if which direnv > /dev/null; then
  eval "$(direnv hook zsh)"
fi

# GPG
export GPG_TTY=$(tty)
