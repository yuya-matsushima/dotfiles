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
| `omarchy/.config/chromium-flags.conf` | Chromium の Wayland / IME フラグ (`--enable-wayland-ime` 等) |
| `omarchy/.pi/agent/settings.json` | `theme: omarchy-system` を含む |
| `.config/nvim` | macOS / Linux 共通 (独自 lazy.nvim 構成) |
| `.config/opencode` | macOS / Linux 共通 |

macOS 専用ターゲット (`.hammerspoon`, `.gvimrc`) は Linux では link しません。

## スクリーンセーバーの軽量化 (`.local/bin/omarchy-screensaver`)

Omarchy 既定のスクリーンセーバー (`/usr/bin/omarchy-screensaver`) は
`ttfx --random-effect --frame-rate 120` でエフェクトを回し続ける。`fireworks` /
`blackhole` / `matrix` のような高負荷な効果が選ばれるとファンが唸る。

設定でエフェクトを選ぶ公式オプションが無いため, `~/.local/bin/omarchy-screensaver`
で `/usr/bin/omarchy-screensaver` をユーザー上書きする (パッケージ本体は変更しない)。

ただし, `~/.local/bin` に置くだけでは有効にならない。Omarchy 既定
(`default.hypr.envs`) が Hyprland の起動プロセスの PATH 先頭に
`/usr/share/omarchy/bin` を挿入し, そこには `/usr/bin/omarchy-*` への symlink が
あるため, `omarchy-screensaver` は常にパッケージ版に解決されてしまう。

そこで `hypr/envs.lua` (`~/.config/hypr/envs.lua`) で冗長な
`/usr/share/omarchy/bin` を PATH から取り除く。`omarchy-*` は引き続き `/usr/bin`
から解決され, `~/.local/bin` (既に `/usr/bin` より前) の上書きが優先される。
`envs.lua` は `hypr/autostart.lua` の先頭で `require("hypr.envs")` して読み込む。

上書き版は**軽い効果を一度だけ描画して静止表示**する。環境変数で調整できる。

| 環境変数 | 既定 | 説明 |
|---|---|---|
| `OMARCHY_SCREENSAVER_EFFECT` | `print` | 使う ttfx エフェクト。`wipe` / `slide` / `expand` / `middleout` / `sweep` / `highlight` も軽い |
| `OMARCHY_SCREENSAVER_FRAME_RATE` | `60` | フレームレート |

## 日本語入力 (IME / fcitx5)

IME は Omarchy 既定の fcitx5 + Hyprland に任せ, **単一のグローバル状態**で運用する。
アプリ / ウィンドウ単位の状態保持は行わない。

- Hyprland は IME 連携に `zwp_input_method_v2` を使う。この経路では fcitx5 から
  見える入力コンテキストが常に 1 つで, IME の ON/OFF 状態は**グローバル**になる。
  したがって「アプリごとに入力状態を記憶する」ことは原理的にできない。これを
  再現しようとする常駐スクリプト (旧 `hypr-fcitx-sync`) は, web app の window class
  が URL 由来で不安定なこともあり破綻する (特定アプリが英語に固定される等) ため
  撤去した。
- IME の切替は `hypr/bindings.lua` の `CTRL + SPACE` (`fcitx5-remote -t`) で行う。
  Hyprland では fcitx5 がトリガキーを直接受け取れないため, compositor 側で叩く。
- 環境変数 (`INPUT_METHOD` / `QT_IM_MODULE` / `XMODIFIERS` / `SDL_IM_MODULE`) は
  Omarchy 既定 (`default/environment.d/10-omarchy-fcitx.conf`) に任せる。fcitx5 は
  同梱の systemd ユーザーサービス `omarchy-fcitx5.service` が起動する。
- Chromium 系は `omarchy/.config/chromium-flags.conf` で `--enable-wayland-ime` を
  指定する。`GTK_IM_MODULE` を設定しない構成のため, これが無いと日本語入力できない。
- Ghostty は GTK4 のネイティブ Wayland text-input 経路で入力する (旧ラッパー不要)。

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
