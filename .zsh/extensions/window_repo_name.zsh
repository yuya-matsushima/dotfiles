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

# リポジトリ名と worktree 名の区切り文字
typeset -g _ymt_tmux_window_sep="${_ymt_tmux_window_sep:-:}"

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

if autoload -Uz add-zsh-hook 2>/dev/null; then
  add-zsh-hook chpwd _ymt_tmux_repo_name_chpwd
fi
