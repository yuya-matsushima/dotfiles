# woefe/git-prompt.zsh (Linux / omarchy) 用テーマ設定
# macOS の Homebrew zsh-git-prompt は .zsh/config/zsh-git-prompt.sh を使う
#
# 重要: git-prompt.zsh 本体は、PROMPT / RPROMPT のどちらにも gitprompt が
# 含まれていない場合に PROMPT を上書きする。ここで RPROMPT に gitprompt を
# 設定したうえで source することで、既存の PROMPT を保ったまま branch を右側に出す。
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

# show git status & awsume profile
# Set initial RPROMPT only if not already set
# This allows prompt command settings to persist across sourcing
if [[ -z "$RPROMPT" ]]; then
  RPROMPT='$(gitprompt)${AWSUME_PROFILE:+[awss:$AWSUME_PROFILE]}${AWS_PROFILE:+[awsp:$AWS_PROFILE]}'
fi
