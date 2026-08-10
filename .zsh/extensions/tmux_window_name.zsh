# AI agent CLI 実行中の tmux window 名をリポジトリ名にする
#
# .tmux.conf は automatic-rename on のため、window 名はフォアグラウンドの
# プロセス名になる。Claude Code はバージョン付きバイナリで起動するので
# `2.1.221` のような名前になり、どのリポジトリで作業中か分からない。
#
# preexec で対象 CLI を検出して window 名をリポジトリ名へ変更し、
# precmd (= CLI 終了後) に元の状態へ戻す。
#
#   通常のリポジトリ     : website-2026
#   git worktree 内      : website-2026:fix-login
#   複数ペインで異なる repo : website-2026|api
#   同名 window が既存     : website-2026-2
#
# 対象コマンドは YMT_TMUX_AGENT_COMMANDS で上書きできる (~/.zshrc_local など)。
#
# 1 つの window の複数ペインで agent を動かしても壊れないよう、rename 前の状態は
# shell 変数ではなく window option に持たせ、実行中ペインの集合で参照カウントする。
#
#   @ymt_win_agents     : agent 実行中のペイン ID (スペース区切り)
#   @ymt_win_pane_repos : ペインごとのリポジトリ名 (pane_id=repo_name 改行区切り)
#   @ymt_win_prev_auto  : 最初の agent 起動前の automatic-rename
#   @ymt_win_prev_name  : 最初の agent 起動前の window 名
#
# あわせて、CLI 終了時に ~/.tmux/agent-status.sh でステータスバーのバー
# (pane option @agent_status) をクリアする。Claude Code は SessionEnd hook で
# 自前でクリアするが、Codex / OpenCode には終了イベントがなく、この precmd が
# ないとバーが残り続ける (bin/agent_hooks.sh 参照)。

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
# `-` はそのまま渡し、移動を再現する過程の OLDPWD で解決する
# (`cd dir && cd - && claude` を正しく再現するため)。
# ディレクトリとして開けない語は zoxide のクエリ結果で解決を試みる
# (このリポジトリの .zshrc は `zoxide init zsh --cmd cd` で cd を置き換えるため)。
# 各引数は `<cond><TAB><移動先...>` 形式で、cond は直前の区切りを表す:
#   u = 無条件 (`;` / 先頭) / a = `&&` (直前成功時のみ) / o = `||` (直前失敗時のみ)
# 移動先が TAB 区切りで複数ある場合 (`cd foo bar`) は zoxide の複数語クエリとして解決する。
# 最終的に移動に失敗していたら、誤った移動先を使わず現在の PWD basis に戻す。
_ymt_tmux_window_repo_name() {
  local common="" top="" root repo wt d z

  if (( $# )); then
    (
      local last_ok=1 cond rest
      for d in "$@"; do
        cond="${d%%$'\t'*}"
        rest="${d#*$'\t'}"
        case $cond in
          a) (( last_ok )) || continue ;;
          o) (( last_ok )) && continue ;;
        esac

        last_ok=0
        if [[ $rest == - ]]; then
          builtin cd -q - >/dev/null 2>&1 && last_ok=1
        elif [[ $rest == *$'\t'* ]]; then
          # 複数語は zoxide のクエリとしてのみ意味を持つ
          if (( $+commands[zoxide] )); then
            z="$(zoxide query -- "${(@ps:\t:)rest}" 2>/dev/null)" &&
              builtin cd -q -- "$z" 2>/dev/null && last_ok=1
          fi
        elif builtin cd -q -- "$rest" 2>/dev/null; then
          last_ok=1
        elif (( $+commands[zoxide] )); then
          # zoxide のキーワード指定 (`cd project`) を query で解決する。
          # query は読み取り専用なので、preexec での実行が履歴を汚さない。
          z="$(zoxide query -- "$rest" 2>/dev/null)" &&
            builtin cd -q -- "$z" 2>/dev/null && last_ok=1
        fi
      done
      (( last_ok )) || exit 1
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
    root="$top"
  else
    # git 管理外 / git 未インストール
    print -r -- "${PWD:t}"
    return
  fi

  # GitHub リポジトリの場合は remote URL から canonical なリポジトリ名を取得
  if [[ -n $root ]]; then
    local remote_url
    remote_url="$(git -C "$root" remote get-url origin 2>/dev/null)"
    if [[ $remote_url == *github.com* ]]; then
      remote_url="${remote_url##*/}"
      remote_url="${remote_url%.git}"
      repo="$remote_url"
    fi
  fi

  wt="${top:t}"
  if [[ -n $wt && $wt != $repo ]]; then
    print -r -- "${repo}${_ymt_tmux_window_sep}${wt}"
  else
    print -r -- "$repo"
  fi
}

# コマンドラインを 1 回走査し、出現順に `cmd<TAB><コマンド名>` / `cd<TAB><移動先>`
# を _ymt_tmux_window_parsed に格納する。呼び出し側はこれを順に読み、
# agent に到達した時点で cd の収集を止める。
# preexec は全コマンドで走るため、結果は stdout ではなくグローバル配列に返す
# (command substitution による subshell fork を毎コマンド払わないため)。
#
# `cd foo && claude` や `claude | tee log` のような複合コマンドも拾えるよう、
# 区切り (; && || | & 等) ごとに先頭語を取り直す。環境変数代入は読み飛ばす。
#
# command/env/sudo などのラッパー配下では、そのラッパーが引数を取るオプションを
# 消費したうえで、実際に実行されるコマンドだけを cmd として出す
# (`sudo echo claude` を agent 起動と誤判定しないため)。
#
# 1 つの cd が複数引数を取る場合 (`cd foo bar` = zoxide の複数語クエリ) は
# TAB 区切りで 1 要素にまとめる。各移動先の語は展開可否を表す 1 文字
# (E = 展開する / L = リテラル) を接頭辞に持つ。
typeset -ga _ymt_tmux_window_parsed

# ラッパーごとの「次の語を引数として取る」オプション。
# 表にないオプションが引数を取る場合は agent を検出できない (誤検出はしない) 側に倒れる。
typeset -gA _ymt_tmux_window_wrapper_optargs
_ymt_tmux_window_wrapper_optargs=(
  env   '-u --unset -C --chdir -S --split-string -P'
  sudo  '-u --user -g --group -C --close-from -D --chdir -h --host -p --prompt -r --role -t --type -T --command-timeout -R --chroot -U --other-user'
  time  '-o --output -f --format'
  exec  '-a'
)

_ymt_tmux_window_parse() {
  local -a words cdargs optargs
  local w next raw wname flag
  local head=1 wrapper=0 i=1 n j sep cond=u prev_seg=none

  _ymt_tmux_window_parsed=()
  words=(${(z)1})
  n=${#words}

  while (( i <= n )); do
    w="${words[i]}"
    # 区切りの種類を覚えておき、cd の実行条件 (短絡) の再現に使う
    case $w in
      '&&')
        cond=a
        head=1
        wrapper=0
        (( i++ ))
        continue
        ;;
      '||')
        cond=o
        head=1
        wrapper=0
        (( i++ ))
        continue
        ;;
      ';'|'|'|'|&'|'&'|'('|')'|'{'|'}'|'!'|$'\n')
        cond=u
        head=1
        wrapper=0
        (( i++ ))
        continue
        ;;
    esac
    if (( ! head )); then
      (( i++ ))
      continue
    fi

    raw="$w"
    w="${(Q)w}"
    if [[ $w == *=* ]]; then
      (( i++ ))
      continue
    fi

    # ラッパー配下ではオプション (と引数を取るものはその引数) を読み飛ばし、
    # 最初の非オプション語を実行コマンドとして 1 つだけ候補にする
    if (( wrapper )); then
      if [[ $w == '--' ]]; then
        wrapper=2
        (( i++ ))
        continue
      fi
      if (( wrapper == 1 )) && [[ $w == -* && $w != '-' ]]; then
        if [[ $w != *=* ]] && (( ${optargs[(Ie)$w]} )); then
          (( i += 2 ))
        else
          (( i++ ))
        fi
        continue
      fi
      _ymt_tmux_window_parsed+=( "cmd"$'\t'"${w:t}" )
      prev_seg=other
      wrapper=0
      head=0
      (( i++ ))
      continue
    fi

    case $w in
      command|builtin|exec|env|nohup|time|sudo)
        wrapper=1
        wname="$w"
        optargs=(${=_ymt_tmux_window_wrapper_optargs[$wname]})
        (( i++ ))
        continue
        ;;
    esac

    if [[ $w == cd ]]; then
      # cd のオプション (-L / -P / -q 等) を読み飛ばし、実際の移動先を集める。
      # 引数なしは $HOME、`cd -- <dir>` は以降を literal 扱い。
      # `cd -` は OLDPWD がここまでの移動で変わるため、`-` のまま後段へ渡す。
      # 引数が複数ある場合 (zoxide の複数語クエリ) はすべて保持する。
      j=$(( i + 1 ))
      sep=0
      cdargs=()
      while (( j <= n )); do
        next="${words[j]}"
        case $next in
          ';'|'&&'|'||'|'|'|'|&'|'&'|'('|')'|'{'|'}'|$'\n')
            sep=1
            break
            ;;
        esac
        raw="$next"
        next="${(Q)next}"
        # 引用・エスケープされた $ は shell も展開しないので、リテラル扱いにする
        if [[ $raw == *\'* || $raw == *'\$'* ]]; then
          flag=L
        else
          flag=E
        fi
        if (( ${#cdargs} == 0 )) && [[ $next == '--' ]]; then
          # 以降はオプションとして解釈しない
          (( j++ ))
          while (( j <= n )); do
            next="${words[j]}"
            case $next in
              ';'|'&&'|'||'|'|'|'|&'|'&'|'('|')'|'{'|'}'|$'\n')
                sep=1
                break
                ;;
            esac
            if [[ $next == *\'* || $next == *'\$'* ]]; then
              cdargs+="L${(Q)next}"
            else
              cdargs+="E${(Q)next}"
            fi
            (( j++ ))
          done
          break
        elif (( ${#cdargs} == 0 )) && [[ $next == '-' ]]; then
          cdargs+='L-'
          (( j++ ))
          break
        elif (( ${#cdargs} == 0 )) && [[ $next == -* ]]; then
          (( j++ ))
          continue
        else
          cdargs+="${flag}${next}"
          (( j++ ))
        fi
      done

      # 直前が cd でない条件付き cd は先行コマンドの成否を再現できない。
      # 誤った移動先を使わないよう `x` (再現不能) として後段に伝える。
      if [[ $cond != u && $prev_seg != cd ]]; then
        cond=x
      fi

      if (( ${#cdargs} == 0 )); then
        _ymt_tmux_window_parsed+=( "cd"$'\t'"$cond"$'\t'"L$HOME" )
      else
        _ymt_tmux_window_parsed+=( "cd"$'\t'"$cond"$'\t'"${(pj:\t:)cdargs}" )
      fi
      prev_seg=cd
      head=0
      # j は区切り、または消費し終えた次の位置を指す
      i=$j
      continue
    fi

    _ymt_tmux_window_parsed+=( "cmd"$'\t'"${w:t}" )
    prev_seg=other
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

# @ymt_win_pane_repos にペインのリポジトリ名を追加または更新する。
# データ形式: pane_id=repo_name を改行区切りで保持
_ymt_tmux_window_pane_repos_update() {
  local data="$1" pane_id="$2" repo="$3"
  local -a result
  local entry found=0

  if [[ -z $data ]]; then
    print -r -- "${pane_id}=${repo}"
    return
  fi

  for entry in ${(f)data}; do
    [[ -z $entry ]] && continue
    if [[ ${entry%%=*} == $pane_id ]]; then
      result+=("${pane_id}=${repo}")
      found=1
    else
      result+=("$entry")
    fi
  done
  (( found )) || result+=("${pane_id}=${repo}")
  print -r -- "${(F)result}"
}

# @ymt_win_pane_repos から指定ペインのエントリを削除する
_ymt_tmux_window_pane_repos_remove() {
  local data="$1" pane_id="$2"
  local -a result
  local entry

  [[ -z $data ]] && return

  for entry in ${(f)data}; do
    [[ -z $entry ]] && continue
    [[ ${entry%%=*} == $pane_id ]] || result+=("$entry")
  done
  (( ${#result} )) && print -r -- "${(F)result}"
}

# @ymt_win_pane_repos の全ペインから一意なリポジトリ名を収集し | 区切りで出力
_ymt_tmux_window_composite_name() {
  local data="$1" entry repo
  local -a repos

  [[ -n $data ]] || return 1

  for entry in ${(f)data}; do
    [[ -z $entry ]] && continue
    repo="${entry#*=}"
    [[ -n $repo ]] && (( ${repos[(Ie)$repo]} )) || repos+=("$repo")
  done

  (( ${#repos} )) || return 1
  print -r -- "${(j:|:)repos}"
}

# 同名の window が既に存在する場合、末尾に -N サフィックスを付与する
_ymt_tmux_window_suffixed_name() {
  local base="$1" win_name max_n=0 n
  local -a existing

  existing=(${(f)"$(tmux list-windows -F '#{window_name}' 2>/dev/null)"})

  for win_name in $existing; do
    if [[ $win_name == $base ]]; then
      max_n=1
    elif [[ $win_name == $base-<-> ]]; then
      n="${win_name#$base-}"
      [[ $n == <-> ]] && (( n > max_n )) && max_n=$n
    fi
  done

  if (( max_n > 0 )); then
    print -r -- "${base}-$(( max_n + 1 ))"
  else
    print -r -- "$base"
  fi
}

_ymt_tmux_window_name_preexec() {
  [[ -n $TMUX && -n $TMUX_PANE ]] || return
  (( $+commands[tmux] )) || return

  # $3 は alias 展開済みのコマンドライン
  local -a lw
  local matched=0 line jobspec jtext
  line="${3:-$1}"

  # `fg` / `fg %2` / `%2` はジョブ再開なので、停止中ジョブのコマンドで判定し直す
  lw=(${(z)line})
  if [[ ${lw[1]} == fg || ${lw[1]} == %* ]]; then
    jobspec="${lw[1]}"
    [[ $jobspec == fg ]] && jobspec="${lw[2]:-%+}"
    jtext="$(_ymt_tmux_window_job_text "$jobspec")"
    [[ -n $jtext ]] && line="$jtext"
  fi

  # `cd foo && claude` は preexec 時点でまだ移動していないため、移動先も集める。
  # agent に到達した後の cd は反映しない (`claude; cd ../other` 等)。
  # 対象コマンドでない場合にコストを払わないよう、展開は判定後にまとめて行う。
  local l kind val d w2
  local -a rawcds cddirs parts eparts cdexp
  setopt localoptions nonomatch nonullglob
  _ymt_tmux_window_parse "$line"
  for l in $_ymt_tmux_window_parsed; do
    kind="${l%%$'\t'*}"
    val="${l#*$'\t'}"
    if [[ $kind == cd ]]; then
      (( matched )) || rawcds+="$val"
    elif (( ${YMT_TMUX_AGENT_COMMANDS[(Ie)$val]} )); then
      matched=1
    fi
  done
  (( matched )) || return

  # val は `<cond><TAB><E|L><移動先>...` 形式。cond はそのまま保持して後段へ渡す
  local cond rest skip_cond=0
  for val in $rawcds; do
    cond="${val%%$'\t'*}"
    rest="${val#*$'\t'}"

    # 再現不能な条件付き cd。ここまでの収集を破棄し、次の無条件 cd まで無視する
    if [[ $cond == x ]]; then
      cddirs=()
      skip_cond=1
      continue
    fi
    if (( skip_cond )); then
      [[ $cond == u ]] || continue
      skip_cond=0
    fi

    if [[ $rest == 'L-' ]]; then
      # OLDPWD は移動を再現する側で解決する
      cddirs+="$cond"$'\t'"-"
      continue
    fi
    # 複数語 (zoxide クエリ) も 1 語も、語ごとに展開してから TAB 区切りで戻す
    parts=("${(@ps:\t:)rest}")
    eparts=()
    for w2 in $parts; do
      d="${w2[2,-1]}"
      # 引用符で抑止されていない $VAR / ${VAR} だけを展開する。
      # コマンド置換は preexec で実行してしまうため除外する
      if [[ ${w2[1]} == E ]]; then
        if [[ $d == *'$'* && $d != *'$('* && $d != *'`'* ]]; then
          d="${(e)d}"
        fi
        # ~ 展開のため、配列コンテキストで GLOB_SUBST をかける
        cdexp=(${~d})
        d="${cdexp[1]:-$d}"
      fi
      eparts+="$d"
    done
    cddirs+="$cond"$'\t'"${(pj:\t:)eparts}"
  done

  local name state composite_name pane_repos_data
  local -a others f
  name="$(_ymt_tmux_window_repo_name "${cddirs[@]}")"
  [[ -n $name ]] || return

  state="$(tmux display-message -p -t "$TMUX_PANE" \
    "#{@ymt_win_agents}"$'\t'"#{@ymt_win_prev_auto}"$'\t'"#{automatic-rename}"$'\t'"#{window_name}"$'\t'"#{@ymt_win_pane_repos}" \
    2>/dev/null)" || return
  [[ -n $state ]] || return
  f=("${(@ps:\t:)state}")
  pane_repos_data="${f[5]}"

  others=(${(f)"$(_ymt_tmux_window_other_agents "$f[1]")"})

  pane_repos_data="$(_ymt_tmux_window_pane_repos_update "$pane_repos_data" "$TMUX_PANE" "$name")"

  composite_name="$(_ymt_tmux_window_composite_name "$pane_repos_data")"
  [[ -n $composite_name ]] || composite_name="$name"

  # 初回リネーム時のみサフィックスを付与
  if [[ -z $f[1] ]]; then
    composite_name="$(_ymt_tmux_window_suffixed_name "$composite_name")"
  fi

  tmux rename-window -t "$TMUX_PANE" "$composite_name" 2>/dev/null || return
  # rename-window はそのウィンドウの automatic-rename を off にする

  # 退避値が未設定のときだけ保存する。他ペインが kill されて @ymt_win_agents が
  # stale になっていても (others が空でも)、既存の退避値は上書きしない。
  if [[ -z $f[2] ]]; then
    tmux set-option -w -t "$TMUX_PANE" @ymt_win_prev_auto "$f[3]" 2>/dev/null
    tmux set-option -w -t "$TMUX_PANE" @ymt_win_prev_name "$f[4]" 2>/dev/null
  fi
  tmux set-option -w -t "$TMUX_PANE" @ymt_win_agents "${(j: :)others} $TMUX_PANE" 2>/dev/null
  tmux set-option -w -t "$TMUX_PANE" @ymt_win_pane_repos "$pane_repos_data" 2>/dev/null
  _ymt_tmux_window_active=1
}

# 対象 CLI のジョブがまだ生きているかどうかを返す。
# precmd は「agent の終了」ではなく「プロンプトの復帰」で走るため、
# `opencode &` のバックグラウンド起動や `Ctrl-Z` での停止でも呼ばれる。
# そのままクリアすると稼働中の agent のバーを消してしまうので、
# ジョブのコマンド文字列を対象コマンドと突き合わせて判定する。
# _ymt_tmux_window_parsed を上書きするが、precmd 以降で参照する箇所はない
# (preexec は毎回パースし直す)。
_ymt_tmux_agent_job_alive() {
  local j l kind val

  (( ${+jobtexts} )) || return 1
  (( ${#jobtexts} )) || return 1

  for j in ${(k)jobtexts}; do
    _ymt_tmux_window_parse "${jobtexts[$j]}"
    for l in $_ymt_tmux_window_parsed; do
      kind="${l%%$'\t'*}"
      val="${l#*$'\t'}"
      [[ $kind == cmd ]] || continue
      (( ${YMT_TMUX_AGENT_COMMANDS[(Ie)$val]} )) && return 0
    done
  done

  return 1
}

# agent 終了時に自ペインのステータスバーのバーをクリアする。
# @agent_status は pane option なので、他ペインで動いている agent には影響しない。
# option 名を二重管理しないよう、直接 tmux を叩かずスクリプト経由で呼ぶ。
_ymt_tmux_agent_status_clear() {
  local script="$HOME/.tmux/agent-status.sh"
  [[ -f $script ]] || return
  _ymt_tmux_agent_job_alive && return
  sh "$script" clear 2>/dev/null
}

_ymt_tmux_window_name_precmd() {
  # rename していないプロンプトでは何もしない (サブプロセスを起動しない)
  [[ -n $_ymt_tmux_window_active ]] || return
  _ymt_tmux_window_active=""

  [[ -n $TMUX && -n $TMUX_PANE ]] || return
  (( $+commands[tmux] )) || return

  _ymt_tmux_agent_status_clear

  local state agents rest auto name pane_repos_data composite_name
  local -a others
  state="$(tmux display-message -p -t "$TMUX_PANE" \
    "#{@ymt_win_agents}"$'\t'"#{@ymt_win_prev_auto}"$'\t'"#{@ymt_win_prev_name}"$'\t'"#{@ymt_win_pane_repos}" 2>/dev/null)" || return
  agents="${state%%$'\t'*}"
  rest="${state#*$'\t'}"
  auto="${rest%%$'\t'*}"
  rest="${rest#*$'\t'}"
  name="${rest%%$'\t'*}"
  pane_repos_data="${rest#*$'\t'}"

  others=(${(f)"$(_ymt_tmux_window_other_agents "$agents")"})

  # 他ペインでまだ agent が動いている場合は自ペインを外し、window 名を再計算
  if (( ${#others} )); then
    pane_repos_data="$(_ymt_tmux_window_pane_repos_remove "$pane_repos_data" "$TMUX_PANE")"
    composite_name="$(_ymt_tmux_window_composite_name "$pane_repos_data")"
    tmux set-option -w -t "$TMUX_PANE" @ymt_win_agents "${(j: :)others}" 2>/dev/null
    tmux set-option -w -t "$TMUX_PANE" @ymt_win_pane_repos "$pane_repos_data" 2>/dev/null
    [[ -n $composite_name ]] && tmux rename-window -t "$TMUX_PANE" "$composite_name" 2>/dev/null
    return
  fi

  tmux set-option -w -t "$TMUX_PANE" -u @ymt_win_agents 2>/dev/null
  tmux set-option -w -t "$TMUX_PANE" -u @ymt_win_prev_auto 2>/dev/null
  tmux set-option -w -t "$TMUX_PANE" -u @ymt_win_prev_name 2>/dev/null
  tmux set-option -w -t "$TMUX_PANE" -u @ymt_win_pane_repos 2>/dev/null

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
