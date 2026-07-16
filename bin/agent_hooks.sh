#!/bin/sh

# Install / uninstall AI agent status hooks for Claude Code and Codex.
# Registers ~/.tmux/agent-status.sh as a hook command so that each CLI
# reports its state (working / blocked / idle) to the tmux status line.
# Existing hook entries that do not reference agent-status.sh are preserved.
#
# Usage: agent_hooks.sh [uninstall]

set -e

MODE="${1:-install}"

case "$MODE" in
    install|uninstall)
        ;;
    *)
        echo "Usage: $0 [uninstall]" >&2
        exit 1
        ;;
esac

if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required (brew install jq)" >&2
    exit 1
fi

SCRIPT="$HOME/.tmux/agent-status.sh"

if [ "$MODE" = "install" ] && [ ! -e "$SCRIPT" ]; then
    echo "error: $SCRIPT not found. Run 'make link' first." >&2
    exit 1
fi

# event -> state mapping. Codex has no SessionEnd and uses PermissionRequest
# where Claude uses Notification.
CLAUDE_EVENTS='{
    "SessionStart": "idle",
    "Stop": "idle",
    "UserPromptSubmit": "working",
    "PostToolUse": "working",
    "Notification": "blocked",
    "SessionEnd": "clear"
}'
CODEX_EVENTS='{
    "SessionStart": "idle",
    "Stop": "idle",
    "UserPromptSubmit": "working",
    "PostToolUse": "working",
    "PermissionRequest": "blocked"
}'

# Build {event: full_command} from {event: state}. The script path is wrapped
# in single quotes so the command remains a valid shell command in the hook.
build_commands() {
    echo "$1" | jq --arg script "$SCRIPT" '
        ([39] | implode) as $q
        | to_entries
        | map({key: .key, value: ("sh " + $q + $script + $q + " " + .value)})
        | from_entries
    '
}

update() {
    path="$1"
    commands="$2"
    mkdir -p "$(dirname "$path")"
    [ -f "$path" ] || echo '{}' > "$path"

    tmp=$(mktemp)
    if [ "$MODE" = "install" ]; then
        jq --argjson cmds "$commands" '
            .hooks //= {}
            | .hooks |= (
                to_entries
                | map(.value |= (
                    map(.hooks |= map(select(.command | contains("agent-status.sh") | not)))
                    | map(select(.hooks | length > 0))
                ))
                | map(select(.value | length > 0))
                | from_entries
            )
            | reduce ($cmds | to_entries[]) as $e (.;
                .hooks[$e.key] += [{
                    hooks: [{type: "command", command: $e.value, timeout: 5}]
                }]
            )
        ' "$path" > "$tmp"
    else
        jq '
            .hooks //= {}
            | .hooks |= (
                to_entries
                | map(.value |= (
                    map(.hooks |= map(select(.command | contains("agent-status.sh") | not)))
                    | map(select(.hooks | length > 0))
                ))
                | map(select(.value | length > 0))
                | from_entries
            )
        ' "$path" > "$tmp"
    fi
    mv "$tmp" "$path"
    echo "$path: $MODE done"
}

update "$HOME/.claude/settings.json" "$(build_commands "$CLAUDE_EVENTS")"
update "$HOME/.codex/hooks.json" "$(build_commands "$CODEX_EVENTS")"

if [ "$MODE" = "install" ]; then
    cat >&2 <<'MSG'

Note: Codex will not run the new hooks until you trust them.
      Run 'codex' and execute '/hooks' to review and trust the entries.
MSG
fi
