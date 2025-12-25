#!/bin/bash
cache_file="/tmp/tmux-git-branch-${TMUX_PANE}.cache"
pane_path="$1"

# キャッシュが存在し新しい（5秒以内）場合は再利用
if [[ -f "$cache_file" ]] && [[ $(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0))) -lt 5 ]]; then
  cat "$cache_file"
  exit 0
fi

# キャッシュを更新
if cd "$pane_path" 2>/dev/null; then
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    if [[ ${#branch} -gt 30 ]]; then
      echo "[${branch:0:29}…]" > "$cache_file"
    else
      echo "[$branch]" > "$cache_file"
    fi
    cat "$cache_file"
  else
    rm -f "$cache_file"
  fi
fi
