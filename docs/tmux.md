# Tmux Cheat Sheet

このドキュメントは、現在の設定ファイル（`.tmux.conf`）に基づいたショートカットキーとコマンドのまとめです。

## Tmux

**Prefix Key:** `Ctrl+e`
(デフォルトの `Ctrl+b` から変更されています)

### ウィンドウ・ペイン操作 (カスタム設定)

| キー操作 | 動作 | 設定元 |
|---|---|---|
| `Prefix` + `c` | 新規ウィンドウ作成 (カレントディレクトリを引き継ぐ) | `.tmux.conf` |
| `Prefix` + `C-n` | 次のウィンドウへ移動 | `.tmux.conf` |
| `Prefix` + `\` | ペインを左右に分割 (カレントディレクトリを引き継ぐ) | `.tmux.conf` |
| `Prefix` + `-` | ペインを上下に分割 (カレントディレクトリを引き継ぐ) | `.tmux.conf` |
| `Prefix` + `h/j/k/l` | ペインの移動 (左/下/上/右) | `.tmux.conf` |
| `Prefix` + `H/J/K/L` | ペインのリサイズ (長押し可能) | `.tmux.conf` |
| `Prefix` + `z` | ペインを閉じる (kill-pane) <br> **注意:** デフォルトの「ズーム機能」は上書きされ使用不可 | `.tmux.conf` |
| `Prefix` + `i` | ペイン番号を表示 | `.tmux.conf` |

### デフォルトで有効な基本機能 (Prefix + ...)
これらの機能は設定ファイルで上書きされておらず、デフォルトのまま使用可能です。

| キー操作 | 動作 |
|---|---|
| `Prefix` + `s` | セッション一覧を表示・選択 (ツリー表示) |
| `Prefix` + `w` | ウィンドウ一覧を表示・選択 (ツリー表示) |
| `Prefix` + `d` | デタッチ (セッションをバックグラウンドに残してシェルに戻る) |
| `Prefix` + `,` | ウィンドウ名の変更 |
| `Prefix` + `$` | セッション名の変更 |
| `Prefix` + `x` | ペインを閉じる (確認あり) |
| `Prefix` + `!` | 現在のペインを新しいウィンドウに切り離す (Break pane) |
| `Prefix` + `Space` | ペインレイアウトの順次切り替え |
| `Prefix` + `?` | キーバインド一覧を表示 (ヘルプ) |

### コピーモード (Vi Mode)

| キー操作 | 動作 | 設定元 |
|---|---|---|
| `Prefix` + `y` | コピーモード開始 | `.tmux.conf` |
| `Prefix` + `p` | バッファの内容をペースト | `.tmux.conf` |
| `v` | 選択開始 (Visual selection) | `.tmux.conf` |
| `C-v` | 短形選択 (Rectangle toggle) | `.tmux.conf` |
| `y` | 選択範囲をコピー (システムクリップボードへ `pbcopy`) | `.tmux.conf` |
| `Y` | 行コピー | `.tmux.conf` |

### その他ユーティリティ

| キー操作 | 動作 | 設定元 |
|---|---|---|
| `Prefix` + `r` | `.tmux.conf` のリロード | `.tmux.conf` |
| `Prefix` + `g` | `lazygit` をポップアップウィンドウで開く | `.tmux.conf` |
| `C-z` | Prefixキーを内側のアプリケーションに送信 | `.tmux.conf` |

## window 名 (git リポジトリ名)

`.tmux.conf` は `automatic-rename on` のため、window 名は通常フォアグラウンドのプロセス名になります。
`.zsh/extensions/window_repo_name.zsh` は `chpwd` (cd 時) に、git リポジトリ内なら window 名を
リポジトリ名へ固定します。`rename-window` は `automatic-rename` を off にするため、
その window にいる間はリポジトリ名が維持されます
(agent CLI 実行中も `2.1.221` のようなバージョン付きプロセス名にはなりません)。

| 状況 | window 名 |
|---|---|
| 通常のリポジトリ | `website-2026` |
| リポジトリ内のサブディレクトリ | `website-2026` (リポジトリルート基準) |
| git worktree 内 | `website-2026:fix-login` (`リポジトリ名:worktree ディレクトリ名`) |
| git 管理外 | 自動リネーム (プロセス名。例: `zsh`, `nvim`) |

- `Prefix` + `,` で手動リネームした window には介入しません
  (自フックが付けた名前を window option `@ymt_repo_set_name` で識別し、
  外部で変更されていたら以後触りません)。
- window 名は window 単位のため、複数ペインで別々のディレクトリにいる場合は
  **最後に cd したペイン**のリポジトリ名が優先されます。
- リポジトリ名と worktree 名の区切り文字は `_ymt_tmux_window_sep` (既定 `:`) で変更できます。

```zsh
# ~/.zshrc_local
_ymt_tmux_window_sep="-"
```

### 制限

- `chpwd` で発火するため **cd したときのみ** 更新されます。`chpwd` は起動時の
  カレントディレクトリでは走らないため、リポジトリ内で window を新規作成
  (`Prefix` + `c`) した直後や、同一ディレクトリ内で `git clone` した場合は、
  一度 cd し直すまで名前は変わりません。
- git 管理外へ移動すると、その window の名前は `automatic-rename` に戻ります。
  リポジトリ名を付けていたペイン自身が移動したときだけ復帰します。

## AI agent 実行中のステータスバー

window 名の左端に付く色付きバー (`@agent_status`) は pane option で、Claude Code /
Codex の agent hooks (`bin/agent_hooks.sh`)、OpenCode の tmux-status プラグイン、
Pi の `~/.pi/agent/extensions/tmux-status.ts` が設定します。

Claude Code (`SessionEnd`) と Pi (`session_shutdown`) は自分でクリアしますが、
Codex / OpenCode には終了イベントに相当する hook がなく、
`.zsh/extensions/window_repo_name.zsh` の `precmd` が終了時にクリアします。
自前でクリアする CLI でも kill など異常終了時は `precmd` がクリアします。
`@agent_status` はペイン単位なので、同じ window の他ペインで動いている agent のバーには影響しません。

precmd は「agent の終了」ではなく「プロンプトの復帰」で走るため、対象 CLI のジョブが
まだ生きている間 (`Ctrl-Z` での停止中、`opencode &` のようなバックグラウンド起動中) は
クリアしません。`Ctrl-Z` で停止した agent のバーはそのまま残り、`fg` で再開して
本当に終了した時点でクリアされます。

ただし `&` でバックグラウンド起動した場合、終了時には precmd が走らないためバーが残ります。

生存判定は zsh の `jobstates` を使いますが、`jobtexts` はジョブ全体のコマンド文字列しか
持たないため、パイプで agent と他プロセスを組み合わせた場合にどのプロセスが agent かは
区別できません (agent CLI はバージョン番号のプロセス名で動くため `ps` による照合も不可)。
そのため、ジョブが `suspended` なら生存、`running` でいずれかのプロセスが `done` なら
非生存、という保守的な判定にしています。`true | opencode &` のようにバックグラウンド +
パイプ + 先行要素が先に終了する組み合わせは原理的に判別できません。

### 対象コマンド

対象コマンドは `YMT_TMUX_AGENT_COMMANDS` で上書きできます (既定は
`claude` / `codex` / `opencode` / `pi` / `agy` / `antigravity`)。
`~/.zshrc_local` で配列を定義してください。

```zsh
# ~/.zshrc_local
YMT_TMUX_AGENT_COMMANDS=(claude codex opencode pi agy antigravity aider)
```

## tmux-agent-sidebar

[hiroppy/tmux-agent-sidebar](https://github.com/hiroppy/tmux-agent-sidebar) を導入しています。
全 session / window の Claude Code / Codex / OpenCode を 1 つのサイドバーに一覧し,
状態・プロンプト・Git 情報・worktree などを window を切り替えずに確認できます。

`~/.tmux` はリポジトリ内 `.tmux/` への symlink のため, プラグインの実体は
`.tmux/plugins/tmux-agent-sidebar/` に clone されます (git 管理外)。

### 導入・更新

```sh
make tmux_plugin            # clone + バイナリ取得 + エージェント配線
make tmux_plugin_update     # git pull + 最新バイナリ取得
make tmux_plugin_uninstall  # 追加した agent hooks / OpenCode bridge を削除
```

- バイナリは GitHub Releases の prebuilt を取得し, 失敗した場合は
  `cargo build --release` にフォールバックします。
- 導入手順は `bin/tmux_plugin.sh` にまとまっており, 何度実行しても冪等です。
- 設定の再読み込みは `Prefix` + `r` です。

### キーバインド

| キー操作 | 動作 |
|---|---|
| `Prefix` + `e` | 現在の window でサイドバーの表示を切り替え |
| `Prefix` + `E` | 全 window でサイドバーの表示を切り替え |

`.tmux.conf` で `@sidebar_auto_create off` を設定しているため, 新しい window を
開いただけではサイドバーは表示されません。必要になったときだけ `Prefix` + `e` で開きます。

### エージェント連携

`make tmux_plugin` は `opencode` / `claude` / `codex` を `command -v` で判定し,
**インストールされているものだけ**配線します。無いものは skip します。

| エージェント | 配線内容 |
|---|---|
| OpenCode | `~/.config/opencode/plugins/tmux-agent-sidebar.js` を同梱 bridge への symlink として作成 |
| Claude Code | `tmux-agent-sidebar setup claude` の hooks を `~/.claude/settings.json` へマージ |
| Codex | `~/.codex/config.toml` の `[features]` に `codex_hooks = true` を追加し, hooks を `~/.codex/hooks.json` へマージ |

- 追加した hooks は `tmux-agent-sidebar/hook.sh` を含む command で識別し,
  再実行時に一度削除してからマージします (`bin/agent_hooks.sh` が管理する
  `agent-status.sh` などの hooks には触れません)。
- Codex は設定変更後に `codex` を再起動し, `/hooks` で新しい hooks を trust する
  必要があります。
- Claude Code の plugin 経由インストール (`/plugin marketplace add ...`) は
  このスクリプトと同等の hooks を追加するため, 併用しないでください。
- 既存の `@agent_status` による window 名左端のバーはそのまま併用できます。
