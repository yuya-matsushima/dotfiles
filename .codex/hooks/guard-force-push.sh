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
#   - +<refspec>: 引数中の + で始まる token（強制更新）
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
#   1. command 全体を単一 record として読み、シングルクォート内の separator
#      (; / & / | / \n) を空白に neutralize してから subcommand 分割する。
#      これにより `echo 'x;git push --force ...'` のような単なる文字列引数を
#      subcommand として誤検出しない。
#   2. 各 subcommand は先頭の env-var 代入 / env コマンドを剥がしてから
#      whitespace で token 化し、tok[1]=='git' かつ最初の 'push' token を
#      subcommand 位置として扱う。POSIX awk の longest-match による
#      `git push --force origin push` (refspec 名が push) のような bypass を
#      避けるため。
#   3. token 化後の args から quote (' / ") を除去してから regex 判定する。
#      シェル実行時に quote が除去されて git に argv として渡るため。
#
# 既知の限界（defense-in-depth の限界として明示的に許容）:
#   - ダブルクォート内・ヒアドキュメント内の separator は neutralize しない
#     ため、`echo "x;git push --force ..."` のような入力は分割されて誤検出
#     する（false positive: 実際には実行されない）。
#   - `env -i git push --force` のように env に flag が付く形式は先頭の
#     env-var stripping を通過しないので検査対象外になる（false negative）。
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

verdict=$(printf '%s' "$cmd" | awk '
    function ltrim(s) { sub(/^[[:space:]]+/, "", s); return s }

    # 先頭の環境変数代入 (FOO=bar / FOO=<quoted-with-spaces>) と env コマンドを剥がす。
    # 剥がした後で tok[1] == git 判定に入るので、
    # `GIT_SSH_COMMAND=... git push --force` や `env git push -f`
    # (値に quote 込み空白を含む形も含む) を検査対象にできる。
    # env に flag が付く形式 (env -i 等) は未対応（defense-in-depth の限界）。
    function strip_env(s,   prev, i, n, c, eq_len, in_q, q_char) {
        prev = ""
        while (s != prev) {
            prev = s
            if (match(s, /^env[[:space:]]+/)) {
                s = substr(s, RLENGTH + 1)
                continue
            }
            if (!match(s, /^[A-Za-z_][A-Za-z0-9_]*=/)) break
            eq_len = RLENGTH
            # 値部分を quote-aware に消費する: unquoted whitespace で終端。
            i = eq_len + 1
            n = length(s)
            in_q = 0
            q_char = ""
            while (i <= n) {
                c = substr(s, i, 1)
                if (in_q) {
                    if (c == q_char) { in_q = 0; q_char = "" }
                    i++
                    continue
                }
                if (c == "\047" || c == "\"") {
                    in_q = 1
                    q_char = c
                    i++
                    continue
                }
                if (c == " " || c == "\t") break
                i++
            }
            # 末尾に達している = 後続の command がないので strip 対象外として抜ける
            if (i > n) break
            # 値終端後の連続空白を飛ばす
            while (i <= n) {
                c = substr(s, i, 1)
                if (c == " " || c == "\t") { i++; continue }
                break
            }
            s = substr(s, i)
        }
        return s
    }

    # シングルクォート (\047) 内の separator を空白に置換する。Bash の
    # シングルクォートはあらゆる展開を無効化するため、内部を単なる文字列と
    # して扱ってよい。ダブルクォート・ヒアドキュメントは $(...) や `...`
    # command substitution を含みうるので neutralize しない。
    function neutralize_sq(s,   r, i, n, c, in_sq) {
        r = ""
        n = length(s)
        in_sq = 0
        for (i = 1; i <= n; i++) {
            c = substr(s, i, 1)
            if (c == "\047") { in_sq = 1 - in_sq; r = r c; continue }
            if (in_sq && (c == ";" || c == "&" || c == "|" || c == "\n")) {
                r = r " "
                continue
            }
            r = r c
        }
        return r
    }

    # git global option のうち、次 token を値として consume するもの。
    # 空白区切りで値を取る形式 (`--git-dir /path`) と attached 形式
    # (`--git-dir=/path`) の両方が git で受理されるため、両対応する。
    # attached 形式は先頭に `=` を含むので `-` 判定だけで自然に flag 扱いになる。
    function takes_separate_value(t) {
        return (t == "-c" || t == "-C" ||
                t == "--git-dir" || t == "--work-tree" ||
                t == "--namespace" || t == "--super-prefix" ||
                t == "--config-env")
    }

    # 先頭に現れうる shell control keyword / 記号。
    # subshell paren は RS で separator にしているので tok として現れないが、
    # `{`, `}`, `!`, `time`, if/then/else/... は tok として残りうる。
    function is_shell_control(t) {
        return (t == "!" || t == "time" ||
                t == "if" || t == "then" || t == "else" || t == "elif" || t == "fi" ||
                t == "do" || t == "done" || t == "while" || t == "until" ||
                t == "for" || t == "case" || t == "in" || t == "esac" ||
                t == "{" || t == "}")
    }

    function check_subcommand(line,   n, tok, i, j, t, pos, start, has_raw_force, has_with_lease, has_mirror, has_plus) {
        line = strip_env(ltrim(line))
        n = split(line, tok, /[[:space:]]+/)
        if (n == 0) return ""
        # 先頭の shell control token (if / then / do / { など) と shell
        # wrapper (command / exec / builtin) を読み飛ばす。
        # `if true; then git push -f ...; fi` や `command git push --force`
        # のようなケースも subcommand として検査対象にする。
        start = 1
        while (start <= n && (is_shell_control(tok[start]) ||
                              tok[start] == "command" || tok[start] == "exec" ||
                              tok[start] == "builtin")) start++
        if (start > n) return ""
        # git 本体は "git" or "<path>/git" 形式で受け付ける
        # (`/usr/bin/git push --force` などの絶対パス呼び出しに対応)。
        if (tok[start] != "git" && tok[start] !~ /(^|\/)git$/) return ""
        # git の直後: グローバル option (-c VAL / -C dir / --git-dir DIR / --xxx / -x)
        # を読み飛ばし、最初に現れる bare token を git subcommand として扱う。
        # `git checkout push --force` のような別 subcommand の引数に "push" が
        # 現れても push subcommand と誤認しない。
        i = start + 1
        pos = 0
        while (i <= n) {
            if (substr(tok[i], 1, 1) == "-") {
                # flag。next token を値として consume する global option は 2 token 進める。
                if (takes_separate_value(tok[i])) {
                    i += 2
                } else {
                    i += 1
                }
                continue
            }
            # 最初の bare token: これが subcommand。
            if (tok[i] == "push") pos = i
            break
        }
        if (pos == 0) return ""

        # push 以降の tokens を 1 つずつ判定する。
        # トークン単位の判定にすることで、`-ofoo` (push-option の値埋め込み) を
        # `-f を含む短縮結合形` と誤認する false positive を避ける。
        has_raw_force = 0
        has_with_lease = 0
        has_mirror = 0
        has_plus = 0
        for (j = pos + 1; j <= n; j++) {
            t = tok[j]
            gsub(/["\047]/, "", t)  # quote 除去

            # --force / --force=<val>
            if (t == "--force" || t ~ /^--force=/) { has_raw_force = 1; continue }
            # 短縮結合形: 値を取らない git push short flag [f v q n u d] のみで
            # 構成された cluster に f が 1 文字以上含まれる場合のみ raw force。
            # 値を取る -o (push-option) は cluster に含めない: `-ofoo` は
            # `--push-option=foo` の短縮であり `-f` の結合形ではない。
            if (t ~ /^-[fvqnud]*f[fvqnud]*$/) { has_raw_force = 1; continue }
            # --force-with-lease
            if (t == "--force-with-lease" || t ~ /^--force-with-lease=/) { has_with_lease = 1; continue }
            # --mirror
            if (t == "--mirror") { has_mirror = 1; continue }
            # +<refspec>
            if (substr(t, 1, 1) == "+" && length(t) > 1) { has_plus = 1; continue }
        }

        if (has_raw_force && has_with_lease) return "combined"
        if (has_raw_force) return "raw"
        if (has_mirror) return "mirror"
        if (has_plus) return "plus"
        return ""
    }

    # 全 record を単一 buffer に蓄積してから処理する。awk のデフォルト RS
    # では入力の改行が record 境界になり、シングルクォート内の改行判定が
    # できないため。
    { input = (NR == 1 ? $0 : input "\n" $0) }

    END {
        # Bash の行継続 (backslash + newline) を単一空白に正規化してから
        # subcommand 分割する。行継続はシェル上は 1 コマンド扱いなので、
        # 分割対象の改行から除外する必要がある。
        gsub(/\\\n/, " ", input)
        neutralized = neutralize_sq(input)
        # subshell paren `(cmd)` の内側も subcommand として検査対象にするため、
        # `(` / `)` も separator に含める。制御構文の keyword (if / then / do
        # など) は tok ベースで check_subcommand が読み飛ばすので RS には不要。
        n = split(neutralized, subs, /[;&|\n()]+/)
        for (i = 1; i <= n; i++) {
            v = check_subcommand(subs[i])
            if (v != "") { print v; exit }
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
