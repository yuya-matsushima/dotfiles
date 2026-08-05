#!/bin/sh

# agent 実行中のペインが kill された window の名前を復元する。
#
# .zsh/extensions/tmux_window_name.zsh は precmd で復元するが、
# kill-pane (この設定では Prefix + z) ではその shell の precmd が走らないため、
# @ymt_win_agents / @ymt_win_pane_repos と退避値が残り
# automatic-rename も off のままになる。
# .tmux.conf の after-kill-pane hook からこのスクリプトを呼んで後始末する。
#
# Usage: window-name-cleanup.sh <window-target>

set -e

WIN="${1:-}"
[ -n "$WIN" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0

# window が既に消えている場合は何もしない
agents=$(tmux display-message -p -t "$WIN" '#{@ymt_win_agents}' 2>/dev/null) || exit 0
[ -n "$agents" ] || exit 0

live=$(tmux list-panes -t "$WIN" -F '#{pane_id}' 2>/dev/null) || exit 0

# 記録されたペインのうち、まだ生きているものを残す
remaining=''
for p in $agents; do
    for l in $live; do
        if [ "$p" = "$l" ]; then
            remaining="$remaining $p"
            break
        fi
    done
done

remaining=$(printf '%s' "$remaining" | sed 's/^ *//')

if [ -n "$remaining" ]; then
    # まだ agent が動いているペインが残っているので名前は維持する
    tmux set-option -w -t "$WIN" @ymt_win_agents "$remaining" 2>/dev/null || true

    # @ymt_win_pane_repos から死んだペインのエントリを除去
    pane_repos=$(tmux display-message -p -t "$WIN" '#{@ymt_win_pane_repos}' 2>/dev/null || true)
    if [ -n "$pane_repos" ]; then
        save_ifs="$IFS"
        IFS='
'
        new_pane_repos=''
        for entry in $pane_repos; do
            [ -z "$entry" ] && continue
            pid="${entry%%=*}"
            for r in $remaining; do
                if [ "$pid" = "$r" ]; then
                    if [ -z "$new_pane_repos" ]; then
                        new_pane_repos="$entry"
                    else
                        new_pane_repos="$new_pane_repos
$entry"
                    fi
                    break
                fi
            done
        done
        IFS="$save_ifs"
        if [ -n "$new_pane_repos" ]; then
            tmux set-option -w -t "$WIN" @ymt_win_pane_repos "$new_pane_repos" 2>/dev/null || true
        fi
    fi
    exit 0
fi

prev_auto=$(tmux display-message -p -t "$WIN" '#{@ymt_win_prev_auto}' 2>/dev/null || true)
prev_name=$(tmux display-message -p -t "$WIN" '#{@ymt_win_prev_name}' 2>/dev/null || true)

tmux set-option -w -t "$WIN" -u @ymt_win_agents 2>/dev/null || true
tmux set-option -w -t "$WIN" -u @ymt_win_prev_auto 2>/dev/null || true
tmux set-option -w -t "$WIN" -u @ymt_win_prev_name 2>/dev/null || true
tmux set-option -w -t "$WIN" -u @ymt_win_pane_repos 2>/dev/null || true

if [ "$prev_auto" = "1" ]; then
    tmux set-window-option -t "$WIN" automatic-rename on 2>/dev/null || true
elif [ -n "$prev_name" ]; then
    tmux rename-window -t "$WIN" "$prev_name" 2>/dev/null || true
fi
