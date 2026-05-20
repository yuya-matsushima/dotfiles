#!/bin/sh
set -e

REPO="fillin-inc/internal-skills"
SKILLS="agents-init code-review commit debug flow implement issue pr requirements spec spec-issue verify"

# antigravity-cli は $HOME/.antigravity/skills を参照するため,
# $HOME/.agents/skills への symlink を作成して共用する
link_antigravity_skills() {
    src="$HOME/.agents/skills"
    dest="$HOME/.antigravity/skills"

    if [ ! -d "$src" ]; then
        echo "skip antigravity link: $src does not exist"
        return
    fi

    mkdir -p "$HOME/.antigravity"

    if [ -L "$dest" ]; then
        current="$(readlink "$dest")"
        if [ "$current" = "$src" ]; then
            echo "antigravity link: $dest -> $src (already linked)"
            return
        fi
        echo "antigravity link: replace existing symlink $dest -> $current"
        rm "$dest"
    elif [ -e "$dest" ]; then
        echo "antigravity link: $dest exists and is not a symlink, skipping" >&2
        return
    fi

    ln -s "$src" "$dest"
    echo "antigravity link: $dest -> $src"
}

do_install() {
    for skill in $SKILLS; do
        # $HOME/.agents/skills に配置 (Codex / Copilot / Gemini CLI 等が共用)
        gh skill install "$REPO" "$skill" --dir "$HOME/.agents/skills" --agent github-copilot --force
        # $HOME/.claude/skills に配置 (Claude Code)
        gh skill install "$REPO" "$skill" --agent claude-code --scope user --force
    done

    link_antigravity_skills
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

    # $HOME/.agents/skills を指す symlink のみ削除
    antigravity_link="$HOME/.antigravity/skills"
    if [ -L "$antigravity_link" ]; then
        current="$(readlink "$antigravity_link")"
        if [ "$current" = "$HOME/.agents/skills" ]; then
            echo "remove: $antigravity_link"
            rm "$antigravity_link"
        else
            echo "keep: $antigravity_link -> $current (not managed)"
        fi
    fi
}

do_update() {
    gh skill update --all
    link_antigravity_skills
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
