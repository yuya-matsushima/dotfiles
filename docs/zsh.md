# Zsh Cheat Sheet

このドキュメントは、現在の設定ファイル（`.zshrc`, `.zshenv`, `.zsh/functions/fz`）に基づいたショートカットキーとコマンドのまとめです。

## Zsh

### キーバインド (Vi Mode)

Zshは Vi モード (`bindkey -v`) で動作するように設定されています。

#### カスタム設定
| キー操作 | 動作 | 設定元 |
|---|---|---|
| `ESC` `ESC` | コマンドモード (Vi cmd mode) へ移行 | `.zshrc` |
| `Ctrl+a` | 行頭へ移動 | `.zshrc` |
| `Ctrl+e` | 行末へ移動 | `.zshrc` |
| `Ctrl+p` | 履歴を後方検索 (入力中の文字列でフィルタ) | `.zshrc` |
| `Ctrl+n` | 履歴を前方検索 (入力中の文字列でフィルタ) | `.zshrc` |
| `Shift+Tab` | 補完メニューを逆順に選択 | `.zshrc` |

#### デフォルトで有効なViモード操作 (コマンドモード)
`ESC` を押してコマンドモードに入った状態で使用します。

| キー操作 | 動作 |
|---|---|
| `h` / `j` / `k` / `l` | カーソル移動 (左 / 下 / 上 / 右) |
| `w` / `b` | 単語単位で移動 (次 / 前) |
| `0` / `$` | 行頭 / 行末へ移動 |
| `dd` | 行削除 (カット) |
| `D` | カーソル位置から行末まで削除 |
| `u` | アンドゥ (直前の操作を取り消す) |
| `Ctrl+l` | 画面クリア (インサートモードでも動作) |

#### FZF連携 (プラグイン)
`fzf` 導入時に自動設定されるキーバインドです。

| キー操作 | 動作 |
|---|---|
| `Ctrl+r` | コマンド履歴検索 (Interactive History Search) |
| `Ctrl+t` | ファイル検索してコマンドラインに挿入 |
| `Alt+c` (または `Esc+c`) | ディレクトリ検索して移動 (`cd`) |

### 主なエイリアス (抜粋)

| エイリアス | 実行されるコマンド / 説明 | 設定元 |
|---|---|---|
| `ll`, `la`, `lt` | `ls` の各種オプション (`ls -l`, `ls -a`, `ls -t`) | `.zshrc` |
| `root` | 現在のGitリポジトリのルートディレクトリへ `cd` | `.zshrc` |
| `lg` | `lazygit` | `.zshrc` |
| `ni` | `nvim` | `.zshrc` |
| `tinyvim` | 最小構成 (`.vimrc.minimal`) で Vim を起動 | `.zshrc` |
| `tinyprompt` | 画面収録用にプロンプトを簡素化 (`$ ` のみ等) | `.zshrc` |
| `normalprompt` | プロンプトを通常の状態に戻す | `.zshrc` |
| `qr` | `qrencode -t UTF8` (QRコード生成) | `.zshrc` |

---

## fz (Fuzzy Finder Wrapper)

`fzf` を活用した多機能ラッパーコマンドです。`fz <subcommand>` の形式で使用します。

| サブコマンド | 機能概要 | キーバインド・備考 |
|---|---|---|
| `branch` | Git branch の検索とチェックアウト | |
| `log` | Git log の検索と閲覧 | `Ctrl+y`: Commit Hashをコピー |
| `kill` | プロセスの検索と強制終了 (kill) | Tabで複数選択可能 |
| `docker` | Dockerコンテナへの接続 (`exec -it`) | |
| `history` | コマンド履歴からの検索と実行 | |
| `env` | 環境変数の検索と表示 | `Ctrl+y`: 値をコピー |
| `cd` | ディレクトリ履歴 + `fd` 検索による移動 | |
| `pr` | GitHub Pull Request の検索と表示 | `Enter`: 端末で表示, `Ctrl+o`: ブラウザで開く |
| `issue` | GitHub Issue の検索と表示 | `Enter`: 端末で表示, `Ctrl+o`: ブラウザで開く |
| `lazygit` | 配下のGitリポジトリを検索して `lazygit` で開く | |
| `find` | ファイル検索 | パスを表示 (クリップボードにもコピー) |
| `vi` / `vim` | ファイルを検索して Vim で開く | |
