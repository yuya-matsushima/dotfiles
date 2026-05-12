#!/bin/sh
set -e

REPO="fillin-inc/internal-skills"
SKILLS="code-review commit implement issue pr spec-issue spec-to-plan specify task"

do_install() {
    for skill in $SKILLS; do
        # $HOME/.codex/skills に配置 (Codex)
        gh skill install "$REPO" "$skill" --agent codex --scope user --force
        # $HOME/.claude/skills に配置 (Claude Code)
        gh skill install "$REPO" "$skill" --agent claude-code --scope user --force
    done
}

do_update() {
    gh skill update --all
}

CMD="${1:-install}"
case "$CMD" in
    install) do_install ;;
    update)  do_update ;;
    *)
        echo "Usage: install_skills.sh [install|update]" >&2
        exit 1
        ;;
esac
