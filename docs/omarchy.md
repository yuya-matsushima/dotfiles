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
| `omarchy/.config/obsidian/user-flags.conf` | Obsidian (Arch パッケージ) の起動フラグ (`--enable-wayland-ime`) |
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
- IME の切替は `hypr/bindings.lua` の `CTRL + SPACE` で行う。実体は
  `~/.local/bin/ime-toggle` (リポジトリ管理, `bin/link.sh` で symlink) で, current IM を
  `mozc` <-> `keyboard-us` に**明示的に切り替える**。Hyprland では fcitx5 がトリガキーを
  直接受け取れないため compositor 側で叩く。
- 従来の `fcitx5-remote -t` (active/inactive トグル) は, keyboard-us を current IM にした
  状態では mozc に戻れず, mozc が「直接入力」に取り残されて変換が効かなくなることが
  あった (表示は「あ」のまま英語が入力される症状)。`ime-toggle` による IM 切替で
  状態遷移を一意にしこれを防ぐ。それでも変換が効かない場合は `CTRL + SPACE` を
  押し直すか `fcitx5-remote -r` で fcitx5 を再読込する。
- 内蔵 JIS キーボードの **英数 / かな** キーは `hypr/bindings.lua` で compositor が消費し,
  英数 → `fcitx5-remote -s keyboard-us`, かな → `fcitx5-remote -s mozc` に固定する
  (macOS と同じ「押せば必ずその状態」)。jp layout ではそれぞれ keysym `Hangul_Hanja` /
  `Hangul` になる。これらのキーが mozc に届くと mozc 内部で「直接入力」へ遷移し,
  fcitx5 側は mozc 有効 (`fcitx5-remote` = 2) のまま英字しか入らなくなっていた。
  なお Lua の `o.bind` は `code:130` 形式の keycode 指定を解釈しない (keycode 0 になる)。
- macOS (`.hammerspoon/init.lua`) と同じく **cmd (= `SUPER`) の単押し** でも IME をトグルする。
  `hypr/bindings.lua` で `Super_L` / `Super_R` に release バインド (`{ release = true }`) を張り
  `ime-toggle` を呼ぶ。`SUPER` を押している間に他のキーが押されると発火しないため,
  `SUPER + 1` 等や `SUPER` + ドラッグとは共存する (誤発火しないことを確認済み)。
- mozc が「直接入力」に残ったときの保険として, mozc のキー設定
  (`fcitx5-configtool` → mozc → プロパティ → キー設定) で「直接入力 →
  ひらがな」に戻すキーを任意の組み合わせで割り当てられる。ただし
  `CTRL + SPACE` は Hyprland が消費するため mozc 側には割り当てられない。
- IM 構成 (`~/.config/fcitx5/profile`: `keyboard-us` + `mozc`, 既定 IM は mozc) は
  `omarchy/.config/fcitx5/profile` をテンプレートとして `make omarchy`
  (`bin/omarchy/fcitx5.sh`) が配置する。fcitx5 は終了時に profile を書き戻すため
  symlink にはせず, mozc 未登録の場合だけコピーする (既存は `*.bak.<timestamp>` へ退避)。
- 環境変数 (`INPUT_METHOD` / `QT_IM_MODULE` / `XMODIFIERS` / `SDL_IM_MODULE`) は
  Omarchy 既定 (`default/environment.d/10-omarchy-fcitx.conf`) に任せる。fcitx5 は
  同梱の systemd ユーザーサービス `omarchy-fcitx5.service` が起動する。
- Chromium 系は `omarchy/.config/chromium-flags.conf` で `--enable-wayland-ime` を
  指定する。`GTK_IM_MODULE` を設定しない構成のため, これが無いと日本語入力できない。
- Obsidian (Electron) も同様に `omarchy/.config/obsidian/user-flags.conf` で
  `--enable-wayland-ime` を指定する (Arch パッケージのラッパーが読む)。以前入れていた
  `-disable-gpu` は MacBookPro16,2 (Intel Iris Plus, i915) では不要と確認したため外した。
- fcitx5 を再起動した場合, 起動中の Chromium は IME 接続が復帰しないことがあるため
  Chromium も再起動する。
- Ghostty は GTK4 のネイティブ Wayland text-input 経路で入力する (旧ラッパー不要)。

## 無効化している Omarchy 既定キーバインド

`hypr/bindings.lua` で `hl.unbind` しているもの。復活させる場合は該当行を削除して
`hyprctl reload` する。

| キー | Omarchy 既定の動作 | 無効化の理由 |
| --- | --- | --- |
| `SUPER + SHIFT + SPACE` | Toggle top bar (`omarchy-toggle-bar`) | IME 切替の `CTRL + SPACE` と押し方が近く誤爆しやすい。誤爆で `~/.local/state/omarchy/toggles/bar-off` が立ち, バーが画面外 (y = -26) に隠れたままになった |
| `SUPER + /` / `SUPER + ALT + /` | Monitor scaling up / down (`omarchy-hyprland-monitor-scaling`) | 誤爆で画面全体の scale が変わっていた (1 秒間に 5 回 down した記録あり)。アプリ内ズーム (`CTRL + +/-`) は別機能のため影響なし。一時的に変える場合は `omarchy-hyprland-monitor-scaling up\|down` を直接実行する |

バーの表示を手動で切り替える場合は `omarchy-toggle-bar off` (表示) /
`omarchy-toggle-bar on` (非表示) を使う。フラグ名が `bar-off` のため `on` が「非表示」に
なる点に注意。

## T2 MacBook トラックパッドの二本指タップが反応しない / 遅い

MacBookPro16,2 (T2) で「二本指タップ (右クリック) でブラウザのメニューが出るのが遅い / 軽いタッチだと出ない」場合。

### 切り分け

- 1 本指タップは正常 / 二本指クリック (物理押し込み) は確実に動く → タップ認識の問題
- **原因**: T2 の内蔵トラックパッドは HID レベルで `magicmouse` ドライバが処理する
  (Magic Trackpad 2 と同じプロトコル)。しかし libinput の Apple クォーク
  (`/usr/share/libinput/50-system-apple.quirks`) では旧世代 MacBook 用の
  `[Apple Touchpads USB]` (`AttrTouchSizeRange=150:130`) が適用され, 軽いタッチの
  接触サイズが閾値に届かずタップとして認識されない。
- `hyprctl devices` でトラックパッドが `touch` ではなく `mice` に表示されるのは正常。

### 修正

`/etc/libinput/local-overrides.quirks` を作成し, このデバイスだけ
Magic Trackpad v2 相当の緩い閾値にする。

```sh
# 1) オーバーライド作成
sudo tee /etc/libinput/local-overrides.quirks > /dev/null <<'EOF'
[Apple T2 Internal Trackpad override]
MatchBus=usb
MatchVendor=0x05AC
MatchProduct=0x027E
MatchUdevType=touchpad
AttrTouchSizeRange=20:10
AttrPalmSizeThreshold=900
AttrThumbSizeThreshold=800
EOF

# 2) 反映 (デバイスの再列挙 or 再ログイン / Hyprland 再起動)
sudo udevadm trigger
```

反映後は再ログインまたは `omarchy restart hyprland` 相当で libinput がクォークを
再読み込みする。

- 効果が薄い場合は実測して調整する: `sudo libinput measure touchpad-size /dev/input/event7`
  (`libinput-tools` 導入が必要)。
- 変更は `/etc` 配下のマシン固有設定のため, dotfiles リポジトリには含めない。

## 外付け英語キーボード (HHKB / Keychron) の US レイアウト

日本語キーボード (JIS) の MacBook で外付けの英語配列キーボードを接続した場合、
Omarchy のグローバル設定は `jp` のままなので、外付けキーボードにそのまま
`jp` が適用されキーがずれる。

`hypr/input.lua` でデバイス別に `us` レイアウトを適用する (内蔵 JIS キーボードは
`jp` のまま)。

```lua
-- デバイス名は `hyprctl devices` の出力 (小文字化された libinput 名)。
-- IMPORTANT: Hyprland の hl.device は EXACT マッチ (部分一致・正規表現不可)。
-- 接続してデバイス名を確認し、1 エントリずつ追加する。
hl.device({ name = "topre-corporation-hhkb-professional", kb_layout = "us" })

-- HHKB Hybrid / Keychron は HID インターフェースが複数に分かれるため全部登録。
hl.device({ name = "pfu-limited-hhkb-hybrid-keyboard", kb_layout = "us" })
hl.device({ name = "pfu-limited-hhkb-hybrid-consumer-control", kb_layout = "us" })
hl.device({ name = "pfu-limited-hhkb-hybrid", kb_layout = "us" })
hl.device({ name = "keychron-keychron-q11-keyboard", kb_layout = "us" })
hl.device({ name = "keychron-keychron-q11-consumer-control", kb_layout = "us" })
hl.device({ name = "keychron-keychron-q11-system-control", kb_layout = "us" })
hl.device({ name = "keychron-keychron-q11", kb_layout = "us" })
```

- 反映: 保存で自動再読み込み、または `hyprctl reload`。確認は
  `hyprctl devices` の `layout` / `active_keymap`。
- 新しい外付けキーボードを追加する場合は `hyprctl devices` で名前を確認して
  設定を追記する (**部分一致は不可。完全一致のみ**)。
- per-device レイアウトは既定ではキーバインドのキーマップを変更しない
  (キーバインドはグローバルの `jp` のまま解決される)。シンボル解決に切り替える
  場合は `resolve_binds_by_sym = 1` を参照 (Hyprland wiki: Devices)。

## 外部ディスプレイ構成 (monitors.lua)

`~/.config/hypr/monitors.lua` はリポジトリの `.config/hypr/monitors.lua` に symlink され、
`bin/link.sh` で Linux 専用ターゲットとして管理される。

- 外部ディスプレイ接続時: 外部 (DP-3) を上 (Display 1)、内蔵 (eDP-1) を下 (Display 2) に縦配置
- SUPER+1..5 = 外部 / SUPER+6..0 = 内蔵 (workspace_rule で固定)
- Mac 単体時: 内蔵のみ
- 接続検知は `o.shell_succeeds("omarchy hw external monitors")` で設定読み込み時に行う。
  起動後に外部を抜き挿しした場合は `hyprctl reload` で反映する。

注意: `hl.workspace_rule` の selectors は**既存ワークスペースにのみマッチ**するため、
範囲指定 (`workspace = "1-5"`) は無効で、1 つずつ `workspace = "1"` のように列挙する
必要がある。設定変更前に存在するワークスペースには適用されない (再起動で有効)。

注意: scale 用の変数名を Omarchy 既定の `omarchy_monitor_scale` / `omarchy_gdk_scale` に
しない。`omarchy-hyprland-monitor-scaling` (`SUPER + /` / `SUPER + ALT + /`) はこの行を
見つけると `sed -i` で値を書き換え, symlink を実体ファイルに置き換えてしまう
(実際に誤爆で `GDK_SCALE` 2 → 1, 外部 4/3 → 1.25 に書き換わった)。別名にしているため
ショートカットでの scale 変更はその場限りで, `hyprctl reload` で本ファイルの値に戻る。

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
