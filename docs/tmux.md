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

## AI agent 実行中の window 名

`.tmux.conf` は `automatic-rename on` のため、window 名は通常フォアグラウンドのプロセス名になります。
ただし AI agent CLI ではこれが役に立ちません
(Claude Code はバージョン付きバイナリで起動するため `2.1.221` のような window 名になります)。

そこで `.zsh/extensions/tmux_window_name.zsh` が、対象 CLI の実行中だけ window 名をリポジトリ名に差し替えます。

| 状況 | window 名 |
|---|---|
| 通常のリポジトリ | `website-2026` |
| リポジトリ内のサブディレクトリ | `website-2026` (リポジトリルート基準) |
| git worktree 内 | `website-2026:fix-login` (`リポジトリ名:worktree ディレクトリ名`) |
| git 管理外のディレクトリ | カレントディレクトリ名 |

CLI が終了すると元の状態へ戻ります。`Prefix` + `,` で手動リネームした window は、その名前へ復元されます。

### 対象コマンド

既定は `claude` / `codex` / `opencode` / `agy` / `antigravity` です。
`~/.zshrc_local` で配列を定義すると上書きできます。

```zsh
YMT_TMUX_AGENT_COMMANDS=(claude codex opencode agy antigravity aider)
```

リポジトリ名と worktree 名の区切り文字は `_ymt_tmux_window_sep` (既定 `:`) で変更できます。

### 制限

- zsh の `preexec` / `precmd` で発火するため、対話 shell から起動した場合のみ有効です。
  `tmux new-window claude` のような直起動やスクリプト経由では発火しません。
- window 名は window 単位のため、1 つの window の複数ペインで別々の agent を動かすと後勝ちになります。
  ペイン単位の識別は `~/.tmux/agent-status.sh` によるステータスバー(左端の色付きバー)が担います。
