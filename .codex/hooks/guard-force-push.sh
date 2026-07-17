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
#   - -uf / -fu 等、短縮オプションの結合形に f を含むもの
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
#
# 実装メモ:
#   複数コマンド (`;` / `&&` / `||` / `|`) を含む入力に対応するため、
#   まず command を separator で分割し、各サブコマンドが `git ... push`
#   であるものだけを取り出す。以降の判定はサブコマンドの push 以降の
#   引数列に限定して行う（他コマンドの引数に含まれる `--force` などを
#   偽陽性で拾わないため、および先頭に現れる危険な push を貪欲マッチで
#   飛ばさないため）。
# ============================================================================

# shellcheck disable=SC2016  # 拒否メッセージ内の backtick は markdown 装飾で意図的
set -eu

cmd=$(jq -r '.tool_input.command // empty')

# 空・非 Bash なら素通し
[ -z "$cmd" ] && exit 0

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

# サブコマンドごとに push 引数を評価する。1 つでも危険な形が見つかれば拒否。
# awk は 1 変数のみ入力として扱うため、command 全体を stdin から流し込む。
verdict=$(printf '%s' "$cmd" | awk '
    function ltrim(s) { sub(/^[[:space:]]+/, "", s); return s }

    BEGIN { RS = "[;&|]+" }

    {
        line = ltrim($0)
        # `git ...push ...` の形を持つサブコマンドだけ評価。
        # git と push の間には任意個の flag / value トークンを許容する。
        if (line !~ /^git([[:space:]]+[^[:space:]]+)*[[:space:]]+push([[:space:]]|$)/) next

        # push 以降の引数列を取り出す（push の直後の空白より後 or 末尾）
        args = line
        sub(/^git([[:space:]]+[^[:space:]]+)*[[:space:]]+push/, "", args)
        args = ltrim(args)
        args_padded = " " args " "  # 前後 padding で境界マッチを簡潔化

        has_raw_force = 0
        has_with_lease = 0

        # --force / --force=<val>
        if (args_padded ~ /[[:space:]]--force([[:space:]]|=)/) has_raw_force = 1
        # 短縮結合形 -f / -uf / -fu / -abcf など (単ダッシュで f を含み等号なし)
        if (args_padded ~ /[[:space:]]-[[:alnum:]]*f[[:alnum:]]*[[:space:]]/) has_raw_force = 1

        # --force-with-lease
        if (args_padded ~ /[[:space:]]--force-with-lease([[:space:]]|=)/) has_with_lease = 1

        if (has_raw_force && has_with_lease) {
            print "combined"
            exit
        }
        if (has_raw_force) {
            print "raw"
            exit
        }

        # --mirror
        if (args_padded ~ /[[:space:]]--mirror[[:space:]]/) {
            print "mirror"
            exit
        }

        # +<refspec>: token whose first non-blank char is +
        if (args_padded ~ /[[:space:]]\+[^[:space:]]+[[:space:]]/) {
            print "plus"
            exit
        }
    }
')

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
