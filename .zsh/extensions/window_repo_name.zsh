# tmux window 名を git リポジトリ名にする
#
# .tmux.conf は automatic-rename on のため、window 名は通常フォアグラウンドの
# プロセス名になる。git リポジトリ内ではリポジトリ名を表示したいので、
# chpwd (cd 時) に rename-window でリポジトリ名へ固定する。
# rename-window は automatic-rename を off にするため、その window にいる間は
# リポジトリ名が維持される (agent CLI 実行中も `2.1.221` のような
# バージョン付きプロセス名にはならない)。
#
#   git リポジトリへ cd  : website-2026
#   サブディレクトリへ cd : website-2026 (リポジトリルート基準)
#   git worktree へ cd   : website-2026:fix-login
#   git 管理外へ cd      : automatic-rename on に戻す (プロセス名表示)
#
# window 名は window 単位のため、複数ペインで別々のディレクトリにいる場合は
# 最後に cd したペインのリポジトリ名が優先される。
#
# Prefix + , で手動リネームした window には介入しない。自フックが付けた名前は
# window option @ymt_repo_set_name で識別し、外部で変更されていたら以後触らない。
# リポジトリ名と worktree 名の区切り文字は _ymt_tmux_window_sep (既定 `:`)。
#
# あわせて、agent CLI 終了時にステータスバーのバー (pane option @agent_status) を
# クリアする。Claude Code は SessionEnd hook で自前でクリアするが、Codex /
# OpenCode には終了イベントに相当する hook がなく、この precmd がないとバーが
# 残り続ける (bin/agent_hooks.sh 参照)。

# リポジトリ名と worktree 名の区切り文字
typeset -g _ymt_tmux_window_sep="${_ymt_tmux_window_sep:-:}"

# この shell が対象 CLI を実行したか (precmd のステータスクリア用のフラグ)
typeset -g _ymt_tmux_agent_seen=""

# ステータスクリアの生存判定に使う対象コマンド。
# ~/.zshrc_local などで配列を定義すると上書きできる。
typeset -ga YMT_TMUX_AGENT_COMMANDS
(( ${#YMT_TMUX_AGENT_COMMANDS} )) || YMT_TMUX_AGENT_COMMANDS=(
  claude
  codex
  opencode
  agy
  antigravity
)

# window 名として使うリポジトリ名を出力する。
# git 管理外 / git 未インストールのときは何も出力しない。
# worktree でも本体リポジトリ名を得るため --git-common-dir を使い、
# worktree ディレクトリ名が異なる場合のみ `repo:worktree` にする。
_ymt_tmux_window_repo_name() {
  local common="" top="" root repo wt

  (( $+commands[git] )) || return 0

  common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
  top="$(git rev-parse --show-toplevel 2>/dev/null)"

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
    return 0
  fi

  # GitHub リポジトリの場合は remote URL から canonical なリポジトリ名を取得
  local remote_url
  remote_url="$(git -C "$root" remote get-url origin 2>/dev/null)"
  if [[ $remote_url == *github.com* ]]; then
    remote_url="${remote_url##*/}"
    remote_url="${remote_url%.git}"
    repo="$remote_url"
  fi

  wt="${top:t}"
  if [[ -n $wt && $wt != $repo ]]; then
    print -r -- "${repo}${_ymt_tmux_window_sep}${wt}"
  else
    print -r -- "$repo"
  fi
}

# 対象 CLI のジョブがまだ生きているかどうかを返す。
# precmd は「agent の終了」ではなく「プロンプトの復帰」で走るため、
# `opencode &` のバックグラウンド起動や Ctrl-Z での停止でも呼ばれる。
# そのままクリアすると稼働中の agent のバーを消してしまうので、
# ジョブのコマンド文字列を対象コマンドと突き合わせて判定する。
_ymt_tmux_agent_job_alive() {
  local j w state procs
  local -a words

  (( ${+jobtexts} )) || return 1
  (( ${#jobtexts} )) || return 1

  for j in ${(k)jobtexts}; do
    # jobstates は `suspended:+:12345=done:12346=suspended` 形式
    # (先頭がジョブ全体の状態、以降がプロセスごとの状態)。
    # jobtexts はジョブ全体のコマンド文字列しか持たないため、次の優先順で判定する:
    #   - suspended : Ctrl-Z で止めた agent 自体なので生存扱い
    #   - running   : いずれかのプロセスが done なら生存扱いしない
    #   - それ以外  : done 等。生存扱いしない
    state="${jobstates[$j]%%:*}"
    procs="${jobstates[$j]#*:*:}"
    case $state in
      suspended) ;;
      running) [[ $procs == *=done* ]] && continue ;;
      *) continue ;;
    esac

    words=(${(z)jobtexts[$j]})
    for w in ${words[@]}; do
      w="${(Q)w}"
      w="${w:t}"
      (( ${YMT_TMUX_AGENT_COMMANDS[(Ie)$w]} )) && return 0
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

# cd したディレクトリに応じて window 名を更新する。
_ymt_tmux_repo_name_chpwd() {
  [[ -n $TMUX && -n $TMUX_PANE ]] || return
  (( $+commands[tmux] )) || return

  local state cur auto set_name owner name
  state="$(tmux display-message -p -t "$TMUX_PANE" \
    "#{window_name}"$'\t'"#{automatic-rename}"$'\t'"#{@ymt_repo_set_name}"$'\t'"#{@ymt_repo_renamed}" \
    2>/dev/null)" || return
  [[ -n $state ]] || return

  cur="${state%%$'\t'*}"
  state="${state#*$'\t'}"
  auto="${state%%$'\t'*}"
  state="${state#*$'\t'}"
  set_name="${state%%$'\t'*}"
  owner="${state#*$'\t'}"

  # 自フックが付けた名前が外部で変更されていたら、以後その window には介入しない
  # (Prefix + , による手動リネームなどを尊重する)
  if [[ -n $set_name && $cur != $set_name ]]; then
    tmux set-option -w -t "$TMUX_PANE" -u @ymt_repo_set_name 2>/dev/null
    tmux set-option -w -t "$TMUX_PANE" -u @ymt_repo_renamed 2>/dev/null
    return
  fi

  # 自フック未関与で automatic-rename が off の window は手動リネーム済みとみなす
  if [[ -z $set_name && $auto != 1 ]]; then
    return
  fi

  name="$(_ymt_tmux_window_repo_name)"

  if [[ -n $name ]]; then
    if [[ $cur != $name ]]; then
      tmux rename-window -t "$TMUX_PANE" "$name" 2>/dev/null || return
    fi
    # rename-window は automatic-rename を off にする
    tmux set-option -w -t "$TMUX_PANE" @ymt_repo_set_name "$name" 2>/dev/null
    tmux set-option -w -t "$TMUX_PANE" @ymt_repo_renamed "$TMUX_PANE" 2>/dev/null
    return
  fi

  # git 管理外: 自ペインが名前を所有している場合のみ自動リネームへ戻す
  if [[ $owner == $TMUX_PANE ]]; then
    tmux set-option -w -t "$TMUX_PANE" -u @ymt_repo_set_name 2>/dev/null
    tmux set-option -w -t "$TMUX_PANE" -u @ymt_repo_renamed 2>/dev/null
    [[ $auto == 1 ]] || tmux set-window-option -t "$TMUX_PANE" automatic-rename on 2>/dev/null
  fi
}

# 対象 CLI の起動を検出して、precmd でのステータスクリアを有効にする。
# 対象 CLI が全く起動していないプロンプトではサブプロセスを起動しないためのフラグ。
_ymt_tmux_agent_preexec() {
  [[ -n $TMUX && -n $TMUX_PANE ]] || return
  (( $+commands[tmux] )) || return

  local line="${3:-$1}" w
  local -a words
  words=(${(z)line})

  # fg / %N は停止中の agent の再開かもしれないので保守的にフラグを立てる
  if [[ ${words[1]} == fg || ${words[1]} == %* ]]; then
    _ymt_tmux_agent_seen=1
    return
  fi

  for w in ${words[@]}; do
    w="${(Q)w}"
    w="${w:t}"
    if (( ${YMT_TMUX_AGENT_COMMANDS[(Ie)$w]} )); then
      _ymt_tmux_agent_seen=1
      return
    fi
  done
}

_ymt_tmux_agent_precmd() {
  # 対象 CLI を実行していないプロンプトでは何もしない (サブプロセスを起動しない)
  [[ -n $_ymt_tmux_agent_seen ]] || return
  _ymt_tmux_agent_seen=""

  [[ -n $TMUX && -n $TMUX_PANE ]] || return
  (( $+commands[tmux] )) || return

  _ymt_tmux_agent_status_clear
}

if autoload -Uz add-zsh-hook 2>/dev/null; then
  add-zsh-hook chpwd _ymt_tmux_repo_name_chpwd
  add-zsh-hook preexec _ymt_tmux_agent_preexec
  add-zsh-hook precmd _ymt_tmux_agent_precmd
fi
