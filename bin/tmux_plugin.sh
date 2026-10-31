#!/bin/sh

# Install / update hiroppy/tmux-agent-sidebar and wire the AI agent hooks.
#
#   - clone (or update) the plugin into ~/.tmux/plugins/tmux-agent-sidebar
#   - download the prebuilt binary (fallback: cargo build --release)
#   - wire only the agents that are actually installed:
#       OpenCode   -> symlink the bundled plugin bridge
#       Claude Code -> merge hooks into ~/.claude/settings.json
#       Codex      -> enable [features] codex_hooks and merge ~/.codex/hooks.json
#
# ~/.tmux is a symlink to this repository's .tmux/, so the clone lives under
# .tmux/plugins/ and is ignored by git.
#
# Usage: tmux_plugin.sh [update|uninstall]
#   (no argument) install: clone if missing, fetch binary only when missing
#   update:               git pull and fetch the latest release binary
#   uninstall:            remove managed agent hooks and the OpenCode bridge

set -e

MODE="${1:-install}"
case "$MODE" in
    install|update|uninstall)
        ;;
    *)
        echo "Usage: $0 [update|uninstall]" >&2
        exit 1
        ;;
esac

PLUGIN_NAME="tmux-agent-sidebar"
PLUGIN_REPO="https://github.com/hiroppy/tmux-agent-sidebar.git"
PLUGIN_DIR="$HOME/.tmux/plugins/$PLUGIN_NAME"
BINARY="$PLUGIN_DIR/bin/$PLUGIN_NAME"
OPENCODE_BRIDGE="$PLUGIN_DIR/.opencode/plugins/$PLUGIN_NAME.js"
OPENCODE_LINK="$HOME/.config/opencode/plugins/$PLUGIN_NAME.js"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CODEX_CONFIG="$HOME/.codex/config.toml"
CODEX_HOOKS="$HOME/.codex/hooks.json"
# Managed hook entries are identified by this substring of their command.
# It matches whatever absolute path `setup` emits because the tail is stable.
HOOK_MARKER="$PLUGIN_NAME/hook.sh"

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

warn() {
    echo "$PLUGIN_NAME: $*" >&2
}

# Print the release asset suffix for the current OS / architecture.
detect_platform() {
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$os" in
        darwin|linux)
            ;;
        *)
            warn "unsupported OS: $os"
            return 1
            ;;
    esac

    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            arch="x86_64"
            ;;
        arm64|aarch64)
            arch="aarch64"
            ;;
        *)
            warn "unsupported architecture: $arch"
            return 1
            ;;
    esac

    echo "${os}-${arch}"
}

# macOS Sequoia+ kills ad-hoc signed binaries that keep quarantine xattrs.
post_install_fixups() {
    if [ "$(uname -s)" = "Darwin" ]; then
        xattr -d com.apple.provenance "$BINARY" 2>/dev/null || true
        xattr -d com.apple.quarantine "$BINARY" 2>/dev/null || true
        codesign --force --sign - "$BINARY" >/dev/null 2>&1 || true
    fi
}

download_binary() {
    platform=$(detect_platform) || return 1
    url="https://github.com/hiroppy/tmux-agent-sidebar/releases/latest/download/${PLUGIN_NAME}-${platform}"
    mkdir -p "$(dirname "$BINARY")"
    echo "download: $url"
    if curl -fSL "$url" -o "$BINARY.tmp"; then
        chmod +x "$BINARY.tmp"
        mv "$BINARY.tmp" "$BINARY"
        post_install_fixups
        return 0
    fi
    rm -f "$BINARY.tmp"
    return 1
}

build_from_source() {
    if ! has_cmd cargo; then
        warn "download failed and cargo is not installed"
        return 1
    fi
    echo "build: cargo build --release"
    (cd "$PLUGIN_DIR" && cargo build --release)
    mkdir -p "$(dirname "$BINARY")"
    cp "$PLUGIN_DIR/target/release/$PLUGIN_NAME" "$BINARY"
    post_install_fixups
}

install_plugin() {
    if [ ! -d "$PLUGIN_DIR/.git" ]; then
        mkdir -p "$(dirname "$PLUGIN_DIR")"
        echo "clone: $PLUGIN_REPO -> $PLUGIN_DIR"
        git clone --depth 1 "$PLUGIN_REPO" "$PLUGIN_DIR"
    elif [ "$MODE" = "update" ]; then
        echo "update: git pull --ff-only"
        git -C "$PLUGIN_DIR" pull --ff-only
    fi

    if [ "$MODE" = "update" ] || [ ! -x "$BINARY" ]; then
        if ! download_binary; then
            warn "prebuilt binary unavailable; building from source"
            build_from_source
        fi
    fi

    if [ ! -x "$BINARY" ]; then
        warn "binary is not executable: $BINARY"
        return 1
    fi
}

# Merge the `setup <agent>` JSON ({ "hooks": { ... } }) into a hook config.
# Previously managed entries are stripped first, so re-running is idempotent
# and unrelated hooks (agent-status.sh, guards, ...) are preserved.
merge_hooks() {
    path="$1"
    agent="$2"

    if ! has_cmd jq; then
        warn "jq is required to wire $agent hooks"
        return 1
    fi

    desired=$("$BINARY" setup "$agent")
    mkdir -p "$(dirname "$path")"
    [ -f "$path" ] || echo '{}' > "$path"

    tmp=$(mktemp "${path}.XXXXXX")
    if ! jq --argjson desired "$desired" --arg marker "$HOOK_MARKER" '
        def dedupe: reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
        .hooks //= {}
        | .hooks |= with_entries(.value |= (
            map(.hooks |= map(select(((.command // "") | contains($marker)) | not)))
            | map(select((.hooks | length) > 0))
          ))
        | .hooks |= with_entries(select((.value | length) > 0))
        | reduce (($desired.hooks // {}) | to_entries[]) as $e (.;
            .hooks[$e.key] = (((.hooks[$e.key] // []) + $e.value) | dedupe)
          )
    ' "$path" > "$tmp"; then
        rm -f "$tmp"
        warn "failed to merge hooks into $path"
        return 1
    fi
    mv "$tmp" "$path"
    echo "$agent: hooks merged into $path"
}

# Remove only the entries this script added; other hooks stay untouched.
strip_hooks() {
    path="$1"
    [ -f "$path" ] || return 0
    if ! has_cmd jq; then
        warn "jq is required to update $path"
        return 1
    fi

    tmp=$(mktemp "${path}.XXXXXX")
    if ! jq --arg marker "$HOOK_MARKER" '
        .hooks //= {}
        | .hooks |= with_entries(.value |= (
            map(.hooks |= map(select(((.command // "") | contains($marker)) | not)))
            | map(select((.hooks | length) > 0))
          ))
        | .hooks |= with_entries(select((.value | length) > 0))
    ' "$path" > "$tmp"; then
        rm -f "$tmp"
        warn "failed to update $path"
        return 1
    fi
    mv "$tmp" "$path"
    echo "$path: managed hooks removed"
}

# Ensure `codex_hooks = true` under [features] without reformatting the file.
enable_codex_hooks() {
    path="$1"
    mkdir -p "$(dirname "$path")"
    [ -f "$path" ] || : > "$path"

    tmp=$(mktemp "${path}.XXXXXX")
    if ! awk '
        function emit_key() {
            if (!emitted) {
                print "codex_hooks = true"
                emitted = 1
            }
        }
        /^[[:space:]]*\[/ {
            if (in_features) {
                emit_key()
            }
            in_features = ($0 ~ /^[[:space:]]*\[features\][[:space:]]*(#.*)?$/)
            if (in_features) {
                saw_features = 1
            }
            print
            next
        }
        in_features && /^[[:space:]]*codex_hooks[[:space:]]*=/ {
            emit_key()
            next
        }
        { print }
        END {
            if (in_features) {
                emit_key()
            }
            if (!saw_features) {
                print ""
                print "[features]"
                print "codex_hooks = true"
            }
        }
    ' "$path" > "$tmp"; then
        rm -f "$tmp"
        warn "failed to update $path"
        return 1
    fi
    mv "$tmp" "$path"
    echo "codex: codex_hooks enabled in $path"
}

wire_opencode() {
    if [ ! -f "$OPENCODE_BRIDGE" ]; then
        warn "OpenCode bridge not found: $OPENCODE_BRIDGE"
        return 0
    fi
    mkdir -p "$(dirname "$OPENCODE_LINK")"
    # 実ファイルが既にある場合は内容を失わないよう退避してから symlink する
    if [ -e "$OPENCODE_LINK" ] && [ ! -L "$OPENCODE_LINK" ]; then
        backup="$OPENCODE_LINK.bak.$(date +%Y%m%d%H%M%S)"
        mv "$OPENCODE_LINK" "$backup"
        echo "opencode: backed up $OPENCODE_LINK -> $backup"
    fi
    ln -sfn "$OPENCODE_BRIDGE" "$OPENCODE_LINK"
    echo "opencode: linked $OPENCODE_LINK"
}

unwire_opencode() {
    [ -L "$OPENCODE_LINK" ] || return 0
    case "$(readlink "$OPENCODE_LINK")" in
        "$PLUGIN_DIR"/*)
            rm -f "$OPENCODE_LINK"
            echo "opencode: removed $OPENCODE_LINK"
            ;;
    esac
}

wire_agents() {
    if has_cmd opencode; then
        wire_opencode
    else
        echo "opencode: not found; skip"
    fi

    if has_cmd claude; then
        merge_hooks "$CLAUDE_SETTINGS" claude
    else
        echo "claude: not found; skip"
    fi

    if has_cmd codex; then
        enable_codex_hooks "$CODEX_CONFIG"
        merge_hooks "$CODEX_HOOKS" codex
    else
        echo "codex: not found; skip"
    fi
}

uninstall_agents() {
    strip_hooks "$CLAUDE_SETTINGS"
    strip_hooks "$CODEX_HOOKS"
    unwire_opencode
}

print_next_steps() {
    cat <<'MSG'

Next steps:
  - Reload tmux: prefix + r (or `tmux source ~/.tmux.conf`)
  - Toggle the sidebar: prefix + e (this window) / prefix + E (all windows)
  - Codex: run `codex` and execute `/hooks` to trust the new hook entries
  - Claude Code: `make tmux_plugin_uninstall` removes the hooks added here
MSG
    if has_cmd claude; then
        cat <<'MSG'
    (optional) The bundled Claude Code plugin can also be installed with:
      /plugin marketplace add ~/.tmux/plugins/tmux-agent-sidebar
      /plugin install tmux-agent-sidebar@hiroppy
    Do not enable both; this script already wires the equivalent hooks.
MSG
    fi
}

main() {
    if [ "$MODE" = "uninstall" ]; then
        uninstall_agents
        echo "$PLUGIN_NAME: agent hooks uninstalled (plugin checkout kept)"
        return
    fi

    if ! has_cmd git; then
        warn "git is required"
        exit 1
    fi

    install_plugin
    wire_agents
    print_next_steps
}

main
