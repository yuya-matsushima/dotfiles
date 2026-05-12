#!/bin/sh
set -e

REPO="fillin-inc/internal-skills"
AGENTS_SKILLS_DIR="$HOME/.agents/skills"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
SKILLS="code-review commit implement issue pr spec-issue spec-to-plan specify task"

do_install() {
    mkdir -p "$AGENTS_SKILLS_DIR"
    for skill in $SKILLS; do
        gh skill install "$REPO/$skill" --dir "$AGENTS_SKILLS_DIR" --force
    done
    do_link
}

do_update() {
    gh skill update --all
    do_link
}

do_link() {
    mkdir -p "$CLAUDE_SKILLS_DIR"
    for skill in $SKILLS; do
        dst="$CLAUDE_SKILLS_DIR/$skill"
        src="$AGENTS_SKILLS_DIR/$skill"
        if [ -L "$dst" ]; then
            echo "exist: $dst"
        elif [ -e "$dst" ]; then
            echo "WARN: skip (real file/dir exists): $dst"
        else
            echo "link: $dst"
            ln -s "$src" "$dst"
        fi
    done
}

CMD="${1:-install}"
case "$CMD" in
    install) do_install ;;
    update)  do_update ;;
    link)    do_link ;;
    *)
        echo "Usage: install_skills.sh [install|update|link]" >&2
        exit 1
        ;;
esac
