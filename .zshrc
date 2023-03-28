[ -n "$ZSH_PROFILE" ] && zmodload zsh/zprof && zprof
export LANG=ja_JP.UTF-8
case ${UID} in
0)
    LANG=C
    ;;
esac

local zshrc_path=$HOME/.zshrc
local zshenv_path=$HOME/.zshenv
# overwrite path when symbolic link
[ -L $zshrc_path ] && local zshrc_path=$(readlink $HOME/.zshrc)
[ -L $zshenv_path ] && local zshenv_path=$(readlink $HOME/.zshenv)

# compile zshrc
if [ ! -e $HOME/.zshrc.zwc ] || [ $zshrc_path -nt $HOME/.zshrc.zwc ]; then
  zcompile $HOME/.zshrc
  echo "compiled the \$HOME/.zshrc file.: .zshrc is changed"
fi
if [ ! -e $HOME/.zshenv.zwc ] || [ $zshenv_path -nt $HOME/.zshenv.zwc ]; then
  zcompile $HOME/.zshenv
  echo "compiled the \$HOME/.zshenv file.: .zshenv is changed"
fi

source $HOME/.zshenv

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

# load extensions
for file in `find $HOME/.zsh/extensions -type f`; do source $file; done

# load functions
fpath=($HOME/.zsh/functions $fpath)
for file in `find $fpath[1] -type f -not -name '_*'`; do
  autoload -Uz $(echo $file | cut -d '/' -f 6)
done
# activate completion
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit -u

## zsh editor
autoload zed

## alias
setopt complete_aliases     # aliased ls needs if file/dir completions work

case "${OSTYPE}" in
freebsd*|darwin*)
    alias ls="ls -G -w"
    ;;
linux*)
    alias ls="ls --color"
    ;;
esac
alias l="ls"
alias la="ls -a"
alias ll="ls -l"
alias lt="ls -t"
alias j="jobs -l"
alias agless='ag --pager="less -XgmR"'
which colordiff > /dev/null && alias diff="colordiff -u"
which asdf > /dev/null && . $(brew --prefix asdf)/libexec/asdf.sh
which awsume > /dev/null && alias awsume="source awsume"
which direnv > /dev/null && eval "$(direnv hook zsh)"
which ggrep > /dev/null && alias grep="$HOMEBREW_PREFIX/bin/ggrep"
which git_root > /dev/null && alias root=git_root
which go > /dev/null && export GOPATH=$(go env GOPATH)
which kubectl > /dev/null && source <(kubectl completion zsh)
[ -f $HOME/.zsh/asdf_completion.zsh ] && source $HOME/.zsh/asdf_completion.zsh

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

    export PATH=/usr/bin/vim
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

# git-prompt
if [ -f $HOME/.zsh/git-prompt.zsh ]; then
  ZSH_GIT_PROMPT_FORCE_BLANK=0
  ZSH_GIT_PROMPT_SHOW_UPSTREAM=0
  ZSH_GIT_PROMPT_SHOW_STASH=0

  ZSH_THEME_GIT_PROMPT_PREFIX="["
  ZSH_THEME_GIT_PROMPT_SUFFIX="]"
  ZSH_THEME_GIT_PROMPT_SEPARATOR="|"
  ZSH_THEME_GIT_PROMPT_DETACHED="%{$fg_no_bold[cyan]%}:"
  ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg_no_bold[white]%}"
  ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg_no_bold[red]%}-"
  ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg_no_bold[green]%}+"
  ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[red]%}-"
  ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[green]%}"
  ZSH_THEME_GIT_PROMPT_UNSTAGED="%{$fg[red]%}-"
  ZSH_THEME_GIT_PROMPT_UNTRACKED="?"
  ZSH_THEME_GIT_PROMPT_STASHED="%{$fg[blue]%}⚑"
  ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}✔"

  RPROMPT='$(gitprompt)${AWSUME_PROFILE:+[aws:$AWSUME_PROFILE]}'
  source $HOME/.zsh/git-prompt.zsh
elif [ -f $HOMEBREW_PREFIX/opt/zsh-git-prompt/zshrc.sh ]; then
  # zsh-git-prompt: git-prompt がない場合に反映
  source $HOMEBREW_PREFIX/opt/zsh-git-prompt/zshrc.sh
  ZSH_THEME_GIT_PROMPT_PREFIX="["
  ZSH_THEME_GIT_PROMPT_SUFFIX="]"
  ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg[white]%}"
  ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[green]%}%{ %G%}"
  ZSH_THEME_GIT_PROMPT_CONFLICTS="%{$fg[magenta]%}%{x%G%}"
  ZSH_THEME_GIT_PROMPT_CHANGED="%{$fg[red]%}%{+%G%}"
  ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[red]%}%{-%G%}"
  ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[green]%}%{+%G%}"
  ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[green]%}%{✔%G%}"

  # show git status & awsume profile
  RPROMPT='$(git_super_status)${AWSUME_PROFILE:+[aws:$AWSUME_PROFILE]}'
fi

if which less > /dev/null; then
  export LESS_TERMCAP_mb=$'\E[01;31m'
  export LESS_TERMCAP_md=$'\E[01;34m'
  export LESS_TERMCAP_me=$'\E[0m'
  export LESS_TERMCAP_se=$'\E[0m'
  export LESS_TERMCAP_so=$'\E[01;44;33m'
  export LESS_TERMCAP_ue=$'\E[0m'
  export LESS_TERMCAP_us=$'\E[01;32m'
fi

[ -f $HOME/.zshrc_local ] && source $HOME/.zshrc_local
[ -n "$ZSH_PROFILE" ] && zprof | less
