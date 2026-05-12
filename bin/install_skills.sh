#!/bin/sh
set -e

REPO="fillin-inc/internal-skills"
SKILLS="code-review commit implement issue pr spec-issue spec-to-plan spec task"

do_install() {
    for skill in $SKILLS; do
        # $HOME/.agents/skills に配置 (Codex / Copilot / Gemini CLI 等が共用)
        gh skill install "$REPO" "$skill" --dir "$HOME/.agents/skills" --agent github-copilot --force
        # $HOME/.claude/skills に配置 (Claude Code)
        gh skill install "$REPO" "$skill" --agent claude-code --scope user --force
    done
}

do_uninstall() {
    for skill in $SKILLS; do
        for dir in "$HOME/.agents/skills" "$HOME/.claude/skills"; do
            target="$dir/$skill"
            if [ -e "$target" ] || [ -L "$target" ]; then
                echo "remove: $target"
                rm -rf "$target"
            else
                echo "not-exist: $target"
            fi
        done
    done
}

do_update() {
    gh skill update --all
}

CMD="${1:-install}"
case "$CMD" in
    install)   do_install ;;
    uninstall) do_uninstall ;;
    update)    do_update ;;
    *)
        echo "Usage: install_skills.sh [install|uninstall|update]" >&2
        exit 1
        ;;
esac
