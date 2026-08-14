#!/bin/sh
# ============================================================================
# guard-protected-files.sh
#
# Hook event : PreToolUse
# Matcher    : Edit | Write | MultiEdit
#
# 目的:
#   Claude Code に「絶対に手編集させたくない」ファイル群への
#   Edit / Write / MultiEdit をブロックする。
#   permissions.deny は Read しか制限できないため、書き込み側の
#   セーフティネットとしてこの hook で対応する。
#
# 保護対象:
#   - .env / .env.<suffix>
#   - lockfile 系: package-lock.json, yarn.lock, pnpm-lock.yaml,
#                  Cargo.lock, go.sum, composer.lock
#   - .git/ 配下（オブジェクトや参照の直接編集）
#     ただし .git/wtr/ 配下は wtr が作る worktree の作業ツリーであり、
#     git の内部データではないため保護対象から除外する
#     （除外しないと worktree 内のソース編集が全面的にブロックされる）
#
# 挙動:
#   - 該当時は stdout に JSON {"decision":"block","reason":"..."} を出力
#     → LLM に理由付きで拒否が伝わる（再度別手段を検討する）
#   - 該当しなければ何も出さず exit 0
#
# 入力:
#   stdin に Claude Code から hook 用の JSON。tool_input.file_path を参照。
# ============================================================================

set -eu

file_path=$(jq -r '.tool_input.file_path // empty')

# file_path が取れない（別スキーマ）ときは素通し
[ -z "$file_path" ] && exit 0

# 保護対象パターン
# ファイル名ベースの保護（場所を問わず、worktree 内でも適用する）
PROTECTED_NAME='(^|/)(\.env(\.[^/]+)?|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.lock|go\.sum|composer\.lock)$'
# git の内部データ
GIT_INTERNAL='/\.git/'
# wtr が作る worktree の作業ツリー（GIT_INTERNAL から除外する）
GIT_WORKTREE='/\.git/wtr/'

if echo "$file_path" | grep -qE "$PROTECTED_NAME" \
  || { echo "$file_path" | grep -qE "$GIT_INTERNAL" \
       && ! echo "$file_path" | grep -qE "$GIT_WORKTREE"; }; then
  cat <<EOF
{"decision":"block","reason":"guard-protected-files: '$file_path' is a protected file (.env / lockfile / .git). Do not edit directly. If regeneration is needed, run the appropriate package manager or migration command instead, and confirm with the user first."}
EOF
  exit 0
fi

exit 0
