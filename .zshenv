# Compile this file for faster loading
local zshenv_path=$HOME/.zshenv
# Overwrite path when symbolic link
[[ -L $zshenv_path ]] && local zshenv_path=$(readlink $HOME/.zshenv)
if [[ ! -e $HOME/.zshenv.zwc ]] || [[ $zshenv_path -nt $HOME/.zshenv.zwc ]]; then
  zcompile $HOME/.zshenv
  [[ -n "$DEBUG_ZSHENV" ]] && echo "compiled $HOME/.zshenv"
fi

typeset -U path
typeset -U fpath

# GPG (only for interactive shells)
[[ -t 0 ]] && export GPG_TTY=$(tty)

# Editor
if (( $+commands[nvim] )); then
  export EDITOR=nvim
else
  export EDITOR=vim
fi

# XDG Base Directory
export XDG_CONFIG_HOME="$HOME/.config"

if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export HOMEBREW_PREFIX=$(/opt/homebrew/bin/brew --prefix)
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
  export HOMEBREW_PREFIX=$(/usr/local/bin/brew --prefix)
else
  echo "Error: Homebrew not found in /opt/homebrew or /usr/local" >&2
  if [[ -t 0 ]]; then
    exit 1
  else
    return 1
  fi
fi

# additional path
local add_path_dirs=(
  /usr/local/sbin
  $HOME/.local/share/vim-lsp-settings/servers/bash-language-server
  $HOMEBREW_PREFIX/opt/python/libexec/bin
  $HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin
  $HOMEBREW_PREFIX/opt/curl/bin
  $HOMEBREW_PREFIX/opt/mysql-client/bin
  $HOMEBREW_PREFIX/opt/libpq/bin
  $HOME/.lmstudio/bin
  $HOME/.antigravity/antigravity/bin
)
# Add GOPATH/bin only if GOPATH is defined
[[ -n "$GOPATH" && -d "$GOPATH/bin" ]] && add_path_dirs+=("$GOPATH/bin")
for dir in $add_path_dirs; do
  [[ -d "$dir" ]] && export PATH="$dir:$PATH"
done

# additional fpath
local add_fpath_dirs=(
  $HOMEBREW_PREFIX/share/zsh/site-functions
  $HOMEBREW_PREFIX/share/zsh-completions
  $HOME/.awsume/zsh-autocomplete
)
for dir in $add_fpath_dirs; do
  [[ -d "$dir" ]] && fpath=("$dir" $fpath)
done
