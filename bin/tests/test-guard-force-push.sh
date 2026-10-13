#!/bin/sh
# ============================================================================
# test-guard-force-push.sh
#
# 回帰テスト:
#   Claude Code 版 / Codex 版の guard-force-push.sh を同じコマンドケース群に
#   stdin で流し、次の 2 点を検証する。
#     1. 各 hook が「期待」(deny / allow) どおりに判定する
#     2. Claude 版と Codex 版の判定が完全に一致する
#
#   判定ロジックは .agents/hooks/force-push-verdict.sh に集約されているため、
#   ここでは両 hook の入出力アダプタと共通判定の回帰をまとめて確認する。
#
#   3. 理由文言が共通スクリプト (.agents/hooks/force-push-reason.sh) と一致し、
#      Claude 版 / Codex 版 (および Pi 版) で同一であること
#
# 依存: sh (POSIX), jq
# 実行: sh bin/tests/test-guard-force-push.sh
# ============================================================================

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
CLAUDE_HOOK="$REPO_ROOT/.claude/hooks/guard-force-push.sh"
CODEX_HOOK="$REPO_ROOT/.codex/hooks/guard-force-push.sh"

pass_count=0
fail_count=0
current_case=""

pass() {
    pass_count=$((pass_count + 1))
    printf '  ok  %s\n' "$current_case"
}

fail() {
    fail_count=$((fail_count + 1))
    printf '  NG  %s: %s\n' "$current_case" "$1" >&2
}

# classify <hook> <command>: deny / allow / unexpected のいずれかを stdout に返す。
#   - 終了コードが 0 以外 -> exit-nonzero
#   - stdout が空          -> allow
#   - Codex 形式           -> hookSpecificOutput.permissionDecision
#   - Claude Code 形式     -> decision == "block" を deny に正規化
classify() {
    hook="$1"
    cmd="$2"
    input=$(jq -cn --arg c "$cmd" '{tool_input:{command:$c}}')
    out=$(printf '%s' "$input" | sh "$hook") || { echo "exit-nonzero"; return; }
    if [ -z "$out" ]; then
        echo "allow"
        return
    fi
    d=$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null || echo "")
    if [ -n "$d" ]; then
        echo "$d"
        return
    fi
    d=$(printf '%s' "$out" | jq -r 'if .decision == "block" then "deny" else empty end' 2>/dev/null || echo "")
    if [ -n "$d" ]; then
        echo "$d"
        return
    fi
    echo "unexpected"
}

# check <deny|allow> <command>
check() {
    expected="$1"
    cmd="$2"
    current_case="$expected: $cmd"
    claude=$(classify "$CLAUDE_HOOK" "$cmd")
    codex=$(classify "$CODEX_HOOK" "$cmd")
    if [ "$claude" != "$expected" ] || [ "$codex" != "$expected" ]; then
        fail "claude=$claude codex=$codex expected=$expected"
        return
    fi
    if [ "$claude" != "$codex" ]; then
        fail "parity mismatch claude=$claude codex=$codex"
        return
    fi
    pass
}

# ------------------------------------------------------------------
# 入力が空
# ------------------------------------------------------------------
check allow ''

# ------------------------------------------------------------------
# 再現表 (issue #250)
# ------------------------------------------------------------------
check allow 'rm -f a.txt; git push origin HEAD'
check deny  'git push --force-with-lease origin a; git push -f origin b'
check deny  'git push origin +HEAD:main'
check deny  'git push --force origin HEAD'
check allow 'git push origin HEAD'

# ------------------------------------------------------------------
# deny: raw force (--force / -f / --force=<val>)
# ------------------------------------------------------------------
check deny 'git push -f origin main'
check deny 'git push --force origin main'
check deny 'git push --force=v1 origin main'
check deny 'git -c foo=bar push --force origin main'
check deny 'git push -uf origin main'
check deny 'git push -fu origin main'
check deny 'git push "--force" origin main'

# ------------------------------------------------------------------
# deny: combined (raw force + --force-with-lease 併記)
# ------------------------------------------------------------------
check deny 'git push --force-with-lease --force origin main'

# ------------------------------------------------------------------
# deny: --mirror / +refspec
# ------------------------------------------------------------------
check deny 'git push --mirror origin'
check deny 'git push origin +main'
check deny "git push origin '+main'"
check deny 'git push origin +main; echo push done'

# ------------------------------------------------------------------
# deny: 連結・改行・行継続
# ------------------------------------------------------------------
check deny 'echo start && git push --force origin main'
check deny 'echo ok
git push --force origin main'
check deny 'git push origin main \
  --force'

# ------------------------------------------------------------------
# deny: env / global option / wrapper / subshell
# ------------------------------------------------------------------
check deny 'GIT_SSH_COMMAND=ssh git push --force origin main'
check deny 'env git push -f origin main'
check deny 'env FOO=bar git push --force origin main'
check deny "GIT_SSH_COMMAND='ssh -i key' git push --force origin main"
check deny 'git --git-dir /tmp/repo/.git push --force origin main'
check deny 'git --work-tree /tmp/tree push -f origin main'
check deny '(git push --force origin main)'
check deny 'if true; then git push -f origin main; fi'
check deny '{ git push --force origin main; }'
check deny 'command git push --force origin main'
check deny 'exec git push -f origin main'
check deny '/usr/bin/git push --force origin main'

# ------------------------------------------------------------------
# deny: wrapper (sudo) / 制御キーワード後ろの env 代入 (回帰: cross-review P2)
# ------------------------------------------------------------------
check deny 'sudo git push --force origin main'
check deny 'sudo git push -f origin main'
check deny 'if true; then GIT_SSH_COMMAND=ssh git push --force origin main; fi'
check deny 'if true; then FOO=bar git push -f origin main; fi'
check deny '{ FOO=bar git push --force origin main; }'
check deny 'time GIT_SSH_COMMAND=ssh git push --force origin main'
check deny 'command sudo git push --force origin main'

# ------------------------------------------------------------------
# deny: refspec 名が push のケース (subcommand 誤認しない)
# ------------------------------------------------------------------
check deny 'git push --force origin push'
check deny 'git push -f origin push'

# ------------------------------------------------------------------
# allow: 通常 push / lease / force-if-includes
# ------------------------------------------------------------------
check allow 'git push origin main'
check allow 'git push -u origin main'
check allow 'git push --force-with-lease origin main'
check allow 'git push --force-with-lease --force-if-includes origin main'
check allow 'git push --force-if-includes origin main'
check allow 'git push --force-with-lease origin main; echo --force done'

# ------------------------------------------------------------------
# allow: 別 subcommand の引数に push が現れるケース
# ------------------------------------------------------------------
check allow 'git checkout push --force'
check allow 'git --no-pager checkout push --force'

# ------------------------------------------------------------------
# allow: -ofoo は push-option の短縮で -f の結合形ではない
# ------------------------------------------------------------------
check allow 'git push -ofoo origin main'
check allow 'git push -o key=value origin main'

# ------------------------------------------------------------------
# allow: 値を取る push option の値は強制更新フラグではない (回帰: cross-review P2)
# ------------------------------------------------------------------
check allow 'git push --force-with-lease -o --force origin main'
check allow 'git push --force-with-lease --push-option +deploy origin main'
check allow 'git push -o --force origin main'
check allow 'git push --push-option +deploy origin main'

# ------------------------------------------------------------------
# deny: 値を消費した後に現れる本物の強制更新フラグ
# ------------------------------------------------------------------
check deny 'git push -o foo --force origin main'
check deny 'git push --push-option foo +main'

# ------------------------------------------------------------------
# allow: wrapper 付きでも git push でなければ許可
# ------------------------------------------------------------------
check allow 'sudo echo git push --force origin main'
check allow 'sudo git push origin main'

# ------------------------------------------------------------------
# allow: シングルクォート内は subcommand 分割しない
# ------------------------------------------------------------------
check allow "echo 'x;git push --force origin main'"
check allow "echo 'x; git push --force'"
check allow "echo 'do not run git push --force'"

# ------------------------------------------------------------------
# 理由文言は共通スクリプト (.agents/hooks/force-push-reason.sh) が唯一の出所。
# Claude 版 / Codex 版 (および Pi 版) が同じ文言を relay することを確認する。
# ------------------------------------------------------------------
REASON_SH="$REPO_ROOT/.agents/hooks/force-push-reason.sh"

# reason_of <hook> <command>: block JSON から理由文言を取り出す
reason_of() {
    hook="$1"
    cmd="$2"
    input=$(jq -cn --arg c "$cmd" '{tool_input:{command:$c}}')
    out=$(printf '%s' "$input" | sh "$hook")
    printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecisionReason // .reason // empty'
}

current_case="reason: 既知 verdict はすべて文言を持つ"
missing=""
for v in combined raw mirror plus; do
    [ -n "$(sh "$REASON_SH" "$v")" ] || missing="$missing $v"
done
if [ -z "$missing" ]; then pass; else fail "empty reason for:$missing"; fi

current_case="reason: 未知 verdict も fail-closed で文言を返す"
if [ -n "$(sh "$REASON_SH" unknown-verdict)" ]; then pass; else fail "empty reason"; fi

current_case="reason: Claude 版は共有スクリプトと一致"
expected="guard-force-push: $(sh "$REASON_SH" raw)"
got=$(reason_of "$CLAUDE_HOOK" 'git push --force origin main')
if [ "$got" = "$expected" ]; then pass; else fail "claude='$got' expected='$expected'"; fi

current_case="reason: Codex 版は共有スクリプトと一致"
expected="guard-force-push: $(sh "$REASON_SH" mirror)"
got=$(reason_of "$CODEX_HOOK" 'git push --mirror origin')
if [ "$got" = "$expected" ]; then pass; else fail "codex='$got' expected='$expected'"; fi

current_case="reason: Claude と Codex の文言が一致 (combined)"
claude_reason=$(reason_of "$CLAUDE_HOOK" 'git push --force-with-lease --force origin main')
codex_reason=$(reason_of "$CODEX_HOOK" 'git push --force-with-lease --force origin main')
if [ -n "$claude_reason" ] && [ "$claude_reason" = "$codex_reason" ]; then
    pass
else
    fail "claude='$claude_reason' codex='$codex_reason'"
fi

# ------------------------------------------------------------------
# 集計
# ------------------------------------------------------------------
echo ""
echo "=========================================="
printf '  passed: %d\n' "$pass_count"
printf '  failed: %d\n' "$fail_count"
echo "=========================================="

if [ "$fail_count" -gt 0 ]; then
    exit 1
fi
exit 0
