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
#
# 1 つの window の複数ペインで agent を動かしても壊れないよう、rename 前の状態は
# shell 変数ではなく window option に持たせ、実行中ペインの集合で参照カウントする。
#
#   @ymt_win_agents    : agent 実行中のペイン ID (スペース区切り)
#   @ymt_win_prev_auto : 最初の agent 起動前の automatic-rename
#   @ymt_win_prev_name : 最初の agent 起動前の window 名

# リポジトリ名と worktree 名の区切り文字
typeset -g _ymt_tmux_window_sep="${_ymt_tmux_window_sep:-:}"

# この shell が rename を実施済みかどうか (precmd の早期 return 用)
typeset -g _ymt_tmux_window_active=""

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
# 環境変数代入と、command/env などのラッパー (そのオプションを含む) は読み飛ばす。
_ymt_tmux_window_head_commands() {
  local -a words
  local w
  local head=1 wrapper=0 skip_next=0
  words=(${(z)1})

  for w in $words; do
    case $w in
      ';'|'&&'|'||'|'|'|'|&'|'&'|'('|')'|'{'|'}'|'!'|$'\n')
        head=1
        wrapper=0
        skip_next=0
        continue
        ;;
    esac
    (( head )) || continue

    w="${(Q)w}"

    # 直前のラッパーオプションが引数を取る場合 (env -u NAME / sudo -u USER)
    if (( skip_next )); then
      skip_next=0
      continue
    fi

    [[ $w == *=* ]] && continue

    # ラッパーに渡されたオプション (env -u FOO / sudo -E / time -p)
    if (( wrapper )) && [[ $w == -* ]]; then
      case $w in
        -u|--unset) skip_next=1 ;;
      esac
      continue
    fi

    case $w in
      command|builtin|exec|env|nohup|time|sudo)
        wrapper=1
        continue
        ;;
    esac

    print -r -- "${w:t}"
    head=0
    wrapper=0
  done
}

# @ymt_win_agents のうち、生存していて自ペイン以外のものを出力する。
# ペインが kill された場合に古い ID が残り続けないよう、都度 list-panes と突き合わせる。
_ymt_tmux_window_other_agents() {
  local -a recorded live
  local p
  recorded=(${=1})
  live=(${(f)"$(tmux list-panes -t "$TMUX_PANE" -F '#{pane_id}' 2>/dev/null)"})

  for p in $recorded; do
    [[ $p == $TMUX_PANE ]] && continue
    (( ${live[(Ie)$p]} )) && print -r -- "$p"
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

  local name state agents rest auto wname
  local -a others
  name="$(_ymt_tmux_window_repo_name)"
  [[ -n $name ]] || return

  state="$(tmux display-message -p -t "$TMUX_PANE" \
    "#{@ymt_win_agents}"$'\t'"#{automatic-rename}"$'\t'"#{window_name}" 2>/dev/null)" || return
  [[ -n $state ]] || return
  agents="${state%%$'\t'*}"
  rest="${state#*$'\t'}"
  auto="${rest%%$'\t'*}"
  wname="${rest#*$'\t'}"

  others=(${(f)"$(_ymt_tmux_window_other_agents "$agents")"})

  tmux rename-window -t "$TMUX_PANE" "$name" 2>/dev/null || return
  # rename-window はそのウィンドウの automatic-rename を off にする

  # この window で最初の agent のときだけ、rename 前の状態を退避する
  if (( ${#others} == 0 )); then
    tmux set-option -w -t "$TMUX_PANE" @ymt_win_prev_auto "$auto" 2>/dev/null
    tmux set-option -w -t "$TMUX_PANE" @ymt_win_prev_name "$wname" 2>/dev/null
  fi
  tmux set-option -w -t "$TMUX_PANE" @ymt_win_agents "${(j: :)others} $TMUX_PANE" 2>/dev/null
  _ymt_tmux_window_active=1
}

_ymt_tmux_window_name_precmd() {
  # rename していないプロンプトでは何もしない (サブプロセスを起動しない)
  [[ -n $_ymt_tmux_window_active ]] || return
  _ymt_tmux_window_active=""

  [[ -n $TMUX && -n $TMUX_PANE ]] || return
  (( $+commands[tmux] )) || return

  local state agents rest auto name
  local -a others
  state="$(tmux display-message -p -t "$TMUX_PANE" \
    "#{@ymt_win_agents}"$'\t'"#{@ymt_win_prev_auto}"$'\t'"#{@ymt_win_prev_name}" 2>/dev/null)" || return
  agents="${state%%$'\t'*}"
  rest="${state#*$'\t'}"
  auto="${rest%%$'\t'*}"
  name="${rest#*$'\t'}"

  others=(${(f)"$(_ymt_tmux_window_other_agents "$agents")"})

  # 他ペインでまだ agent が動いているので、自ペインを外すだけで名前は維持する
  if (( ${#others} )); then
    tmux set-option -w -t "$TMUX_PANE" @ymt_win_agents "${(j: :)others}" 2>/dev/null
    return
  fi

  tmux set-option -w -t "$TMUX_PANE" -u @ymt_win_agents 2>/dev/null
  tmux set-option -w -t "$TMUX_PANE" -u @ymt_win_prev_auto 2>/dev/null
  tmux set-option -w -t "$TMUX_PANE" -u @ymt_win_prev_name 2>/dev/null

  if [[ $auto == 1 ]]; then
    tmux set-window-option -t "$TMUX_PANE" automatic-rename on 2>/dev/null
  elif [[ -n $name ]]; then
    # 手動で rename 済みの window は元の名前へ戻す
    tmux rename-window -t "$TMUX_PANE" "$name" 2>/dev/null
  fi
}

if autoload -Uz add-zsh-hook 2>/dev/null; then
  add-zsh-hook preexec _ymt_tmux_window_name_preexec
  add-zsh-hook precmd _ymt_tmux_window_name_precmd
fi
