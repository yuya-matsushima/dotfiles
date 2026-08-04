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
# 引数にディレクトリを渡すと、そこへ順に移動した状態で解決する
# (`cd foo && claude` のように preexec 時点ではまだ移動していない場合に使う)。
# 途中で移動に失敗したら、誤った移動先を使わず現在の PWD basis に戻す。
_ymt_tmux_window_repo_name() {
  local common="" top="" root repo wt d

  if (( $# )); then
    (
      for d in "$@"; do
        builtin cd -q -- "$d" 2>/dev/null || exit 1
      done
      _ymt_tmux_window_repo_name
    ) && return
    # cd に失敗した場合は引数なしで解決し直す
    _ymt_tmux_window_repo_name
    return
  fi

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

# コマンドラインから、対象コマンド判定に使う候補語を 1 行ずつ出力する。
# `cd foo && claude` や `claude | tee log` のような複合コマンドも拾えるよう、
# 区切り (; && || | & 等) ごとに先頭語を取り直す。環境変数代入は読み飛ばす。
#
# command/env/sudo などのラッパー配下では、その残りの語をすべて候補として出す。
# `env -P /path claude` / `sudo --user root claude` のように引数を取るオプションは
# ラッパーごとに異なり、網羅的な表を持つのは現実的でないため。
# 候補が増えても、YMT_TMUX_AGENT_COMMANDS に一致しない語は無視されるだけで済む。
_ymt_tmux_window_command_candidates() {
  local -a words
  local w
  local head=1 wrapper=0
  words=(${(z)1})

  for w in $words; do
    case $w in
      ';'|'&&'|'||'|'|'|'|&'|'&'|'('|')'|'{'|'}'|'!'|$'\n')
        head=1
        wrapper=0
        continue
        ;;
    esac
    (( head )) || continue

    w="${(Q)w}"
    [[ $w == *=* ]] && continue

    # ラッパー配下では残りの語をすべて候補にする (オプションとその引数を含む)
    if (( wrapper )); then
      print -r -- "${w:t}"
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
  done
}

# 対象コマンドより前にある `cd` の移動先を、出現順に 1 行ずつ出力する。
# `cd repo-a && cd ../repo-b && claude` のように複数あっても順に反映できるようにする。
_ymt_tmux_window_cd_targets() {
  local -a words
  local w next
  local head=1 i=1 n

  words=(${(z)1})
  n=${#words}

  while (( i <= n )); do
    w="${words[i]}"
    case $w in
      ';'|'&&'|'||'|'|'|'|&'|'&'|'('|')'|'{'|'}'|'!'|$'\n')
        head=1
        (( i++ ))
        continue
        ;;
    esac
    if (( ! head )); then
      (( i++ ))
      continue
    fi

    w="${(Q)w}"
    if [[ $w == cd ]]; then
      next="${(Q)words[i+1]}"
      case $next in
        ''|-*|';'|'&&'|'||'|'|'|'&') ;;
        *) print -r -- "$next" ;;
      esac
      head=0
      (( i += 2 ))
      continue
    fi

    # 対象コマンドに到達したらそこで打ち切る (agent より後ろの cd は反映しない)
    if (( ${YMT_TMUX_AGENT_COMMANDS[(Ie)${w:t}]} )); then
      return
    fi

    head=0
    (( i++ ))
  done
}

# ジョブ指定 (%1 / %+ / %string 等) から、そのジョブのコマンド文字列を出力する。
# Ctrl-Z で停止した agent を fg で再開したときに、再び対象コマンドとして
# 判定できるようにするために使う。
_ymt_tmux_window_job_text() {
  local spec="${1:-%+}" j mark

  (( ${+jobtexts} )) || return
  (( ${#jobtexts} )) || return

  case $spec in
    %%|%+|'') spec='+' ;;
    %-) spec='-' ;;
    %<->)
      print -r -- "${jobtexts[${spec#%}]}"
      return
      ;;
    %*)
      # %string : コマンドが string で始まるジョブ
      for j in ${(k)jobtexts}; do
        if [[ ${jobtexts[$j]} == ${spec#%}* ]]; then
          print -r -- "${jobtexts[$j]}"
          return
        fi
      done
      return
      ;;
    *) spec='+' ;;
  esac

  for j in ${(k)jobstates}; do
    mark="${${(s.:.)jobstates[$j]}[2]}"
    if [[ $mark == $spec ]]; then
      print -r -- "${jobtexts[$j]}"
      return
    fi
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
  local -a cmds lw
  local cmd matched=0 line jobspec jtext
  line="${3:-$1}"

  # `fg` / `fg %2` / `%2` はジョブ再開なので、停止中ジョブのコマンドで判定し直す
  lw=(${(z)line})
  if [[ ${lw[1]} == fg || ${lw[1]} == %* ]]; then
    jobspec="${lw[1]}"
    [[ $jobspec == fg ]] && jobspec="${lw[2]:-%+}"
    jtext="$(_ymt_tmux_window_job_text "$jobspec")"
    [[ -n $jtext ]] && line="$jtext"
  fi

  cmds=(${(f)"$(_ymt_tmux_window_command_candidates "$line")"})
  for cmd in $cmds; do
    if (( ${YMT_TMUX_AGENT_COMMANDS[(Ie)$cmd]} )); then
      matched=1
      break
    fi
  done
  (( matched )) || return

  # `cd foo && claude` は preexec 時点でまだ移動していないため、移動先で解決する
  local d
  local -a cddirs cdexp
  setopt localoptions nonomatch nonullglob
  for d in ${(f)"$(_ymt_tmux_window_cd_targets "$line")"}; do
    # ~ 展開のため、配列コンテキストで GLOB_SUBST をかける
    cdexp=(${~d})
    cddirs+="${cdexp[1]:-$d}"
  done

  local name state
  local -a others f
  name="$(_ymt_tmux_window_repo_name "${cddirs[@]}")"
  [[ -n $name ]] || return

  state="$(tmux display-message -p -t "$TMUX_PANE" \
    "#{@ymt_win_agents}"$'\t'"#{@ymt_win_prev_auto}"$'\t'"#{automatic-rename}"$'\t'"#{window_name}" \
    2>/dev/null)" || return
  [[ -n $state ]] || return
  f=("${(@ps:\t:)state}")

  others=(${(f)"$(_ymt_tmux_window_other_agents "$f[1]")"})

  tmux rename-window -t "$TMUX_PANE" "$name" 2>/dev/null || return
  # rename-window はそのウィンドウの automatic-rename を off にする

  # 退避値が未設定のときだけ保存する。他ペインが kill されて @ymt_win_agents が
  # stale になっていても (others が空でも)、既存の退避値は上書きしない。
  if [[ -z $f[2] ]]; then
    tmux set-option -w -t "$TMUX_PANE" @ymt_win_prev_auto "$f[3]" 2>/dev/null
    tmux set-option -w -t "$TMUX_PANE" @ymt_win_prev_name "$f[4]" 2>/dev/null
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
