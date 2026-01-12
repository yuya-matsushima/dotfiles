#!/bin/bash

# tmux status bar git branch display script
# Shows current git branch name in brackets, truncated if too long

main() {
    # Change to the current pane's path
    # tmux passes pane_current_path via environment or we rely on PWD
    local current_path="${1:-$PWD}"

    cd "$current_path" 2>/dev/null || return

    # Get current git branch name
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

    if [[ -n "$branch" ]]; then
        # Truncate branch name if longer than 30 characters
        if [[ ${#branch} -gt 30 ]]; then
            echo "[${branch:0:29}…]"
        else
            echo "[$branch]"
        fi
    fi
}

main "$@"
