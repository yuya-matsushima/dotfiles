#!/bin/sh
# bin/skills.sh
#
# .config/skills/skills.json を SSOT として, user scope の skill
# (~/.claude/skills と ~/.agents/skills) を固定管理する。
#
# Usage:
#   sh bin/skills.sh            宣言との差分を install / 更新する
#   sh bin/skills.sh --check    差分を表示するだけ (差分があれば exit 1)
#   sh bin/skills.sh --prune    宣言に無い gh 管理 skill を削除する (確認あり)
#
# Options:
#   --check        install せず状態だけを表示する
#   --force        宣言済み skill を状態に関係なく再 install する
#   --prune        宣言に無い gh 管理 skill を削除する
#   -y, --yes      --prune の確認をスキップする
#   --file PATH    manifest のパス (既定: $HOME/.config/skills/skills.json)
#   -h, --help     print help
#
# manifest (JSON):
#   {
#     "repos": {
#       "<owner/repo>": {
#         "version": "<tag or SHA>",       // 任意 (配下の skill に適用)
#         "skills": [
#           "<skill>",
#           { "name": "<skill>", "version": "<tag or SHA>" }
#         ]
#       }
#     }
#   }
#
#   version を省略すると最新 release tag に追従する。skill 側の version は
#   repo 側より優先される。
#
# 依存: gh (skill extension), jq
set -eu

usage() {
    cat <<'EOF'
Usage:
  sh bin/skills.sh [--check] [--prune] [--yes] [--file PATH]

Options:
  --check        install せず状態だけを表示する (差分があれば exit 1)
  --force        宣言済み skill を状態に関係なく再 install する
  --prune        宣言に無い gh 管理 skill を削除する (確認あり)
  -y, --yes      --prune の確認をスキップする
  --file PATH    manifest のパス (既定: $HOME/.config/skills/skills.json)
  -h, --help     print help
EOF
}

MODE=install
FORCE=0
PRUNE=0
ASSUME_YES=0
FILE=${SKILLS_FILE:-"$HOME/.config/skills/skills.json"}

while [ $# -gt 0 ]; do
    case "$1" in
    --check)
        MODE=check
        ;;
    --force)
        FORCE=1
        ;;
    --prune)
        PRUNE=1
        ;;
    -y | --yes)
        ASSUME_YES=1
        ;;
    --file)
        if [ $# -lt 2 ]; then
            echo "エラー: --file にはパスを指定してください" >&2
            exit 64
        fi
        FILE=$2
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "エラー: 未知の引数です: $1" >&2
        usage >&2
        exit 64
        ;;
    esac
    shift
done

if [ "$MODE" = check ] && [ "$PRUNE" -eq 1 ]; then
    echo "エラー: --check と --prune は同時に指定できません" >&2
    exit 64
fi
if [ "$MODE" = check ] && [ "$FORCE" -eq 1 ]; then
    echo "エラー: --check と --force は同時に指定できません" >&2
    exit 64
fi

for cmd in gh jq awk sort sed mktemp; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "エラー: $cmd コマンドが見つかりません" >&2
        exit 127
    fi
done

if [ ! -f "$FILE" ]; then
    echo "エラー: manifest が見つかりません: $FILE" >&2
    echo "  dotfiles リポジトリで 'make link' を実行するか, --file でパスを指定してください。" >&2
    exit 66
fi

CLAUDE_ROOT="$HOME/.claude/skills"
AGENTS_ROOT="$HOME/.agents/skills"

WORK_DIR=$(mktemp -d) || {
    echo "エラー: 一時ディレクトリを作成できませんでした" >&2
    exit 1
}
trap 'rm -rf "$WORK_DIR"' EXIT INT TERM

ENTRIES="$WORK_DIR/entries"
DECLARED="$WORK_DIR/declared"
CACHE="$WORK_DIR/remote-cache"
PRUNE_LIST="$WORK_DIR/prune"
: >"$ENTRIES"
: >"$DECLARED"
: >"$CACHE"
: >"$PRUNE_LIST"

# manifest の schema を検証する。違反があれば 1 行のエラーメッセージを返す。
# shellcheck disable=SC2016 # jq の \(...) は shell 展開させない
JQ_VALIDATE='
def error_message:
  if type != "object" then
    "top-level が object ではありません"
  elif (.repos | type) != "object" then
    "repos が object ではありません"
  else
    [ .repos | to_entries[] |
      .key as $repo | .value as $group |
      if ($repo | test("^[^/]+/[^/]+$") | not) then
        "repos のキーは <owner>/<repo> 形式必須: \($repo)"
      elif ($group | type) != "object" then
        "repos.\($repo) が object ではありません"
      elif ($group.version != null and ($group.version | type) != "string") then
        "repos.\($repo).version は string 必須"
      elif ($group.skills | type) != "array" then
        "repos.\($repo).skills は array 必須"
      else
        [ $group.skills | to_entries[] |
          .key as $i | .value as $s |
          if ($s | type) == "string" then
            if ($s | length) == 0 then
              "repos.\($repo).skills[\($i)] が空です"
            else empty end
          elif ($s | type) == "object" then
            if ($s.name | type) != "string" then
              "repos.\($repo).skills[\($i)].name は string 必須"
            elif ($s.name | length) == 0 then
              "repos.\($repo).skills[\($i)].name が空です"
            elif ($s.version != null and ($s.version | type) != "string") then
              "repos.\($repo).skills[\($i)].version は string 必須"
            else empty end
          else
            "repos.\($repo).skills[\($i)] は string または object 必須"
          end
        ] | first // empty
      end
    ] | first // empty
  end;
error_message
'

validate_manifest() {
    _vm_err=''
    _vm_rc=0
    _vm_err=$(jq -r "$JQ_VALIDATE" "$FILE" 2>/dev/null) || _vm_rc=$?
    if [ "$_vm_rc" -ne 0 ]; then
        echo "エラー: manifest を JSON として読めません: $FILE" >&2
        exit 65
    fi
    if [ -n "$_vm_err" ]; then
        echo "エラー: manifest が不正です: $_vm_err" >&2
        exit 65
    fi
}

# manifest を 1 skill = 1 行の "repo|repo_version|skill|skill_version" に正規化する。
load_entries() {
    jq -r '
        .repos | to_entries[] | .key as $repo | .value as $group |
        $group.skills[] |
        (if type == "string" then {name: ., version: null} else . end) as $s |
        [$repo, ($group.version // ""), $s.name, ($s.version // "")] | join("|")
    ' "$FILE" >"$ENTRIES"
}

validate_manifest
load_entries

if [ ! -s "$ENTRIES" ]; then
    echo "エラー: manifest に skill が 1 つも書かれていません: $FILE" >&2
    exit 65
fi

# skill の leaf 名 (install 先ディレクトリ名) を集める。
cut -d '|' -f3 "$ENTRIES" | sed 's#.*/##' | sort -u >"$DECLARED"

_dups=$(cut -d '|' -f3 "$ENTRIES" | sed 's#.*/##' | sort | uniq -d)
if [ -n "$_dups" ]; then
    echo "エラー: skill 名が重複しています (install 先が同じになります):" >&2
    printf '%s\n' "$_dups" | sed 's/^/  - /' >&2
    exit 65
fi

# 同一 repo の最新 release tag を 1 回だけ解決する。
# releases/latest が無い repo では tags の最大値を fallback に使う。
latest_tag() {
    _lt_repo=$1
    _lt_tag=''
    _lt_rc=0

    # gh api は 404 の JSON body を stdout に出すことがあるため, パイプで
    # 終了ステータスを隠さず, 成功したときだけ出力を採用する。
    _lt_out=$(gh api "repos/$_lt_repo/releases/latest" --jq '.tag_name' 2>/dev/null </dev/null) || _lt_rc=$?
    if [ "$_lt_rc" -eq 0 ] && [ -n "$_lt_out" ]; then
        printf '%s' "$_lt_out"
        return
    fi

    _lt_rc=0
    _lt_out=$(gh api --paginate "repos/$_lt_repo/tags" --jq '.[].name' 2>/dev/null </dev/null) || _lt_rc=$?
    if [ "$_lt_rc" -eq 0 ] && [ -n "$_lt_out" ]; then
        _lt_tag=$(printf '%s\n' "$_lt_out" | sort -V | tail -1)
    fi
    printf '%s' "$_lt_tag"
}

cut -d '|' -f1 "$ENTRIES" | sort -u >"$WORK_DIR/repos"
while IFS= read -r _lt_repo; do
    [ -n "$_lt_repo" ] || continue
    _lt_tag=$(latest_tag "$_lt_repo")
    printf '%s|%s\n' "$_lt_repo" "$_lt_tag" >>"$CACHE"
done <"$WORK_DIR/repos"

lookup_tag() {
    awk -F '|' -v r="$1" '$1 == r { print $2; exit }' "$CACHE"
}

normalize_repo() {
    _nr_repo=$1
    _nr_repo=${_nr_repo#https://github.com/}
    _nr_repo=${_nr_repo#http://github.com/}
    _nr_repo=${_nr_repo#git@github.com:}
    _nr_repo=${_nr_repo%.git}
    _nr_repo=${_nr_repo%/}
    printf '%s' "$_nr_repo" | tr '[:upper:]' '[:lower:]'
}

# SKILL.md frontmatter の metadata ブロックから key の値を読む。
read_meta() {
    _rm_file=$1
    _rm_key=$2
    [ -f "$_rm_file" ] || return 0
    awk -v key="$_rm_key" '
        NR == 1 && $0 != "---" { exit }
        NR == 1 { next }
        $0 == "---" { exit }
        /^metadata:[[:space:]]*$/ { in_meta = 1; next }
        /^[^[:space:]]/ { in_meta = 0 }
        in_meta && match($0, "^[[:space:]]+" key ":[[:space:]]*") {
            print substr($0, RSTART + RLENGTH)
            exit
        }
    ' "$_rm_file" 2>/dev/null |
        tr -d '\r' |
        sed -e 's/^["'"'"']//' -e 's/["'"'"']$//' -e 's/[[:space:]]*$//'
}

# インストール済み SKILL.md の github-ref を比較可能な形で読む。
# refs/tags/<tag> -> <tag>, refs/heads/<branch> -> <branch>, それ以外の
# commit SHA 等はそのまま返す。読めない場合は unknown。
installed_ref() {
    _iv_file=$1
    _iv_repo=$2
    [ -f "$_iv_file" ] || {
        printf 'missing'
        return
    }

    _iv_repo_raw=$(read_meta "$_iv_file" github-repo)
    if [ -n "$_iv_repo_raw" ]; then
        _iv_actual=$(normalize_repo "$_iv_repo_raw")
        _iv_expected=$(normalize_repo "$_iv_repo")
        if [ "$_iv_actual" != "$_iv_expected" ]; then
            # 同名 skill を別の配布元から入れている場合はバージョン比較しない。
            printf 'unknown'
            return
        fi
    fi

    _iv_ref=$(read_meta "$_iv_file" github-ref)
    case "$_iv_ref" in
    refs/tags/?*) printf '%s' "${_iv_ref#refs/tags/}" ;;
    refs/heads/?*) printf '%s' "${_iv_ref#refs/heads/}" ;;
    ?*) printf '%s' "$_iv_ref" ;;
    *) printf 'unknown' ;;
    esac
}

# 1 skill の状態を "state|installed_ref" で返す。
# state: up-to-date / outdated / missing / partial / mismatch / unverified / head
# target (宣言された tag / SHA) が空 (release が無い / 解決できない) のときは
# HEAD 追従 (head) として成功扱いにする。
skill_status() {
    _ss_leaf=$1
    _ss_repo=$2
    _ss_target=$3
    _ss_claude_md="$CLAUDE_ROOT/$_ss_leaf/SKILL.md"
    _ss_agents_md="$AGENTS_ROOT/$_ss_leaf/SKILL.md"
    _ss_has_claude=0
    _ss_has_agents=0
    [ -f "$_ss_claude_md" ] && _ss_has_claude=1
    [ -f "$_ss_agents_md" ] && _ss_has_agents=1

    if [ "$_ss_has_claude" -eq 0 ] && [ "$_ss_has_agents" -eq 0 ]; then
        printf 'missing|-'
        return
    fi

    _ss_claude_ref='-'
    _ss_agents_ref='-'
    [ "$_ss_has_claude" -eq 1 ] && _ss_claude_ref=$(installed_ref "$_ss_claude_md" "$_ss_repo")
    [ "$_ss_has_agents" -eq 1 ] && _ss_agents_ref=$(installed_ref "$_ss_agents_md" "$_ss_repo")

    if [ "$_ss_has_claude" -eq 1 ] && [ "$_ss_has_agents" -eq 1 ] &&
        [ "$_ss_claude_ref" != "$_ss_agents_ref" ]; then
        printf 'mismatch|%s/%s' "$_ss_claude_ref" "$_ss_agents_ref"
        return
    fi

    if [ "$_ss_has_claude" -eq 0 ] || [ "$_ss_has_agents" -eq 0 ]; then
        _ss_v=$_ss_claude_ref
        [ "$_ss_has_claude" -eq 0 ] && _ss_v=$_ss_agents_ref
        printf 'partial|%s' "$_ss_v"
        return
    fi

    # release が無い (または解決できない) repo は HEAD 追従とみなし, 比較しない。
    if [ -z "$_ss_target" ]; then
        printf 'head|%s' "$_ss_claude_ref"
        return
    fi

    if [ "$_ss_claude_ref" = unknown ] || [ "$_ss_claude_ref" = '-' ]; then
        printf 'unverified|-'
        return
    fi

    if [ "$_ss_claude_ref" = "$_ss_target" ]; then
        printf 'up-to-date|%s' "$_ss_claude_ref"
    else
        printf 'outdated|%s' "$_ss_claude_ref"
    fi
}

restore_exec() {
    [ -d "$1" ] || return 0
    find "$1" -type f -name '*.sh' -exec chmod u+x {} + 2>/dev/null || true
}

install_skill() {
    _is_repo=$1
    _is_skill=$2
    _is_target=$3
    _is_leaf=$4
    # gh skill install --force は既存ディレクトリへ上書きマージするため,
    # 上流で削除されたサブディレクトリが残る。一度一時ディレクトリへ install し,
    # 成功後に skill ディレクトリごと置換して残骸を消す。
    _is_tmp_claude="$WORK_DIR/install-claude-$_is_leaf"
    _is_tmp_agents="$WORK_DIR/install-agents-$_is_leaf"
    rm -rf "$_is_tmp_claude" "$_is_tmp_agents"
    mkdir -p "$_is_tmp_claude" "$_is_tmp_agents"

    if [ -n "$_is_target" ]; then
        gh skill install "$_is_repo" "$_is_skill" --dir "$_is_tmp_claude" --agent claude-code --force \
            --pin "$_is_target" </dev/null
        gh skill install "$_is_repo" "$_is_skill" --dir "$_is_tmp_agents" --agent github-copilot --force \
            --pin "$_is_target" </dev/null
    else
        gh skill install "$_is_repo" "$_is_skill" --dir "$_is_tmp_claude" --agent claude-code --force </dev/null
        gh skill install "$_is_repo" "$_is_skill" --dir "$_is_tmp_agents" --agent github-copilot --force </dev/null
    fi

    mkdir -p "$CLAUDE_ROOT" "$AGENTS_ROOT"
    rm -rf "${CLAUDE_ROOT:?}/${_is_leaf:?}" "${AGENTS_ROOT:?}/${_is_leaf:?}"
    mv "$_is_tmp_claude/$_is_leaf" "$CLAUDE_ROOT/$_is_leaf"
    mv "$_is_tmp_agents/$_is_leaf" "$AGENTS_ROOT/$_is_leaf"

    restore_exec "$CLAUDE_ROOT/$_is_leaf"
    restore_exec "$AGENTS_ROOT/$_is_leaf"
}

# 宣言に無い gh 管理 skill を "leaf|repo" 形式で PRUNE_LIST に集める。
# symlink (例: superwhisper -> /opt/...) と github-repo を持たない skill は
# 管理外として対象にしない。
collect_undeclared() {
    _cu_root=''
    _cu_dir=''
    _cu_leaf=''
    : >"$PRUNE_LIST"

    for _cu_root in "$CLAUDE_ROOT" "$AGENTS_ROOT"; do
        [ -d "$_cu_root" ] || continue
        for _cu_dir in "$_cu_root"/*; do
            [ -d "$_cu_dir" ] || continue
            [ -L "$_cu_dir" ] && continue
            [ -f "$_cu_dir/SKILL.md" ] || continue
            _cu_leaf=${_cu_dir##*/}
            if grep -Fxq "$_cu_leaf" "$DECLARED"; then
                continue
            fi
            _cu_repo=$(normalize_repo "$(read_meta "$_cu_dir/SKILL.md" github-repo)")
            [ -n "$_cu_repo" ] || continue
            printf '%s|%s\n' "$_cu_leaf" "$_cu_repo" >>"$PRUNE_LIST"
        done
    done

    sort -u -o "$PRUNE_LIST" "$PRUNE_LIST"
}

prune_undeclared() {
    _pu_root=''
    _pu_line=''
    _pu_leaf=''
    _pu_repo=''

    collect_undeclared
    if [ ! -s "$PRUNE_LIST" ]; then
        echo "prune: 削除対象はありません"
        return 0
    fi

    echo "以下の宣言外 skill を削除します:"
    while IFS= read -r _pu_line; do
        _pu_leaf=${_pu_line%%|*}
        _pu_repo=${_pu_line#*|}
        printf '  - %s (%s)\n' "$_pu_leaf" "$_pu_repo"
    done <"$PRUNE_LIST"

    if [ "$ASSUME_YES" -ne 1 ]; then
        printf '削除しますか? [y/N]: '
        _pu_answer=''
        IFS= read -r _pu_answer || _pu_answer=''
        case "$_pu_answer" in
        y | Y | yes | YES) ;;
        *)
            echo "Cancelled."
            return 0
            ;;
        esac
    fi

    while IFS= read -r _pu_line; do
        _pu_leaf=${_pu_line%%|*}
        for _pu_root in "$CLAUDE_ROOT" "$AGENTS_ROOT"; do
            [ -e "$_pu_root/$_pu_leaf" ] || continue
            rm -rf "${_pu_root:?}/${_pu_leaf:?}"
            printf 'removed: %s/%s\n' "${_pu_root#"$HOME"/}" "$_pu_leaf"
        done
    done <"$PRUNE_LIST"
}

if [ "$MODE" = check ]; then
    printf '%-24s %-32s %-18s %-18s %s\n' "SKILL" "REPO" "DECLARED" "INSTALLED" "STATUS"
    printf '%-24s %-32s %-18s %-18s %s\n' "------------------------" "--------------------------------" "------------------" "------------------" "------"
fi

_drift=0
_changed=0

while IFS='|' read -r _repo _repo_version _skill _skill_version <&3; do
    _leaf=${_skill##*/}
    # skill 行の version が repo 行の version より優先される。
    _target=$_skill_version
    [ -n "$_target" ] || _target=$_repo_version
    if [ -z "$_target" ]; then
        _target=$(lookup_tag "$_repo")
    fi

    _status_pair=$(skill_status "$_leaf" "$_repo" "$_target")
    _state=${_status_pair%%|*}
    _installed=${_status_pair#*|}

    # --force は状態に関係なく全 skill を再 install する。
    if [ "$FORCE" -eq 1 ]; then
        _state=force
    fi

    if [ "$MODE" = check ]; then
        if [ -n "$_skill_version" ]; then
            _declared_disp=$_skill_version
        elif [ -n "$_repo_version" ]; then
            _declared_disp=$_repo_version
        elif [ -n "$_target" ]; then
            _declared_disp="latest($_target)"
        else
            _declared_disp="latest"
        fi
        printf '%-24s %-32s %-18s %-18s %s\n' \
            "$_leaf" "$_repo" "$_declared_disp" "$_installed" "$_state"
        case "$_state" in
        up-to-date | head) ;;
        *) _drift=1 ;;
        esac
        continue
    fi

    case "$_state" in
    up-to-date | head)
        printf 'ok: %s (%s)\n' "$_skill" "$_installed"
        ;;
    *)
        printf 'install: %s %s (%s)\n' "$_repo" "$_skill" "${_target:-HEAD}"
        install_skill "$_repo" "$_skill" "$_target" "$_leaf"
        _changed=$((_changed + 1))
        ;;
    esac
done 3<"$ENTRIES"

if [ "$MODE" = check ]; then
    # 宣言に無い gh 管理 skill も差分として表示する (削除は --prune のみ)。
    collect_undeclared
    if [ -s "$PRUNE_LIST" ]; then
        while IFS= read -r _line; do
            _leaf=${_line%%|*}
            _repo=${_line#*|}
            printf '%-24s %-32s %-18s %-18s %s\n' "$_leaf" "$_repo" "-" "-" "undeclared"
        done <"$PRUNE_LIST"
        _drift=1
    fi

    if [ "$_drift" -ne 0 ]; then
        exit 1
    fi
    exit 0
fi

if [ "$PRUNE" -eq 1 ]; then
    prune_undeclared
fi

if [ "$_changed" -eq 0 ]; then
    echo "Done: すべて宣言どおりです。"
else
    echo "Done: ${_changed} skill(s) installed."
fi
