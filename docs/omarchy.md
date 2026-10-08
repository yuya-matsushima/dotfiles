# Omarchy (Linux) セットアップ

macOS と Linux (Omarchy / Arch) で共通の dotfiles を 1 リポジトリで管理します。
macOS と Linux で設定が本質的に異なるものだけを `omarchy/` 配下に OS 別定義として置きます。

## セットアップ

```sh
make omarchy
```

`make omarchy` は次を実行します。

1. `bin/omarchy.sh` : `bin/omarchy/cli.sh` を呼び出して CLI ツールを導入し, ログインシェルを zsh 化
2. `bin/zsh_plugin.sh` : zsh 用 git-prompt の取得
3. `make link` : `$HOME` 配下への symlink 作成

## CLI ツール (`bin/omarchy/cli.sh`)

macOS 側 `bin/homebrew/cli.sh` で導入している CLI ツールのうち, omarchy で使うものを
Arch パッケージとして導入します。パッケージ名は Arch 側に読み替えています。

omarchy base (`/usr/share/omarchy/install/omarchy-base.packages`) が既に導入する
パッケージ (`bat` / `eza` / `fd` / `fzf` / `imagemagick` / `jq` / `neovim` /
`postgresql-libs` / `qrencode` / `ripgrep` / `tmux` / `tree-sitter-cli` / `zoxide` など)
は二重管理を避けるため含めません。

その他の除外:

- `git` / `curl` / `make` / `grep` / `ncurses` などは base や base-devel で導入済み。
- `mise` は omarchy の `mise-bin`, `gh` / `opencode` / `uv` は mise 管理のため含めません。
- `direnv` は mise で代替するため含めません。
- `htop` / `mariadb-clients` (`mysql-client` 相当) は未使用のため含めません。
- `pngpaste` / `font-symbols-only-nerd-font` など macOS 専用ツールは含めません。
- 公式リポジトリに無いツール (`diff-pdf-git`, `github-copilot-cli-bin`) は AUR から
  導入します。AUR ヘルパー (`omarchy` / `yay`) が無い環境では自動的に skip されます。

## zsh の導入とログインシェル変更

Omarchy 既定のログインシェルは bash です。zsh を使う場合の手順は次の通りです。

```sh
# 1) 導入
sudo pacman -S --needed zsh        # もしくは: omarchy pkg add zsh

# 2) /etc/shells に載っているか確認 (Arch の zsh パッケージは通常自動で追加)
grep -x /usr/bin/zsh /etc/shells || echo /usr/bin/zsh | sudo tee -a /etc/shells

# 3) ログインシェル変更 (必ず対話端末で。パスワードを聞かれる)
chsh -s /usr/bin/zsh

# 4) 確認 (現在のログインシェルは $SHELL ではなく passwd を見る)
getent passwd "$USER" | cut -d: -f7
```

### `chsh` が実行できないとき

- `chsh` は PAM でパスワード入力を要求するため, **TTY の無い非対話環境では失敗**します
  (例: `make omarchy` をエージェントや CI から実行した場合)。対話端末で実行してください。
- 非対話環境向けに `bin/omarchy.sh` は `chsh` を行わず, 手動実行を案内して終了します。
- パスワード入力が通らない場合は次でも変更できます。

  ```sh
  sudo chsh -s /usr/bin/zsh "$USER"
  # もしくは
  sudo usermod -s /usr/bin/zsh "$USER"
  ```

### 反映されないように見えるとき

- `$SHELL` はシェル起動時のキャッシュ値で, 変更後も**再ログインするまで**古い値を返します。
  実際の値は `getent passwd "$USER" | cut -d: -f7` で確認してください。
- 反映には**ログアウト → 再ログイン**が必要です。すぐ試す場合は `exec zsh`。
- Omarchy の環境変数 (`OMARCHY_PATH` / `PATH`) は, zsh ログインシェルでも
  `/etc/zsh/zprofile` が `/etc/profile` を source → `/etc/profile.d/omarchy.sh` 経由で
  設定されるため失われません。

## OS 別オーバーレイ (`omarchy/`)

`bin/link.sh` は `uname` で OS を判定し, Linux では `omarchy/<target>` があればそちらを優先します。

| 対象 | 扱い |
|---|---|
| `omarchy/.config/mise/config.toml` | Linux 用 mise 設定。macOS 側は Homebrew で管理する `gh`/`opencode`/`uv` を含む |
| `omarchy/.config/ghostty/config` | Linux 用 Ghostty 設定 (omarchy theme 連動) |
| `omarchy/.pi/agent/settings.json` | `theme: omarchy-system` を含む |
| `.config/nvim` | macOS / Linux 共通 (独自 lazy.nvim 構成) |
| `.config/opencode` | macOS / Linux 共通 |

macOS 専用ターゲット (`.hammerspoon`, `.gvimrc`) は Linux では link しません。

## symlink とバックアップ

- リンク先に実体ファイル/ディレクトリがある場合は内容を失わないよう
  `*.bak.<timestamp>` へ退避してから symlink します。
- `.gitconfig` は XDG 配置の `~/.config/git/config` へリンクします
  (omarchy 既定の git 設定を上書き)。
- `.tmux.conf` は Linux では XDG 配置の `~/.config/tmux/tmux.conf` へリンクします。
  tmux 3.7 は `~/.tmux.conf` と XDG の両方を読み, XDG 側が後に適用されるため,
  omarchy 既定の tmux 設定を上書きするには XDG 側に置く必要があります。
- mise は symlink 先を新しいパスとして扱うため, 初回は `mise trust` が必要になる
  ことがあります (`mise trust ~/Projects/Personal/dotfiles` など)。
