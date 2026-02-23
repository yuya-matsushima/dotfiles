[ -n "$ZSH_PROFILE" ] && zmodload zsh/zprof && zprof
export LANG=ja_JP.UTF-8
case ${UID} in
0)
    LANG=C
    ;;
esac

local zshrc_path=$HOME/.zshrc
# overwrite path when symbolic link
[ -L $zshrc_path ] && local zshrc_path=$(readlink $HOME/.zshrc)

# compile zshrc (silent unless DEBUG is set)
if [ ! -e $HOME/.zshrc.zwc ] || [ $zshrc_path -nt $HOME/.zshrc.zwc ]; then
  zcompile $HOME/.zshrc
  [ -n "$DEBUG_ZSHRC" ] && echo "compiled the \$HOME/.zshrc file.: .zshrc is changed"
fi

autoload colors && colors

case ${UID} in
0)
    PROMPT="%{${fg[cyan]}%}$(echo ${HOST%%.*} | tr '[a-z]' '[A-Z]') %B%{${fg[red]}%}%30<~<%/%%%{${reset_color}%}%b "
    PROMPT2="%B%{${fg[red]}%}%_#%{${reset_color}%}%b "
    SPROMPT="%B%{${fg[white]}%}%r is correct? [n,y,a,e]:%{${reset_color}%}%b "
    ;;
*)
    PROMPT="%{${fg[cyan]}%}%30<~<%/%%%{${reset_color}%} "
    PROMPT2="%{${fg[red]}%}%_%%%{${reset_color}%} "
    SPROMPT="%{${fg[red]}%}%r is correct? [n,y,a,e]:%{${reset_color}%} "
    [ -n "${REMOTEHOST}${SSH_CONNECTION}" ] &&
        PROMPT="%{${fg[red]}%}$(echo ${HOST%%.*} | tr '[a-z]' '[A-Z]') ${PROMPT}"
    ;;
esac

# auto change directory
setopt auto_cd

# auto directory pushd that you can get dirs list by cd -[tab]
setopt auto_pushd

# command correct edition before each completion attempt
setopt correct

# compacked complete list display
setopt list_packed

# no remove postfix slash of command line
setopt noautoremoveslash

# no beep sound when complete list displayed
setopt nolistbeep
setopt nobeep

# enable extended globbing
setopt extendedglob


# Keybind configuration
bindkey -d
bindkey -v

# start vi comannd mode: ESC&ESC
bindkey '\e\e' vi-cmd-mode

# move locator
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line

# historical backward/forward search with linehead string binded to ^P/^N
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^n" history-beginning-search-forward-end
# reverse menu completion binded to Shift-Tab
bindkey "\e[Z" reverse-menu-complete

# history
HISTFILE=${HOME}/.zsh_history
HISTSIZE=250000
SAVEHIST=250000
setopt hist_ignore_dups     # ignore duplication command history list
setopt share_history        # share command history data

# load credentials (only for interactive shells)
if [[ $- == *i* ]]; then
  [[ -f "$HOME/.zsh/credentials.zsh" ]] && source "$HOME/.zsh/credentials.zsh"
fi

# load extensions
if [[ -d $HOME/.zsh/extensions ]]; then
  for file in $HOME/.zsh/extensions/*(.N); do
    [[ -r "$file" ]] && source "$file"
  done
fi

# load functions
fpath=($HOME/.zsh/functions $fpath)
if [[ -d $HOME/.zsh/functions ]]; then
  for file in $HOME/.zsh/functions/^_*(.N); do
    [[ -r "$file" && ${file:t} != *.zsh ]] && autoload -Uz ${file:t}
  done
fi
# activate completion
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit -u

## zsh editor
autoload zed

## alias
setopt complete_aliases     # aliased ls needs if file/dir completions work

case "${OSTYPE}" in
freebsd*|darwin*)
    if (( $+commands[eza] )); then
      alias ls="eza --time-style=long-iso"
      alias la="eza -a --time-style=long-iso"
      alias ll="eza -l --time-style=long-iso"
      alias lt="eza --sort=modified --time-style=long-iso"
    else
      alias ls="ls -G -w"
      alias la="ls -a"
      alias ll="ls -l"
      alias lt="ls -t"
    fi
    ;;
linux*)
    if (( $+commands[eza] )); then
      alias ls="eza --time-style=long-iso"
      alias la="eza -a --time-style=long-iso"
      alias ll="eza -l --time-style=long-iso"
      alias lt="eza --sort=modified --time-style=long-iso"
    else
      alias ls="ls --color"
      alias la="ls -a"
      alias ll="ls -l"
      alias lt="ls -t"
    fi
    ;;
esac
alias l="ls"
alias j="jobs -l"
if (( $+commands[erd] )); then
  alias tree='erd --color=auto'
  alias treeless='erd --color=force | less -R'
fi
(( $+commands[rg] )) && alias rgless='rg --pcre2 --pretty --context 2 --no-heading --color=always'
(( $+commands[colordiff] )) && alias diff="colordiff -u"
(( $+commands[delta] )) && alias gitdiff="git diff --no-index"
if (( $+commands[asdf] )); then
  local asdf_path="$(brew --prefix asdf 2>/dev/null)/libexec/asdf.sh"
  [[ -f "$asdf_path" ]] && . "$asdf_path"
fi
(( $+commands[awsume] )) && alias awsume="source awsume"
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
# zoxide: 非対話シェル (Claude Code 等) での __zoxide_z エラーを回避するため対話シェルでのみ初期化
[[ $- == *i* ]] && (( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd cd)"
# Use GNU grep if available (for personal use only)
(( $+commands[ggrep] )) && alias ggrep="$HOMEBREW_PREFIX/bin/ggrep"
if (( $+commands[git] )); then
  alias root_path='git rev-parse --show-toplevel 2>/dev/null || echo .'
  alias root='cd $(root_path)'
fi
if (( $+commands[go] )); then
  export GOPATH=$(go env GOPATH)
  export GOBIN=${GOPATH}/bin
  export ASDF_GOLANG_MOD_VERSION_ENABLED=true
fi
(( $+commands[kubectl] )) && source <(kubectl completion zsh 2>/dev/null) 2>/dev/null
(( $+commands[codex] )) && source <(codex completion zsh 2>/dev/null) 2>/dev/null
(( $+commands[claude] )) && source "$HOME/.zsh/completions/_claude" 2>/dev/null
(( $+commands[qr] )) && alias qr="qrencode -t UTF8"
(( $+commands[uv] )) && eval "$(uv generate-shell-completion zsh 2>/dev/null)" 2>/dev/null
if (( $+commands[nvim] )); then
  alias ni="nvim"
  alias vi="nvim"
fi
# tinyvim: vim with minimal configuration
if [[ -f "$HOME/.vimrc.minimal" || -L "$HOME/.vimrc.minimal" ]]; then
  alias tinyvim='vim -u "$HOME/.vimrc.minimal"'
fi
if (( $+commands[fzf] )); then
  source <(fzf --zsh 2>/dev/null) 2>/dev/null || true
  [ -f "$HOME/.zsh/fzf.zsh" ] && source "$HOME/.zsh/fzf.zsh"
fi
if (( $+commands[yazi] )); then
  [ -f "$HOME/.zsh/yazi.zsh" ] && source "$HOME/.zsh/yazi.zsh"
fi
(( $+commands[lazygit] )) && alias lg='lazygit'

## terminal configuration
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

case "${TERM}" in
screen)
    TERM=xterm
    ;;
screen-256color)
    TERM=xterm-256color
    ;;
esac

case "${TERM}" in
xterm|xterm-color|xterm-256color)
    export LSCOLORS=exfxcxdxbxegedabagacad
    export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
    zstyle ':completion:*' list-colors 'di=34' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'
    ;;
kterm-color)
    stty erase '^H'
    export LSCOLORS=exfxcxdxbxegedabagacad
    export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
    zstyle ':completion:*' list-colors 'di=34' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'
    ;;
kterm)
    stty erase '^H'
    ;;
cons25)
    unset LANG
    export LSCOLORS=ExFxCxdxBxegedabagacad

    # Remove incorrect PATH assignment (was: export PATH=/usr/bin/vim)
    export LS_COLORS='di=01;34:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
    zstyle ':completion:*' list-colors 'di=;34;1' 'ln=;35;1' 'so=;32;1' 'ex=31;1' 'bd=46;34' 'cd=43;34'
    ;;
jfbterm-color)
    export LSCOLORS=gxFxCxdxBxegedabagacad
    export LS_COLORS='di=01;36:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
    zstyle ':completion:*' list-colors 'di=;36;1' 'ln=;35;1' 'so=;32;1' 'ex=31;1' 'bd=46;34' 'cd=43;34'
    ;;
esac

# report process
REPORTTIME=3

# git-prompt (zsh-git-prompt)
if [[ -f $HOMEBREW_PREFIX/opt/zsh-git-prompt/zshrc.sh ]]; then
  source $HOMEBREW_PREFIX/opt/zsh-git-prompt/zshrc.sh
  [[ -f $HOME/.zsh/config/zsh-git-prompt.sh ]] && source $HOME/.zsh/config/zsh-git-prompt.sh
else
  echo "Warning: zsh-git-prompt not found. Install with: brew install zsh-git-prompt" >&2
fi

[ -f $HOME/.zsh/asdf_completion.zsh ] && source $HOME/.zsh/asdf_completion.zsh
which less > /dev/null && source $HOME/.zsh/config/less.zsh

[ -f $HOME/.zshrc_local ] && source $HOME/.zshrc_local

# start tmux via tmx for Alacritty and Ghostty
if command -v tmx >/dev/null 2>&1 && [[ -z "$TMUX" ]]; then
  if [[ "$TERM" == alacritty* ]]; then
    if ! tmux has-session -t alacritty 2>/dev/null; then
      tmx alacritty
    fi
  elif [[ "$TERM" == xterm-ghostty ]]; then
    if ! tmux has-session -t ghostty 2>/dev/null; then
      tmx ghostty
    fi
  fi
fi

[ -n "$ZSH_PROFILE" ] && zprof | less
