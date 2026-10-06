#!/bin/sh
# ============================================================================
# guard-force-push.sh
#
# Hook event : PreToolUse
# Matcher    : Bash
#
# 目的:
#   Claude Code の Bash tool で `git push --force` / `git push -f` 相当の
#   コマンドをブロックする。permissions.deny のパターンマッチは
#   "git -c ... push --force" のような接頭 flag が付いた形を素通しさせる
#   隙間があるため、意味論ベースで防ぐ。
#
# 判定:
#   実際の判定ロジックは共通スクリプト
#   `~/.agents/hooks/force-push-verdict.sh` に集約している（Codex 版と同一）。
#   本スクリプトは Claude Code の hook JSON の入出力だけを担う薄いアダプタで、
#   verdict を Claude Code の block JSON に変換する。
#   これにより、コマンド文字列全体への grep ではなく、subcommand 分割・
#   クォート内区切りの無害化・push 以降のトークン単位判定で細かく制御する。
#
#   ブロックする verdict:
#     - combined : raw --force と --force-with-lease を併記
#     - raw      : git push -f / --force / --force=<val> / 短縮結合形 (-uf 等)
#     - mirror   : git push --mirror
#     - plus     : +<refspec> による強制更新
#
#   素通し（相対的に安全なので許可）:
#     - git push --force-with-lease [--force-if-includes]
#     - git push --force-if-includes 単独
#     - 通常の git push
#
# 挙動:
#   - 該当時は JSON {"decision":"block","reason":"..."} を stdout に出力
#   - 該当しなければ何も出さず exit 0
#
# 入力:
#   stdin に Claude Code の hook JSON。tool_input.command を参照。
# ============================================================================

# shellcheck disable=SC2016  # block メッセージ内の backtick は markdown 装飾で意図的
set -eu

cmd=$(jq -r '.tool_input.command // empty')

# 空・非 Bash なら素通し
[ -z "$cmd" ] && exit 0

# 共通判定スクリプトをスクリプト自身の位置から解決する
# （`~/.claude/hooks` はリポジトリへの symlink のため、物理パスへ正規化する）。
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
verdict_sh="$script_dir/../../.agents/hooks/force-push-verdict.sh"

# 共通判定が見つからない場合は素通し（defense-in-depth のため fail-open）
[ -f "$verdict_sh" ] || exit 0

verdict=$(printf '%s' "$cmd" | sh "$verdict_sh")

emit_block() {
    jq -n --arg reason "guard-force-push: $1" '{decision:"block",reason:$reason}'
    exit 0
}

case "$verdict" in
    combined)
        emit_block 'raw --force と --force-with-lease の併記は意図が矛盾するためブロックします。--force-with-lease 単独に絞ってください。'
        ;;
    raw)
        emit_block '`git push --force` (or -f / -uf など短縮結合形) is blocked. Prefer `git push --force-with-lease` after confirming with the user, or update the branch via rebase + PR review instead.'
        ;;
    mirror)
        emit_block '`git push --mirror` は全 ref を上書きするためブロックします。個別 branch を明示的に push してください。'
        ;;
    plus)
        emit_block '`+<refspec>` による強制更新はブロックします。lease 付きで push するか, rebase + PR review を経由してください。'
        ;;
esac

exit 0
