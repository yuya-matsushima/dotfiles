#!/bin/sh
# ============================================================================
# guard-force-push.sh
#
# Hook event : PreToolUse
# Matcher    : ^Bash$
#
# 目的:
#   Codex の Bash tool で、危険な force push を拒否する。
#   permissions のパターンマッチは "git -c ... push --force" のような
#   接頭 flag が付いた形を素通しさせる隙間があるため、意味論ベースで防ぐ。
#
# 判定:
#   実際の判定ロジックは共通スクリプト
#   `~/.agents/hooks/force-push-verdict.sh` に集約している。
#   本スクリプトは Codex の hook JSON の入出力だけを担う薄いアダプタで、
#   verdict を Codex の拒否 JSON に変換する。
#
#   拒否する verdict:
#     - combined : raw --force と --force-with-lease を併記
#     - raw      : git push -f / --force / 短縮結合形
#     - mirror   : git push --mirror
#     - plus     : +<refspec> による強制更新
#
#   許可:
#     - git push --force-with-lease [--force-if-includes]
#     - git push --force-if-includes 単独（lease がない場合は Git 上 no-op）
#     - 通常の git push
#
# 挙動:
#   - 該当時は hookSpecificOutput.permissionDecision=deny を JSON で stdout に出力
#   - 該当しなければ何も出さず exit 0（終了コードは常に 0）
#
# 入力:
#   stdin に Codex の hook JSON。.tool_input.command を参照。
# ============================================================================

# shellcheck disable=SC2016  # deny メッセージ内の backtick は markdown 装飾で意図的
set -eu

cmd=$(jq -r '.tool_input.command // empty')

# 空・非 Bash なら素通し
[ -z "$cmd" ] && exit 0

# 共通判定スクリプトをスクリプト自身の位置から解決する
# （`~/.codex/hooks` はリポジトリへの symlink のため、物理パスへ正規化する）。
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
verdict_sh="$script_dir/../../.agents/hooks/force-push-verdict.sh"

# 共通判定が見つからない場合は素通し（defense-in-depth のため fail-open）
[ -f "$verdict_sh" ] || exit 0

verdict=$(printf '%s' "$cmd" | sh "$verdict_sh")

emit_deny() {
    reason="guard-force-push: $1"
    jq -n --arg reason "$reason" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $reason
        }
    }'
    exit 0
}

case "$verdict" in
    combined)
        emit_deny 'raw --force と --force-with-lease の併記は意図が矛盾するため拒否します。--force-with-lease 単独に絞ってください。'
        ;;
    raw)
        emit_deny '`git push --force` (or -f / -uf など短縮結合形) is blocked. Prefer `git push --force-with-lease` after confirming with the user, or update the branch via rebase + PR review instead.'
        ;;
    mirror)
        emit_deny '`git push --mirror` は全 ref を上書きするため拒否します。個別 branch を明示的に push してください。'
        ;;
    plus)
        emit_deny '`+<refspec>` による強制更新は拒否します。lease 付きで push するか, rebase + PR review を経由してください。'
        ;;
esac

exit 0
