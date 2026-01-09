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
# Note: git_super_status function is provided by zsh-git-prompt
# Set initial RPROMPT only if not already set
# This allows prompt command settings to persist across sourcing
if [[ -z "$RPROMPT" ]]; then
  RPROMPT='$(git_super_status 2>/dev/null || echo "")${AWSUME_PROFILE:+[aws:$AWSUME_PROFILE]}'
fi
