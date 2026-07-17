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
# 拒否対象:
#   - git push -f / --force / --force=<val>
#   - --force-with-lease と raw force を併記したケース（意図が矛盾するため raw force 側を優先して拒否）
#   - git push --mirror
#   - +<refspec> による強制更新（例: git push origin +main）
#
# 許可:
#   - git push --force-with-lease [--force-if-includes]
#   - git push --force-if-includes 単独（lease がない場合は Git 上 no-op）
#   - 通常の git push
#
# 挙動:
#   - 該当時は hookSpecificOutput.permissionDecision=deny を JSON で stdout に出力
#   - 該当しなければ何も出さず exit 0（終了コードは常に 0）
#
# 入力:
#   stdin に Codex の hook JSON。.tool_input.command を参照。
# ============================================================================

# shellcheck disable=SC2016  # 拒否メッセージ内の backtick は markdown 装飾で意図的
set -eu

cmd=$(jq -r '.tool_input.command // empty')

# 空・非 Bash なら素通し
[ -z "$cmd" ] && exit 0

# git push を含まないなら素通し。git と push の間に任意の flag / value トークンを許容する
# （例: `git -c foo=bar push --force`）。; / & / | は command 境界とみなす。
echo "$cmd" | grep -qE '(^|[[:space:];&|])git([[:space:]]+[^[:space:];&|]+)*[[:space:]]+push([[:space:];&|]|$)' || exit 0

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

has_raw_force=false
if echo "$cmd" | grep -qE '(^| )(-f|--force)($|=| )'; then
    has_raw_force=true
fi

has_with_lease=false
if echo "$cmd" | grep -qE '(^| )--force-with-lease($|=| )'; then
    has_with_lease=true
fi

# raw force と --force-with-lease の併記は raw force 側を優先して拒否
if [ "$has_raw_force" = true ] && [ "$has_with_lease" = true ]; then
    emit_deny 'raw --force と --force-with-lease の併記は意図が矛盾するため拒否します。--force-with-lease 単独に絞ってください。'
fi

# raw force
if [ "$has_raw_force" = true ]; then
    emit_deny '`git push --force` (or -f) is blocked. Prefer `git push --force-with-lease` after confirming with the user, or update the branch via rebase + PR review instead.'
fi

# --mirror
if echo "$cmd" | grep -qE '(^| )--mirror($| )'; then
    emit_deny '`git push --mirror` は全 ref を上書きするため拒否します。個別 branch を明示的に push してください。'
fi

# +<refspec> による強制更新: git push <remote> +<ref>[:<ref>] を検出
# push サブコマンド以降の位置引数を評価する必要があるため簡略化:
# コマンド全体に " +<非空白>" もしくは "^+<非空白>" が現れ、
# それが git push の refspec 位置に相当するかを判定する。
# 誤検知を避けるため、"push" 以降の部分だけを対象にする。
push_tail=$(echo "$cmd" | sed -n 's/.*[[:space:]]push\([[:space:]].*\)/\1/p')
if [ -n "$push_tail" ] && echo "$push_tail" | grep -qE '(^|[[:space:]])\+[^[:space:]]+'; then
    emit_deny '`+<refspec>` による強制更新は拒否します。lease 付きで push するか, rebase + PR review を経由してください。'
fi

exit 0
