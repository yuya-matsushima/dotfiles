#!/bin/sh

# omarchy/plugins.txt に列挙した Omarchy シェルプラグインを導入・有効化する。
# 既に導入済みのプラグインは有効化だけ行うため, 何度実行しても安全。
#
# 使い方:
#   sh bin/omarchy/plugins.sh
#   make omarchy_plugins
#
# プラグインを追加するときは omarchy/plugins.txt に
#   <plugin-id> <git-url> [placement]
# の形式で 1 行追加する (placement は left / center / right)。

set -e

if [ "$(uname -s)" != "Linux" ]; then
    echo "plugins.sh: this script is for Linux only" >&2
    exit 1
fi

# URL に glob 文字が含まれても word splitting で展開しないようにする。
set -f

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd)
PLUGIN_LIST="$REPO_DIR/omarchy/plugins.txt"

# Omarchy 以外の Arch ではプラグイン機構自体が無いため skip する。
if ! command -v omarchy >/dev/null 2>&1; then
    echo "plugins.sh: omarchy command not found; skip shell plugins" >&2
    exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "plugins.sh: jq is required" >&2
    exit 1
fi

if [ ! -f "$PLUGIN_LIST" ]; then
    echo "plugins.sh: $PLUGIN_LIST not found" >&2
    exit 1
fi

INSTALLED=$(omarchy plugin list --json)

# 現在の状態を enabled / disabled / 空文字 (未導入) で返す。
plugin_state() {
    printf '%s' "$INSTALLED" | jq -r --arg id "$1" '
        .[] | select(.id == $id) | if .enabled then "enabled" else "disabled" end
    ' | head -n 1
}

# 2 番目の引数 (placement) が空なら位置を変更せず有効化する。
enable_plugin() {
    if [ -n "$2" ]; then
        omarchy plugin enable "$1" "$2"
    else
        omarchy plugin enable "$1"
    fi
}

while IFS= read -r line || [ -n "$line" ]; do
    line=${line%%#*}

    # 前後の空白を落として id と URL に分割する。空白での分割は意図的で,
    # glob 展開は先頭の `set -f` で無効化している。
    # shellcheck disable=SC2086
    set -- $line
    if [ "$#" -eq 0 ]; then
        continue
    fi
    if [ "$#" -lt 2 ]; then
        echo "plugins.sh: invalid line (expected '<plugin-id> <git-url>'): $line" >&2
        exit 1
    fi

    plugin_id=$1
    plugin_url=$2
    plugin_placement=${3:-}

    case "$plugin_placement" in
        "" | left | center | right)
            ;;
        *)
            echo "plugins.sh: invalid placement '$plugin_placement' for $plugin_id" >&2
            exit 1
            ;;
    esac

    # 既に有効なプラグインの位置はユーザーの移動を尊重して動かさない。
    case "$(plugin_state "$plugin_id")" in
        enabled)
            echo "omarchy plugin: $plugin_id already enabled"
            ;;
        disabled)
            echo "omarchy plugin: enabling $plugin_id"
            enable_plugin "$plugin_id" "$plugin_placement"
            ;;
        *)
            echo "omarchy plugin: installing $plugin_id"
            omarchy plugin add "$plugin_url" --enable --yes
            if [ -n "$plugin_placement" ]; then
                enable_plugin "$plugin_id" "$plugin_placement"
            fi
            ;;
    esac

    # 追加直後の一覧は古い可能性があるため, 毎回引き直して確認する。
    if ! omarchy plugin list --json | jq -e --arg id "$plugin_id" \
        '.[] | select(.id == $id and .enabled)' >/dev/null; then
        echo "plugins.sh: failed to install/enable $plugin_id" >&2
        exit 1
    fi
done < "$PLUGIN_LIST"
