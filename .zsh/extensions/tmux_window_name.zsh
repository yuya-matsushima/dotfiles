# AI agent CLI 実行中の tmux window 名をリポジトリ名にする
#
# .tmux.conf は automatic-rename on のため、window 名はフォアグラウンドの
# プロセス名になる。Claude Code はバージョン付きバイナリで起動するので
# `2.1.221` のような名前になり、どのリポジトリで作業中か分からない。
#
# preexec で対象 CLI を検出して window 名をリポジトリ名へ変更し、
# precmd (= CLI 終了後) に元の状態へ戻す。
#
#   通常のリポジトリ : website-2026
#   git worktree 内  : website-2026:fix-login
#
# 対象コマンドは YMT_TMUX_AGENT_COMMANDS で上書きできる (~/.zshrc_local など)。

# リポジトリ名と worktree 名の区切り文字
typeset -g _ymt_tmux_window_sep="${_ymt_tmux_window_sep:-:}"

# rename 前の状態の退避先 (precmd で復元に使う)
typeset -g _ymt_tmux_window_prev_auto=""
typeset -g _ymt_tmux_window_prev_name=""

typeset -ga YMT_TMUX_AGENT_COMMANDS
(( ${#YMT_TMUX_AGENT_COMMANDS} )) || YMT_TMUX_AGENT_COMMANDS=(
  claude
  codex
  opencode
  agy
  antigravity
)

# window 名として使うリポジトリ名を出力する。
# worktree でも本体リポジトリ名を得るため --git-common-dir を使い、
# worktree ディレクトリ名が異なる場合のみ `repo:worktree` にする。
_ymt_tmux_window_repo_name() {
  local common="" top="" root repo wt

  if (( $+commands[git] )); then
    common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
    top="$(git rev-parse --show-toplevel 2>/dev/null)"
  fi

  if [[ -n $common ]]; then
    # /path/website-2026/.git -> /path/website-2026
    root="${common%/.git}"
    # bare リポジトリ (/path/website-2026.git) のフォールバック
    [[ $root == $common ]] && root="${common%.git}"
    repo="${root:t}"
  elif [[ -n $top ]]; then
    # --path-format 非対応の古い git 向けフォールバック
    repo="${top:t}"
  else
    # git 管理外 / git 未インストール
    print -r -- "${PWD:t}"
    return
  fi

  wt="${top:t}"
  if [[ -n $wt && $wt != $repo ]]; then
    print -r -- "${repo}${_ymt_tmux_window_sep}${wt}"
  else
    print -r -- "$repo"
  fi
}

# コマンドラインに含まれる各コマンドの先頭語を 1 行ずつ出力する。
# `cd foo && claude` や `claude | tee log` のような複合コマンドも拾えるよう、
# 区切り (; && || | & 等) ごとに先頭語を取り直す。
# 環境変数代入や command/env などの前置きは読み飛ばす。
_ymt_tmux_window_head_commands() {
  local -a words
  local w
  local head=1
  words=(${(z)1})

  for w in $words; do
    case $w in
      ';'|'&&'|'||'|'|'|'|&'|'&'|'('|')'|'{'|'}'|'!'|$'\n')
        head=1
        continue
        ;;
    esac
    (( head )) || continue

    w="${(Q)w}"
    [[ $w == *=* ]] && continue
    case $w in
      command|builtin|exec|env|nohup|time|sudo) continue ;;
    esac

    print -r -- "${w:t}"
    head=0
  done
}

_ymt_tmux_window_name_preexec() {
  [[ -n $TMUX && -n $TMUX_PANE ]] || return
  (( $+commands[tmux] )) || return

  # $3 は alias 展開済みのコマンドライン
  local -a cmds
  local cmd matched=0
  cmds=(${(f)"$(_ymt_tmux_window_head_commands "${3:-$1}")"})
  for cmd in $cmds; do
    if (( ${YMT_TMUX_AGENT_COMMANDS[(Ie)$cmd]} )); then
      matched=1
      break
    fi
  done
  (( matched )) || return

  local name state
  name="$(_ymt_tmux_window_repo_name)"
  [[ -n $name ]] || return

  state="$(tmux display-message -p -t "$TMUX_PANE" \
    "#{automatic-rename}"$'\t'"#{window_name}" 2>/dev/null)" || return
  [[ -n $state ]] || return

  if tmux rename-window -t "$TMUX_PANE" "$name" 2>/dev/null; then
    # rename-window はそのウィンドウの automatic-rename を off にする
    _ymt_tmux_window_prev_auto="${state%%$'\t'*}"
    _ymt_tmux_window_prev_name="${state#*$'\t'}"
  fi
}

_ymt_tmux_window_name_precmd() {
  # rename していないプロンプトでは何もしない (サブプロセスを起動しない)
  [[ -n $_ymt_tmux_window_prev_auto ]] || return

  local auto="$_ymt_tmux_window_prev_auto" name="$_ymt_tmux_window_prev_name"
  _ymt_tmux_window_prev_auto=""
  _ymt_tmux_window_prev_name=""

  [[ -n $TMUX && -n $TMUX_PANE ]] || return
  (( $+commands[tmux] )) || return

  if [[ $auto == 1 ]]; then
    tmux set-window-option -t "$TMUX_PANE" automatic-rename on 2>/dev/null
  else
    # 手動で rename 済みの window は元の名前へ戻す
    tmux rename-window -t "$TMUX_PANE" "$name" 2>/dev/null
  fi
}

if autoload -Uz add-zsh-hook 2>/dev/null; then
  add-zsh-hook preexec _ymt_tmux_window_name_preexec
  add-zsh-hook precmd _ymt_tmux_window_name_precmd
fi
