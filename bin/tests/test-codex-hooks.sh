#!/bin/sh
# ============================================================================
# test-codex-hooks.sh
#
# 回帰テスト:
#   1. Codex 用ガード (guard-protected-apply-patch.sh / guard-force-push.sh)
#      - 保護対象 / 非保護対象、拒否パターン / 許可パターンの判定
#      - 拒否時は hookSpecificOutput.permissionDecision == "deny" を返す
#      - いずれの経路も終了コードは 0
#   2. bin/agent_hooks.sh
#      - 一時 HOME 上での install → reinstall → uninstall の冪等性
#      - unrelated Hook の保持
#      - 生成 JSON が jq empty を通る
#   3. bin/link.sh
#      - クリーンな HOME にディレクトリを含む TARGETS を link できる
#      - unlink で symlink のみ削除される
#
# 依存: sh (POSIX), jq
# 実行: sh bin/tests/test-codex-hooks.sh
# ============================================================================

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
GUARD_APPLY="$REPO_ROOT/.codex/hooks/guard-protected-apply-patch.sh"
GUARD_BASH="$REPO_ROOT/.codex/hooks/guard-force-push.sh"
AGENT_HOOKS="$REPO_ROOT/bin/agent_hooks.sh"
LINK_SH="$REPO_ROOT/bin/link.sh"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

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

# assert_deny: JSON input -> exit code 0 and permissionDecision == "deny".
assert_deny() {
    guard="$1"
    input="$2"
    out=$(printf '%s' "$input" | sh "$guard") || {
        fail "guard exited non-zero"
        return
    }
    decision=$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // ""' 2>/dev/null || echo "")
    if [ "$decision" != "deny" ]; then
        fail "expected deny, got '$decision' from output: $out"
        return
    fi
    pass
}

# assert_allow: JSON input -> exit code 0 and empty stdout.
assert_allow() {
    guard="$1"
    input="$2"
    out=$(printf '%s' "$input" | sh "$guard") || {
        fail "guard exited non-zero"
        return
    }
    if [ -n "$out" ]; then
        fail "expected empty stdout, got: $out"
        return
    fi
    pass
}

# ------------------------------------------------------------------
# 1. guard-protected-apply-patch.sh
# ------------------------------------------------------------------
echo "# guard-protected-apply-patch"

current_case="deny: Add File .env"
assert_deny "$GUARD_APPLY" '{"tool_input":{"command":"*** Begin Patch\n*** Add File: .env\n+SECRET=1\n*** End Patch\n"}}'

current_case="deny: Update File package-lock.json"
assert_deny "$GUARD_APPLY" '{"tool_input":{"command":"*** Update File: package-lock.json\n@@ ...\n"}}'

current_case="deny: Delete File yarn.lock"
assert_deny "$GUARD_APPLY" '{"tool_input":{"command":"*** Delete File: yarn.lock\n"}}'

current_case="deny: Move to Cargo.lock"
assert_deny "$GUARD_APPLY" '{"tool_input":{"command":"*** Update File: old.lock\n*** Move to: Cargo.lock\n"}}'

current_case="deny: Add File under .git/"
assert_deny "$GUARD_APPLY" '{"tool_input":{"command":"*** Add File: .git/hooks/pre-commit\n"}}'

current_case="deny: .env.local"
assert_deny "$GUARD_APPLY" '{"tool_input":{"command":"*** Add File: apps/web/.env.local\n"}}'

current_case="allow: normal source file"
assert_allow "$GUARD_APPLY" '{"tool_input":{"command":"*** Update File: src/main.rs\n@@ -1 +1 @@\n"}}'

current_case="allow: missing tool_input"
assert_allow "$GUARD_APPLY" '{}'

current_case="allow: no patch headers"
assert_allow "$GUARD_APPLY" '{"tool_input":{"command":"echo hello"}}'

# ------------------------------------------------------------------
# 2. guard-force-push.sh
# ------------------------------------------------------------------
echo "# guard-force-push"

current_case="deny: git push -f"
assert_deny "$GUARD_BASH" '{"tool_input":{"command":"git push -f origin main"}}'

current_case="deny: git push --force"
assert_deny "$GUARD_BASH" '{"tool_input":{"command":"git push --force origin main"}}'

current_case="deny: git push --force=<val>"
assert_deny "$GUARD_BASH" '{"tool_input":{"command":"git push --force=v1 origin main"}}'

current_case="deny: git -c foo=bar push --force"
assert_deny "$GUARD_BASH" '{"tool_input":{"command":"git -c foo=bar push --force origin main"}}'

current_case="deny: raw force + with-lease併記"
assert_deny "$GUARD_BASH" '{"tool_input":{"command":"git push --force-with-lease --force origin main"}}'

current_case="deny: git push --mirror"
assert_deny "$GUARD_BASH" '{"tool_input":{"command":"git push --mirror origin"}}'

current_case="deny: +refspec"
assert_deny "$GUARD_BASH" '{"tool_input":{"command":"git push origin +main"}}'

current_case="deny: 短縮結合オプション -uf"
assert_deny "$GUARD_BASH" '{"tool_input":{"command":"git push -uf origin main"}}'

current_case="deny: 短縮結合オプション -fu"
assert_deny "$GUARD_BASH" '{"tool_input":{"command":"git push -fu origin main"}}'

current_case="deny: 複数コマンドの先頭が危険な +refspec"
assert_deny "$GUARD_BASH" '{"tool_input":{"command":"git push origin +main; echo push done"}}'

current_case="deny: 複数コマンドの後段に危険な push"
assert_deny "$GUARD_BASH" '{"tool_input":{"command":"echo start && git push --force origin main"}}'

current_case="allow: git push --force-with-lease"
assert_allow "$GUARD_BASH" '{"tool_input":{"command":"git push --force-with-lease origin main"}}'

current_case="allow: git push --force-with-lease --force-if-includes"
assert_allow "$GUARD_BASH" '{"tool_input":{"command":"git push --force-with-lease --force-if-includes origin main"}}'

current_case="allow: git push --force-if-includes only"
assert_allow "$GUARD_BASH" '{"tool_input":{"command":"git push --force-if-includes origin main"}}'

current_case="allow: git push (no force)"
assert_allow "$GUARD_BASH" '{"tool_input":{"command":"git push origin main"}}'

current_case="allow: 安全な push の後段に --force を含む別コマンド"
assert_allow "$GUARD_BASH" '{"tool_input":{"command":"git push --force-with-lease origin main; echo --force done"}}'

current_case="allow: git push -u (upstream, no force)"
assert_allow "$GUARD_BASH" '{"tool_input":{"command":"git push -u origin main"}}'

current_case="allow: empty command"
assert_allow "$GUARD_BASH" '{}'

# ------------------------------------------------------------------
# 3. agent_hooks.sh install / reinstall / uninstall
# ------------------------------------------------------------------
echo "# agent_hooks: install / reinstall / uninstall"

HOME_DIR="$WORK/home"
mkdir -p "$HOME_DIR/.tmux" "$HOME_DIR/.agents/hooks" "$HOME_DIR/.codex/hooks" "$HOME_DIR/.claude"
touch "$HOME_DIR/.tmux/agent-status.sh"
cp "$REPO_ROOT/.agents/hooks/notify-sound.sh" "$HOME_DIR/.agents/hooks/"
cp "$GUARD_APPLY" "$HOME_DIR/.codex/hooks/"
cp "$GUARD_BASH" "$HOME_DIR/.codex/hooks/"

# Seed unrelated Claude hooks (guard-* から notify-sound legacy まで含める)
cat > "$HOME_DIR/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Edit|Write|MultiEdit", "hooks": [
        { "type": "command", "command": "sh ~/.claude/hooks/guard-protected-files.sh", "timeout": 3 }
      ]}
    ],
    "Notification": [
      { "hooks": [
        { "type": "command", "command": "sh ~/.claude/hooks/notify-sound.sh", "timeout": 3 },
        { "type": "command", "command": "sh ~/.claude/hooks/user-unrelated.sh", "timeout": 3 }
      ]}
    ]
  }
}
JSON

HOME="$HOME_DIR" sh "$AGENT_HOOKS" install >/dev/null
HOME="$HOME_DIR" sh "$AGENT_HOOKS" install >/dev/null

current_case="claude Notification group count is 2 (unrelated + managed) after 2nd install"
count=$(jq '.hooks.Notification | length' "$HOME_DIR/.claude/settings.json")
if [ "$count" = "2" ]; then pass; else fail "expected 2, got $count"; fi

current_case="claude PreToolUse unrelated guard is preserved"
n=$(jq '[.hooks.PreToolUse[]?.hooks[]? | select(.command | contains("guard-protected-files.sh"))] | length' "$HOME_DIR/.claude/settings.json")
if [ "$n" = "1" ]; then pass; else fail "expected 1, got $n"; fi

current_case="claude Notification user-unrelated is preserved"
n=$(jq '[.hooks.Notification[]?.hooks[]? | select(.command | contains("user-unrelated.sh"))] | length' "$HOME_DIR/.claude/settings.json")
if [ "$n" = "1" ]; then pass; else fail "expected 1, got $n"; fi

current_case="claude legacy .claude/hooks/notify-sound.sh is removed"
n=$(jq '[.hooks.Notification[]?.hooks[]? | select(.command | contains(".claude/hooks/notify-sound.sh"))] | length' "$HOME_DIR/.claude/settings.json")
if [ "$n" = "0" ]; then pass; else fail "expected 0, got $n"; fi

current_case="claude shared notify-sound is registered once"
n=$(jq '[.hooks.Notification[]?.hooks[]? | select(.command | contains(".agents/hooks/notify-sound.sh"))] | length' "$HOME_DIR/.claude/settings.json")
if [ "$n" = "1" ]; then pass; else fail "expected 1, got $n"; fi

current_case="codex PreToolUse has exactly 2 matcher groups"
n=$(jq '.hooks.PreToolUse | length' "$HOME_DIR/.codex/hooks.json")
if [ "$n" = "2" ]; then pass; else fail "expected 2, got $n"; fi

current_case="codex PermissionRequest group has 2 handlers"
n=$(jq '.hooks.PermissionRequest[0].hooks | length' "$HOME_DIR/.codex/hooks.json")
if [ "$n" = "2" ]; then pass; else fail "expected 2, got $n"; fi

current_case="codex apply_patch matcher registered"
n=$(jq '[.hooks.PreToolUse[]? | select(.matcher == "^apply_patch$")] | length' "$HOME_DIR/.codex/hooks.json")
if [ "$n" = "1" ]; then pass; else fail "expected 1, got $n"; fi

current_case="codex Bash matcher registered"
n=$(jq '[.hooks.PreToolUse[]? | select(.matcher == "^Bash$")] | length' "$HOME_DIR/.codex/hooks.json")
if [ "$n" = "1" ]; then pass; else fail "expected 1, got $n"; fi

current_case="claude settings.json is valid JSON"
if jq empty "$HOME_DIR/.claude/settings.json"; then pass; else fail "invalid JSON"; fi

current_case="codex hooks.json is valid JSON"
if jq empty "$HOME_DIR/.codex/hooks.json"; then pass; else fail "invalid JSON"; fi

# Uninstall
HOME="$HOME_DIR" sh "$AGENT_HOOKS" uninstall >/dev/null

current_case="uninstall: claude unrelated guard is still preserved"
n=$(jq '[.hooks.PreToolUse[]?.hooks[]? | select(.command | contains("guard-protected-files.sh"))] | length' "$HOME_DIR/.claude/settings.json")
if [ "$n" = "1" ]; then pass; else fail "expected 1, got $n"; fi

current_case="uninstall: claude user-unrelated still preserved"
n=$(jq '[.hooks.Notification[]?.hooks[]? | select(.command | contains("user-unrelated.sh"))] | length' "$HOME_DIR/.claude/settings.json")
if [ "$n" = "1" ]; then pass; else fail "expected 1, got $n"; fi

current_case="uninstall: claude tmux status handlers removed"
n=$(jq '[.hooks | .. | objects | select(has("command")) | .command | select(contains("agent-status.sh"))] | length' "$HOME_DIR/.claude/settings.json")
if [ "$n" = "0" ]; then pass; else fail "expected 0, got $n"; fi

current_case="uninstall: claude shared notify-sound removed"
n=$(jq '[.hooks | .. | objects | select(has("command")) | .command | select(contains(".agents/hooks/notify-sound.sh"))] | length' "$HOME_DIR/.claude/settings.json")
if [ "$n" = "0" ]; then pass; else fail "expected 0, got $n"; fi

current_case="uninstall: codex Codex-only guards removed"
n=$(jq '[.hooks | .. | objects | select(has("command")) | .command | select(contains(".codex/hooks/guard-"))] | length' "$HOME_DIR/.codex/hooks.json")
if [ "$n" = "0" ]; then pass; else fail "expected 0, got $n"; fi

# ------------------------------------------------------------------
# 4. link.sh
# ------------------------------------------------------------------
echo "# link.sh"

LINK_HOME="$WORK/link_home"
mkdir -p "$LINK_HOME"
# link.sh uses HOME, pwd, and expects to be run from repo root. link mode takes no arg.
(cd "$REPO_ROOT" && HOME="$LINK_HOME" sh "$LINK_SH" >/dev/null)

current_case="link: ~/.agents/hooks is a symlink"
if [ -L "$LINK_HOME/.agents/hooks" ]; then pass; else fail "not a symlink"; fi

current_case="link: ~/.codex/hooks is a symlink"
if [ -L "$LINK_HOME/.codex/hooks" ]; then pass; else fail "not a symlink"; fi

current_case="link: ~/.claude/hooks is a symlink"
if [ -L "$LINK_HOME/.claude/hooks" ]; then pass; else fail "not a symlink"; fi

(cd "$REPO_ROOT" && HOME="$LINK_HOME" sh "$LINK_SH" unlink >/dev/null)

current_case="unlink: ~/.agents/hooks symlink is removed"
if [ ! -L "$LINK_HOME/.agents/hooks" ]; then pass; else fail "still a symlink"; fi

current_case="unlink: ~/.codex/hooks symlink is removed"
if [ ! -L "$LINK_HOME/.codex/hooks" ]; then pass; else fail "still a symlink"; fi

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
