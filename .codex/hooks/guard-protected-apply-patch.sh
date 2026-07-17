#!/bin/sh
# ============================================================================
# guard-protected-apply-patch.sh
#
# Hook event : PreToolUse
# Matcher    : ^apply_patch$
#
# 目的:
#   Codex の apply_patch tool で、保護対象ファイル群への変更を拒否する。
#   Codex は apply_patch の入力を .tool_input.command にパッチ全文として渡す
#   ため、ヘッダーから対象パスを抽出して判定する。
#
# 保護対象:
#   - .env / .env.<suffix>
#   - lockfile 系: package-lock.json, yarn.lock, pnpm-lock.yaml,
#                  Cargo.lock, go.sum, composer.lock
#   - .git/ 配下
#
# 解析するヘッダー:
#   *** Add File: <path>
#   *** Update File: <path>
#   *** Delete File: <path>
#   *** Move to: <path>
#
# 挙動:
#   - いずれかのパスが保護対象なら hookSpecificOutput.permissionDecision=deny
#     を JSON で stdout に出力する（終了コードは常に 0）
#   - 該当しなければ何も出さず exit 0
#
# 入力:
#   stdin に Codex から hook 用の JSON。.tool_input.command を参照。
# ============================================================================

set -eu

command=$(jq -r '.tool_input.command // empty')

# command が取れない（別スキーマ）ときは素通し
[ -z "$command" ] && exit 0

protected_pattern='(^|/)(\.env(\.[^/]+)?|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.lock|go\.sum|composer\.lock)$|(^|/)\.git(/|$)'

# パッチヘッダーから対象パスを抽出（* 4種のいずれか）
paths=$(printf '%s\n' "$command" | sed -n \
    -e 's/^\*\*\* Add File: //p' \
    -e 's/^\*\*\* Update File: //p' \
    -e 's/^\*\*\* Delete File: //p' \
    -e 's/^\*\*\* Move to: //p')

[ -z "$paths" ] && exit 0

hit=$(printf '%s\n' "$paths" | grep -E "$protected_pattern" | head -n 1 || true)

if [ -n "$hit" ]; then
    reason="guard-protected-apply-patch: '$hit' is a protected file (.env / lockfile / .git). Do not edit directly. If regeneration is needed, run the appropriate package manager or migration command instead, and confirm with the user first."
    jq -n --arg reason "$reason" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $reason
        }
    }'
    exit 0
fi

exit 0
