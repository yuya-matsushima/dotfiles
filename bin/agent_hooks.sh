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

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required" >&2
    exit 1
fi

AGENT_HOOKS_MODE="$MODE" \
AGENT_HOOKS_SCRIPT="$HOME/.tmux/agent-status.sh" \
AGENT_HOOKS_CLAUDE="$HOME/.claude/settings.json" \
AGENT_HOOKS_CODEX="$HOME/.codex/hooks.json" \
python3 <<'PY'
import json
import os

mode = os.environ["AGENT_HOOKS_MODE"]
script = os.environ["AGENT_HOOKS_SCRIPT"]

# state transitions per hook event
CLAUDE_EVENTS = {
    "SessionStart": "idle",
    "Stop": "idle",
    "UserPromptSubmit": "working",
    "PostToolUse": "working",
    "Notification": "blocked",
    "SessionEnd": "clear",
}
# Codex has no SessionEnd; PermissionRequest instead of Notification
CODEX_EVENTS = {
    "SessionStart": "idle",
    "Stop": "idle",
    "UserPromptSubmit": "working",
    "PostToolUse": "working",
    "PermissionRequest": "blocked",
}


def load(path):
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return {}


def strip_agent_entries(hooks):
    for event in list(hooks.keys()):
        groups = []
        for group in hooks[event]:
            commands = [
                h for h in group.get("hooks", [])
                if "agent-status.sh" not in h.get("command", "")
            ]
            if commands:
                group["hooks"] = commands
                groups.append(group)
        if groups:
            hooks[event] = groups
        else:
            del hooks[event]


def add_entries(hooks, events):
    for event, state in events.items():
        hooks.setdefault(event, []).append({
            "hooks": [{
                "type": "command",
                "command": "sh '%s' %s" % (script, state),
                "timeout": 5,
            }],
        })


def update(path, events):
    data = load(path)
    hooks = data.setdefault("hooks", {})
    strip_agent_entries(hooks)
    if mode == "install":
        add_entries(hooks, events)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print("%s: %s done" % (path, mode))


update(os.environ["AGENT_HOOKS_CLAUDE"], CLAUDE_EVENTS)
update(os.environ["AGENT_HOOKS_CODEX"], CODEX_EVENTS)
PY
