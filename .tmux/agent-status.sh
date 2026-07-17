#!/bin/sh

# Set per-pane AI agent status for the tmux status line.
# Called from Claude Code / Codex hooks with the state as the first argument.
# The state is stored in the pane option @agent_status and rendered by the
# pane loop #{P:#{@agent_status}} in window-status-format.
#
# Usage: agent-status.sh <working|blocked|idle|clear>

set -e

# no-op outside tmux
[ -n "${TMUX:-}" ] || exit 0
[ -n "${TMUX_PANE:-}" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0

case "${1:-}" in
    working)
        color="colour33"
        ;;
    blocked)
        color="colour160"
        ;;
    idle)
        color="colour244"
        ;;
    clear)
        tmux set-option -p -t "$TMUX_PANE" -u @agent_status 2>/dev/null || true
        exit 0
        ;;
    *)
        echo "Usage: $0 <working|blocked|idle|clear>" >&2
        exit 1
        ;;
esac

tmux set-option -p -t "$TMUX_PANE" @agent_status "#[fg=${color}]▌#[default]" 2>/dev/null || true
