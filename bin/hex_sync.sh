#!/bin/sh

# Hex (ローカル音声入力) の語彙と replacements をリポジトリの JSON に揃える。
#
#   hex/vocabulary.json   : [{"term": "...", "sounds_like": ["...", ...]}, ...]
#   hex/replacements.json : [{"matched_phrase": "...", "output": "..."}, ...]
#                           (Global モード = dictation_processing.default_mode の replacements)
#
# リポジトリ側を SSOT とし, sync では JSON に無い語彙を Hex から削除する。
# Hex の画面で編集した内容を残したいときは, 先に export でリポジトリへ書き戻す。
# settings.json を symlink しないのは, アプリが書き換える状態 (migrations 等) や
# API キーが同じファイルに入るため。
#
# 使い方: sh bin/hex_sync.sh [sync|check|export]   (通常は make hex_sync 等の経由)
#   sync   : リポジトリの内容を Hex へ反映する (既定)
#   check  : 差分だけ表示する。差分があれば exit 1
#   export : Hex の現在の内容をリポジトリへ書き出す
#
# 起動中の Hex に local API で問い合わせるため, Hex を起動しておくこと。

set -e

MODE=${1:-sync}
case "$MODE" in
    sync|check|export) ;;
    *)
        echo "hex_sync.sh: usage: hex_sync.sh [sync|check|export]" >&2
        exit 2
        ;;
esac

REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
VOCAB_FILE="$REPO_DIR/hex/vocabulary.json"
REPL_FILE="$REPO_DIR/hex/replacements.json"
DEFAULT_MODE_KEY="dictation_processing.default_mode"

if [ -n "$HEX_BIN" ]; then
    :
elif [ -x /Applications/Hex.app/Contents/MacOS/hex ]; then
    HEX_BIN=/Applications/Hex.app/Contents/MacOS/hex
elif [ -x "$HOME/.local/bin/hex" ]; then
    HEX_BIN="$HOME/.local/bin/hex"
else
    echo "hex_sync.sh: Hex is not installed" >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "hex_sync.sh: jq is required" >&2
    exit 1
fi

if ! "$HEX_BIN" status >/dev/null 2>&1; then
    echo "hex_sync.sh: Hex is not running; start it first ($HEX_BIN start)" >&2
    exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# sounds_like の並びは比較に影響させない
normalize_vocab() {
    jq -S '[.[] | {term, sounds_like: ((.sounds_like // []) | sort)}] | sort_by(.term)' "$1"
}

"$HEX_BIN" vocabulary list --json | jq '.entries' > "$TMP_DIR/vocab_current.json"
"$HEX_BIN" settings get "$DEFAULT_MODE_KEY" --json \
    | jq --arg key "$DEFAULT_MODE_KEY" '.settings[] | select(.key == $key) | .value' \
    > "$TMP_DIR/default_mode.json"
jq '.replacements // []' "$TMP_DIR/default_mode.json" > "$TMP_DIR/repl_current.json"

if [ "$MODE" = "export" ]; then
    mkdir -p "$REPO_DIR/hex"
    cp "$TMP_DIR/vocab_current.json" "$VOCAB_FILE"
    cp "$TMP_DIR/repl_current.json" "$REPL_FILE"
    echo "hex_sync.sh: exported to hex/vocabulary.json and hex/replacements.json"
    exit 0
fi

for f in "$VOCAB_FILE" "$REPL_FILE"; do
    if ! jq -e 'type == "array"' "$f" >/dev/null 2>&1; then
        echo "hex_sync.sh: $f must be a JSON array" >&2
        exit 1
    fi
done

# hex vocabulary add --sounds-like はカンマ区切りのため, カンマを含む綴りは渡せない
if jq -e 'any(.[]; (.sounds_like // [])[] | contains(","))' "$VOCAB_FILE" >/dev/null; then
    echo "hex_sync.sh: sounds_like must not contain commas" >&2
    exit 1
fi

normalize_vocab "$VOCAB_FILE" > "$TMP_DIR/vocab_want.n.json"
normalize_vocab "$TMP_DIR/vocab_current.json" > "$TMP_DIR/vocab_cur.n.json"
jq -S '.' "$REPL_FILE" > "$TMP_DIR/repl_want.n.json"
jq -S '.' "$TMP_DIR/repl_current.json" > "$TMP_DIR/repl_cur.n.json"

# 削除すべき語彙: 現在あるが, 望む状態に同じ内容で存在しないもの
jq -r --slurpfile want "$TMP_DIR/vocab_want.n.json" \
    '.[] | select(. as $e | $want[0] | index([$e]) | not) | .term' \
    "$TMP_DIR/vocab_cur.n.json" > "$TMP_DIR/vocab_remove.txt"
# 追加すべき語彙: 望む状態にあるが, 現在同じ内容で存在しないもの
jq -c --slurpfile cur "$TMP_DIR/vocab_cur.n.json" \
    '.[] | select(. as $e | $cur[0] | index([$e]) | not)' \
    "$TMP_DIR/vocab_want.n.json" > "$TMP_DIR/vocab_add.jsonl"

repl_changed=0
if ! cmp -s "$TMP_DIR/repl_want.n.json" "$TMP_DIR/repl_cur.n.json"; then
    repl_changed=1
fi

if [ ! -s "$TMP_DIR/vocab_remove.txt" ] && [ ! -s "$TMP_DIR/vocab_add.jsonl" ] && [ "$repl_changed" -eq 0 ]; then
    echo "hex_sync.sh: vocabulary and replacements are up to date"
    exit 0
fi

if [ "$MODE" = "check" ]; then
    # 内容が変わった語彙は remove と add の両方に出る
    while IFS= read -r term; do
        echo "vocabulary: - $term"
    done < "$TMP_DIR/vocab_remove.txt"
    jq -r '"vocabulary: + \(.term) (\(.sounds_like | join(", ")))"' "$TMP_DIR/vocab_add.jsonl"
    if [ "$repl_changed" -eq 1 ]; then
        echo "replacements: differ"
        diff -u "$TMP_DIR/repl_cur.n.json" "$TMP_DIR/repl_want.n.json" || true
    fi
    exit 1
fi

while IFS= read -r term; do
    "$HEX_BIN" vocabulary remove "$term" >/dev/null
    echo "vocabulary: removed $term"
done < "$TMP_DIR/vocab_remove.txt"

while IFS= read -r entry; do
    term=$(printf '%s' "$entry" | jq -r '.term')
    spellings=$(printf '%s' "$entry" | jq -r '.sounds_like | join(",")')
    if [ -n "$spellings" ]; then
        "$HEX_BIN" vocabulary add "$term" --sounds-like "$spellings" >/dev/null
    else
        "$HEX_BIN" vocabulary add "$term" >/dev/null
    fi
    echo "vocabulary: added $term"
done < "$TMP_DIR/vocab_add.jsonl"

if [ "$repl_changed" -eq 1 ]; then
    # Global モードの他の項目 (post_processing 等) は現在値を保ったまま replacements だけ差し替える
    jq --arg key "$DEFAULT_MODE_KEY" --slurpfile repl "$REPL_FILE" \
        '{($key): (.replacements = $repl[0])}' \
        "$TMP_DIR/default_mode.json" > "$TMP_DIR/apply.json"
    "$HEX_BIN" settings apply "$TMP_DIR/apply.json" >/dev/null
    echo "replacements: applied $(jq 'length' "$REPL_FILE") entries"
fi
