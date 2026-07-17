#!/bin/sh

# Install / uninstall AI agent hooks for Claude Code and Codex.
#
# Manages:
#   - tmux status hooks (agent-status.sh) for both CLIs
#   - shared notification sound (~/.agents/hooks/notify-sound.sh)
#   - Codex-only protected-file and force-push guards
#
# Unrelated hook entries (e.g. Claude Code's existing guard-protected-files.sh
# / guard-force-push.sh under ~/.claude/hooks/) are preserved on both install
# and uninstall. Managed entries are identified by command-string substrings.
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

TMUX_SCRIPT="$HOME/.tmux/agent-status.sh"
NOTIFY_SCRIPT="$HOME/.agents/hooks/notify-sound.sh"
CODEX_GUARD_APPLY="$HOME/.codex/hooks/guard-protected-apply-patch.sh"
CODEX_GUARD_BASH="$HOME/.codex/hooks/guard-force-push.sh"

if [ "$MODE" = "install" ]; then
    for p in "$TMUX_SCRIPT" "$NOTIFY_SCRIPT" "$CODEX_GUARD_APPLY" "$CODEX_GUARD_BASH"; do
        if [ ! -e "$p" ]; then
            echo "error: $p not found. Run 'make link' first." >&2
            exit 1
        fi
    done
fi

# Managed command substrings. A hook is treated as managed by this script
# (and stripped before re-registration) when its command contains any marker.
# Path-qualified where possible so Claude's own guard-* hooks are not touched.
CLAUDE_MARKERS='[
    "agent-status.sh",
    ".agents/hooks/notify-sound.sh",
    ".claude/hooks/notify-sound.sh"
]'
CODEX_MARKERS='[
    "agent-status.sh",
    ".agents/hooks/notify-sound.sh",
    ".codex/hooks/guard-protected-apply-patch.sh",
    ".codex/hooks/guard-force-push.sh"
]'

build_claude() {
    jq -n '
        def cmd($c): { type: "command", command: $c, timeout: 5 };
        {
            SessionStart:     [{ hooks: [cmd("sh ~/.tmux/agent-status.sh idle")] }],
            Stop:             [{ hooks: [cmd("sh ~/.tmux/agent-status.sh idle")] }],
            UserPromptSubmit: [{ hooks: [cmd("sh ~/.tmux/agent-status.sh working")] }],
            PostToolUse:      [{ hooks: [cmd("sh ~/.tmux/agent-status.sh working")] }],
            Notification:     [{ hooks: [
                cmd("sh ~/.tmux/agent-status.sh blocked"),
                cmd("sh ~/.agents/hooks/notify-sound.sh")
            ]}],
            SessionEnd:       [{ hooks: [cmd("sh ~/.tmux/agent-status.sh clear")] }]
        }
    '
}

build_codex() {
    jq -n '
        def cmd($c): { type: "command", command: $c, timeout: 5 };
        {
            SessionStart:     [{ hooks: [cmd("sh ~/.tmux/agent-status.sh idle")] }],
            Stop:             [{ hooks: [cmd("sh ~/.tmux/agent-status.sh idle")] }],
            UserPromptSubmit: [{ hooks: [cmd("sh ~/.tmux/agent-status.sh working")] }],
            PostToolUse:      [{ hooks: [cmd("sh ~/.tmux/agent-status.sh working")] }],
            PermissionRequest:[{ hooks: [
                cmd("sh ~/.tmux/agent-status.sh blocked"),
                cmd("sh ~/.agents/hooks/notify-sound.sh")
            ]}],
            PreToolUse: [
                { matcher: "^apply_patch$", hooks: [cmd("sh ~/.codex/hooks/guard-protected-apply-patch.sh")] },
                { matcher: "^Bash$",        hooks: [cmd("sh ~/.codex/hooks/guard-force-push.sh")] }
            ]
        }
    '
}

# jq expression that strips managed handlers, then optionally merges in the
# desired shape. Empty matcher groups and empty events are pruned so the file
# does not accumulate skeletons after uninstall.
# shellcheck disable=SC2016  # jq プログラム本体。シェル展開させない。
STRIP='
    .hooks //= {}
    | .hooks |= (
        with_entries(
            .value |= (
                map(.hooks |= map(
                    select(
                        . as $h
                        | ($markers | map(. as $m | ($h.command // "") | contains($m)) | any) | not
                    )
                ))
                | map(select(.hooks | length > 0))
            )
        )
        | with_entries(select(.value | length > 0))
    )
'

# shellcheck disable=SC2016  # jq プログラム本体。シェル展開させない。
MERGE='
    reduce ($desired | to_entries[]) as $e (.;
        .hooks[$e.key] = ((.hooks[$e.key] // []) + $e.value)
    )
'

update() {
    path="$1"
    markers="$2"
    desired="$3"  # empty when MODE=uninstall

    mkdir -p "$(dirname "$path")"
    [ -f "$path" ] || echo '{}' > "$path"

    tmp=$(mktemp)
    if [ "$MODE" = "install" ]; then
        jq --argjson markers "$markers" --argjson desired "$desired" \
            "$STRIP | $MERGE" "$path" > "$tmp"
    else
        jq --argjson markers "$markers" "$STRIP" "$path" > "$tmp"
    fi
    mv "$tmp" "$path"
    echo "$path: $MODE done"
}

if [ "$MODE" = "install" ]; then
    update "$HOME/.claude/settings.json" "$CLAUDE_MARKERS" "$(build_claude)"
    update "$HOME/.codex/hooks.json"     "$CODEX_MARKERS"  "$(build_codex)"

    cat >&2 <<'MSG'

Note: Codex will not run the new hooks until you trust them.
      Run 'codex' and execute '/hooks' to review and trust the entries.
MSG
else
    update "$HOME/.claude/settings.json" "$CLAUDE_MARKERS" ""
    update "$HOME/.codex/hooks.json"     "$CODEX_MARKERS"  ""
fi
