# fzf configuration

# 基本設定
export FZF_DEFAULT_COMMAND="fd --type f --type d --hidden --exclude .git"
export FZF_DEFAULT_OPTS='
  --height 50% 
  --reverse 
  --border 
  --preview-window=right:50%
  --prompt="❯ "
  --pointer="▶"
  --marker="✓"'

# プレビューコマンド
export FZF_PREVIEW_COMMAND='
  if [[ -d {} ]]; then
    tree -C {} | head -100
  elif [[ -f {} ]]; then
    case {} in
      *.jpg|*.jpeg|*.png|*.gif|*.webp) echo "Image: {}" ;;
      *.pdf) echo "PDF: {}" ;;
      *.zip|*.tar|*.gz|*.7z) echo "Archive: {}" ;;
      *) bat --style=numbers --color=always --line-range=:100 {} 2>/dev/null || cat {} ;;
    esac
  fi
'

export FZF_COMPLETION_OPTS="--preview '${FZF_PREVIEW_COMMAND}'"

# Ctrl+R: コマンド履歴検索
export FZF_CTRL_R_OPTS="
  --preview 'echo {} | sed \"s/^ *[0-9]* *//\" | head -1' 
  --preview-window=down:3:wrap
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

# Ctrl+T: ファイル検索
export FZF_CTRL_T_OPTS="
  --preview '${FZF_PREVIEW_COMMAND}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# Alt+C support for Mac
bindkey "ç" fzf-cd-widget

# Git branch切り替え
fzf-git-branch() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" | fzf -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# Git commit履歴検索
fzf-git-log() {
  git log --graph --color=always \
    --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
    --bind "ctrl-y:execute-silent(echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | pbcopy)+abort" \
    --header "Press CTRL-Y to copy commit hash" \
    --preview "echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % sh -c 'git show % --color=always'" \
    --bind "enter:execute(echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % sh -c 'git show %')"
}

# プロセスkill
fzf-kill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  if [ "x$pid" != "x" ]; then
    echo $pid | xargs kill -${1:-9}
  fi
}

# Docker container選択
if (( $+commands[docker] )); then
  fzf-docker-exec() {
    local container
    container=$(docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}" | sed 1d | fzf | awk '{print $1}')
    if [ -n "$container" ]; then
      docker exec -it $container /bin/bash || docker exec -it $container /bin/sh
    fi
  }
fi

# エイリアス (fz prefix)
alias fzbranch='fzf-git-branch'
alias fzlog='fzf-git-log'
alias fzkill='fzf-kill'
(( $+commands[docker] )) && alias fzdocker='fzf-docker-exec'