#!/bin/sh
# ============================================================================
# guard-force-push.sh
#
# Hook event : PreToolUse
# Matcher    : Bash
#
# 目的:
#   `git push --force` / `git push -f` 相当のコマンドを hook でブロック。
#   permissions.deny のパターンマッチは "git -c ... push --force" のような
#   接頭 flag が付いた形を素通しさせる隙間があるため、意味論ベースで防ぐ。
#
# ブロック対象:
#   - git push ... -f
#   - git push ... --force
#   - git push ... --force=<value>
#
# 素通し（相対的に安全なので許可）:
#   - git push --force-with-lease [--force-if-includes]
#
# 挙動:
#   - 該当時は JSON {"decision":"block","reason":"..."} を stdout に出力
#   - 該当しなければ何も出さず exit 0
#
# 入力:
#   stdin に Claude Code の hook JSON。tool_input.command を参照。
# ============================================================================

set -eu

cmd=$(jq -r '.tool_input.command // empty')

# 空・非 Bash なら素通し
[ -z "$cmd" ] && exit 0

# git push を含まないなら素通し
echo "$cmd" | grep -qE '(^|[[:space:];&|]+)git( +-[^ ]+)*  *push([[:space:];&|]|$)' || exit 0

# --force-with-lease 系は許可（先にホワイトリスト判定）
if echo "$cmd" | grep -qE '(^| )--force-with-lease($|=| )'; then
  exit 0
fi

# -f / --force / --force=<val> を検出
if echo "$cmd" | grep -qE '(^| )(-f|--force)($|=| )'; then
  cat <<'EOF'
{"decision":"block","reason":"guard-force-push: `git push --force` (or -f) is blocked. Prefer `git push --force-with-lease` after confirming with the user, or update the branch via rebase + PR review instead."}
EOF
  exit 0
fi

exit 0
