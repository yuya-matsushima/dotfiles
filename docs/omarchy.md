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
4. `make omarchy_hex` : Hex の導入と dictation バックエンドの選択

## Omarchy 4.5 への更新 (4.0.6 → 4.5.0rc3)

`omarchy-channel-set rc` (または `omarchy channel set rc`) で rc チャンネルへ切り替えると
`omarchy` / `omarchy-settings` が 4.5.0rc3 になり, 続けて `omarchy update` が走る。
4.1〜4.4 は存在せず, 4.0.6 からの直接更新になる。

更新時に知っておくこと:

- **キーバインドが移動した**: 電卓 `SUPER + SHIFT + Q`, Activity `SUPER + SHIFT + T`,
  ネットワーク `SUPER + CTRL + N`, 通知系は `SUPER + ,` が「最新の通知に作用」に変更。
  ナイトライトのショートカットは廃止され Trigger > Toggle へ。
- **モニターごとのワークスペース**: `SUPER + 1〜0` はフォーカス中モニターの 1〜10 を選ぶ。
  4.0.x 用の `workspace_rule` によるモニター固定は競合するため削除した (`hypr/monitors.lua`)。
- **dictation がバックエンド方式に**: migration は既存ユーザーを Voxtype のまま残すので,
  Hex を使うには `omarchy dictation use hex` を実行する (`make omarchy` でも切り替わる)。
- **mise の既定ツール**: `gh` / AI CLI は `/etc/mise/conf.d/omarchy-tools.toml` が宣言する。
  migration が `omarchy/.config/mise/config.toml` から `= "latest"` を削除する。
- **Chromium 系**: migration が `--enable-features` に `OverlayScrollbar` を追加する。
- `hypr/bindings.lua` の 4.0.x 向け dictation フォールバックは, stable へ戻す場合に備えて
  残している (4.5 では実行されない)。

## シェルプラグイン (`omarchy/plugins.txt`)

`make omarchy` は `bin/omarchy/plugins.sh` も実行し, `omarchy/plugins.txt` に
列挙した Omarchy シェルプラグインを導入・有効化します。既に有効なプラグインは
そのまま残すため, 何度実行しても安全です。プラグインだけ反映するときは
`make omarchy_plugins` を使います。

書式:

```
<plugin-id> <git-url> [placement]
```

`placement` (`left` / `center` / `right`) は新規導入時と無効からの復帰時だけ
適用し, 既に有効なバーウィジェットの位置は動かしません。

| プラグイン | 役割 |
|---|---|
| `io.github.thomasvanholder.opencode-agents` | 組み込み Agents パネルに OpenCode Go の利用枠 (5h / weekly / monthly) とトークン統計を追加 |
| `io.github.sirjul1337.lock-explorer` | ロック画面のデザイン選択。`omarchy.lock` を置き換える |
| `markpriem.keystrokes` | KeyCastr 代替。押したキーを keycap として表示 |

4.5 でも `omarchy plugin add [url] [--enable] [--yes]` / `enable <id> [placement]` /
`list [--json]` のインターフェースは変わっていない。`sh bin/omarchy/plugins.sh` を
再実行し, 3 件とも `already enabled` で exit 0 になることを確認済み
(4.5 で `update` / `clone` / `validate` が追加されたが, 本スクリプトでは使わない)。

### Lock Screen Explorer

`omarchy-shell lock explore` でデザインを選択できます。負荷を抑えたい場合は
Settings の Reduce motion を `On` または `On battery` にします (この環境では
`omarchy-shell lock setReduceMotion battery` を設定済み)。動画系デザインは
`qt6-multimedia` が必要で, 未導入なら Classic にフォールバックします。
標準のロック画面に戻すときはプラグインを削除し, `omarchy.lock` を有効化します。

```sh
omarchy plugin remove io.github.sirjul1337.lock-explorer
omarchy plugin enable omarchy.lock
```

### Keystrokes

`omarchy/.config/hypr/bindings.lua` が, プラグインが存在するときだけ
`hypr/keystrokes.lua` を読み込みます。`SUPER + SHIFT + K` でキャプチャを
トグルし, バーのキーボードアイコンから設定を開けます。初回は `make link` の後に
`hyprctl reload` を実行して binding を反映してください。

設定は `~/.config/omarchy/keystrokes.json` (端末固有, dotfiles 管理外) に保存されます。
KeyCastr のように全キーを出す場合は `combosOnly` を `false`, 修飾キー単体も出す場合は
`modifiersAlone` を `true` にします。sudo / polkit の入力中は自動で停止しますが,
画面共有や録画の前には秘密情報を入力しないよう注意してください。

## CLI ツール (`bin/omarchy/cli.sh`)

macOS 側 `bin/homebrew/cli.sh` で導入している CLI ツールのうち, omarchy で使うものを
Arch パッケージとして導入します。パッケージ名は Arch 側に読み替えています。

omarchy base (`/usr/share/omarchy/install/omarchy-base.packages`) が既に導入する
パッケージ (`bat` / `eza` / `fd` / `fzf` / `imagemagick` / `jq` / `neovim` /
`postgresql-libs` / `qrencode` / `ripgrep` / `tmux` / `tree-sitter-cli` / `zoxide` など)
は二重管理を避けるため含めません。

4.5 の base (`omarchy-base.packages` / `omarchy-other.packages` など) と
`bin/omarchy/cli.sh` の導入リストを突き合わせ, 重複は 0 件でした
(`base-devel` / `ffmpeg` / `qt6-*` / `vi` / `fcitx5-mozc` は base 側にあり,
cli.sh には含めていません)。

その他の除外:

- `git` / `curl` / `make` / `grep` / `ncurses` などは base や base-devel で導入済み。
- `mise` は omarchy の `mise-bin`。`gh` / `opencode` / `uv` と AI CLI (`claude` / `codex` / `copilot` / `pi`) は Omarchy 4.5 以降 `/etc/mise/conf.d/omarchy-tools.toml` が宣言するため、`omarchy/.config/mise/config.toml` には書かない (4.5 の migration がユーザー設定側の `= "latest"` を削除する)。`github-copilot-cli-bin` も mise の `copilot` と重複するため AUR から外した。
- `direnv` は mise で代替するため含めません。
- `htop` / `mariadb-clients` (`mysql-client` 相当) は未使用のため含めません。
- `pngpaste` / `font-symbols-only-nerd-font` など macOS 専用ツールは含めません。
- 公式リポジトリに無いツール (`diff-pdf-git`) は AUR から
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
| `omarchy/.config/mise/config.toml` | Linux 用 mise 設定。`gh` / AI CLI は Omarchy が `/etc/mise/conf.d/omarchy-tools.toml` で宣言するためここには書かない |
| `omarchy/.config/chromium-flags.conf` | Chromium の起動フラグ (上流 config の全置換) |
| `omarchy/.pi/agent/settings.json` | Linux のみ (`theme: omarchy-system` を含む) |
| `.config/nvim` | macOS / Linux 共通 (独自 lazy.nvim 構成) |
| `.config/opencode` | Linux のみ (macOS では link しない) |
| `.pi/agent/*` | Linux のみ (macOS では link しない) |

macOS 専用ターゲット (`.hammerspoon`, `.gvimrc`) は Linux では link しません。
逆に `.config/opencode` と `.pi/agent/*` は macOS では使わないため, `bin/link.sh` が
link を skip します (`make unlink` では残存リンクを掃除します)。
`.config/ghostty` も macOS 専用です。Linux では Omarchy 既定の foot を使うため,
`bin/link.sh` が link を skip します。

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

4.5 でも `/usr/bin/omarchy-screensaver` は `--random-effect --frame-rate 120` の
ままで, エフェクトを選ぶ公式オプションも追加されていないため, この上書きと PATH
調整は維持する (確認: `command -v omarchy-screensaver` が
`~/.local/bin/omarchy-screensaver` を返し, Hyprland 起動プロセスの PATH に
`/usr/share/omarchy/bin` は含まれない)。キー入力のエコーを消す `stty -echo` は
上流の修正に追従した。

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
- IME の切替はすべて `hypr/bindings.lua` で compositor 側から行う (かな / 英数キー,
  `SUPER` 単押し)。トグルの実体は `~/.local/bin/ime-toggle` (リポジトリ管理,
  `bin/link.sh` で symlink) で, current IM を `mozc` <-> `keyboard-us` に
  **明示的に切り替える**。
- `CTRL + SPACE` は IME 切替に使わず, アプリ (nvim の `<C-Space>` 補完等) に渡す。
  Omarchy 4.5 の `omarchy-input-method configure --defaults` は
  `default/input-methods/configure.py` の `without_ctrl_space` で `Control+space` を
  トリガキーから除去するが, 代わりに `Zenkaku_Hankaku` (半角/全角) と `Hangul` を
  残す。`Hangul` は Hyprland の かな バインドが消費するものの, `Zenkaku_Hankaku` は
  未バインドで fcitx5 自身の active/inactive トグルが走り, `ime-toggle` の IM 切替と
  状態が食い違う。そのため `~/.config/fcitx5/config` の `[Hotkey/TriggerKeys]` は
  空に揃える (`make omarchy` の `bin/omarchy/fcitx5.sh` がキー行を削除して冪等に実行)。
- 従来の `fcitx5-remote -t` (active/inactive トグル) は, keyboard-us を current IM にした
  状態では mozc に戻れず, mozc が「直接入力」に取り残されて変換が効かなくなることが
  あった (表示は「あ」のまま英語が入力される症状)。`ime-toggle` による IM 切替で
  状態遷移を一意にしこれを防ぐ。それでも変換が効かない場合は `SUPER` 単押し / かなキーを
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
  ひらがな」に戻すキーを任意の組み合わせで割り当てられる。
- IM 構成 (`~/.config/fcitx5/profile`: `keyboard-us` + `mozc`, 既定 IM は mozc) は
  `omarchy/.config/fcitx5/profile` をテンプレートとして `make omarchy`
  (`bin/omarchy/fcitx5.sh`) が配置する。fcitx5 は終了時に profile を書き戻すため
  symlink にはせず, mozc 未登録の場合だけコピーする (既存は `*.bak.<timestamp>` へ退避)。
- 環境変数 (`INPUT_METHOD` / `QT_IM_MODULE` / `XMODIFIERS` / `SDL_IM_MODULE`) は
  Omarchy 既定 (`default/environment.d/10-omarchy-fcitx.conf`) に任せる。fcitx5 は
  同梱の systemd ユーザーサービス `omarchy-fcitx5.service` が起動する。
- Chromium 系の起動フラグは `omarchy/.config/chromium-flags.conf` (`make link` で
  `~/.config/chromium-flags.conf` に symlink) で管理する。Chromium は drop-in
  ディレクトリを持たないため上流 `/usr/share/omarchy/config/chromium-flags.conf` の
  全置換になり, 上流が更新されたら (`omarchy-refresh-chromium` の内容に) 追従する。
  4.5 / Chromium 155 は Wayland IME (text-input-v3) が既定で有効なため
  `--enable-wayland-ime` は指定しない。`--force-device-scale-factor=1` だけは
  HiDPI (scale 5/3, 4/3) での見え方を実機確認するまで残している。
- Obsidian (Electron 43 = Chromium 150) は Omarchy 既定の
  `ELECTRON_OZONE_PLATFORM_HINT=wayland` (`hypr/envs.lua`) で Wayland ネイティブに
  動く。Wayland IME (text-input-v3) は Chromium M137 以降 既定で有効なため,
  Omarchy が同梱する `~/.config/obsidian/user-flags.conf`
  (`--enable-wayland-ime` + `-disable-gpu`) は置かない。`-disable-gpu` は
  MacBookPro16,2 (Intel Iris Plus, i915) では不要と確認済み。
- fcitx5 を再起動した場合, 起動中の Chromium は IME 接続が復帰しないことがあるため
  Chromium も再起動する。

## キーバインド (よく使うもの)

`hypr/bindings.lua` (Omarchy 既定 + 自前の上書き) で有効なもの。全一覧は
`SUPER + K` または `omarchy menu keybindings --print` で確認できる。
`SUPER` は macOS の Command に相当する。

### まず覚える 3 つ

| キー | 動作 |
| --- | --- |
| `SUPER + SPACE` | Omarchy メニュー (ここからほぼ全部たどれる) |
| `SUPER ALT + SPACE` | dock のアプリ一覧 (4.5 以降) |
| `SUPER + K` | キーバインド一覧 |

### ウィンドウ

| キー | 動作 |
| --- | --- |
| `SUPER + W` / `CTRL ALT + DELETE` | 閉じる / 全ウィンドウを閉じる |
| `SUPER + F` | フルスクリーン |
| `SUPER ALT + F` | 全幅表示 |
| `SUPER CTRL + F` | タイル内フルスクリーン |
| `SUPER + T` | フローティング / タイル切替 |
| `SUPER + J` / `SUPER + P` | 分割 (split) 切替 / 疑似ウィンドウ (pseudo tile) |
| `SUPER + O` | ポップアウト (float + pin) |
| `SUPER + L` | ワークスペースレイアウト切替 |
| `SUPER + BACKSPACE` | ウィンドウ透過切替 |
| `SUPER + Home` / `SUPER ALT + Home` | ウィンドウ幅の復元 / 保存 |
| `SUPER CTRL + BACKSPACE` | 単一ウィンドウを正方形アスペクトに |
| `SUPER + S` / `SUPER ALT + S` | スクラッチパッド表示切替 / ウィンドウをスクラッチパッドへ |

### フォーカスと移動

| キー | 動作 |
| --- | --- |
| `SUPER + 矢印` | 上下左右のウィンドウへフォーカス |
| `ALT + TAB` / `SHIFT ALT + TAB` | 次 / 前のウィンドウ |
| `CTRL ALT + TAB` / `SHIFT CTRL ALT + TAB` | 次 / 前のモニタ |
| `SUPER SHIFT + 矢印` | ウィンドウをその方向へスワップ |
| `SUPER + 左ドラッグ` / `SUPER + 右ドラッグ` | ウィンドウ移動 / リサイズ |
| `SUPER CTRL + ←/→` | グループ内のフォーカス移動 |
| `SUPER ALT + ホイール↑` / `SUPER SHIFT ALT + TAB` | グループ内の前のウィンドウ |

### リサイズ (キーボード)

| キー | 動作 |
| --- | --- |
| `SUPER + -` / `SUPER + =` | 左へ広げる / 左を縮める |
| `SUPER SHIFT + =` / `SUPER SHIFT + -` | 下へ広げる / 上を縮める |
| 上記 + `ALT` / 上記 + `CTRL` | 少しだけ (a little) / 大きく (a lot) |

### ワークスペース

| キー | 動作 |
| --- | --- |
| `SUPER + 1〜0` | フォーカス中モニターのスロット 1〜10 へ (0 = 10) |
| `SUPER + TAB` / `SUPER SHIFT + TAB` | 同じモニター内で次 / 前のワークスペース |
| `SUPER CTRL + TAB` | そのモニターで直前にいたワークスペースへ |
| `SUPER + ホイール↓/↑` | 同じモニター内で前 / 後ろへスクロール切替 |
| `SUPER SHIFT + 1〜0` | ウィンドウをそのスロットへ移動 |
| `SUPER SHIFT ALT + 1〜0` | フォーカスを追従させずに移動 |
| `SUPER SHIFT ALT + 矢印` | ワークスペースごと隣のモニターへ移動 |
| `SUPER SHIFT CTRL + 矢印` | ウィンドウだけ隣のモニターへ移動 |
| `SUPER + L` / `SUPER ALT + L` | レイアウト (dwindle / scrolling / floating) を次 / 前へ |
| `SUPER + M` | ウィンドウを dock へ最小化 |

Omarchy 4.5 以降は**モニターごとに 1-10 のワークスペース**を持つ。番号は内部的にグローバル (内蔵 1-10、次のモニター 11-20) だが、バーは各モニターの 1-10 を表示し、`SUPER + 1〜0` はフォーカス中のモニターのスロットを選ぶ (`default/hypr/monitor-workspaces.lua`)。

### アプリ起動・メニュー

| キー | 動作 |
| --- | --- |
| `SUPER + RETURN` | ターミナル |
| `SUPER SHIFT + RETURN` / `SUPER + B` | ブラウザ |
| `SUPER SHIFT ALT + B` | ブラウザ (プライベート) |
| `SUPER SHIFT + F` / `SUPER SHIFT ALT + F` | ファイルマネージャ / カレントディレクトリで開く |
| `SUPER + ESCAPE` / `XF86PowerOff` | システムメニュー (ロック・再起動など) |
| `SUPER CTRL + C` | キャプチャメニュー |
| `SUPER CTRL + ALT + C` | スクリーンショット (4.5 以降) |
| `SUPER CTRL + 1〜9` | バーパネル 1〜9 |
| `SUPER ALT + K` / `SUPER CTRL + K` | Tmux / Herdr |
| `XF86Calculator` / `SUPER SHIFT + Q` | 電卓 |
| `SUPER CTRL + T` / `SUPER CTRL + W` | テーマ / 背景 (4.5 以降) |
| `SUPER SHIFT + T` | Activity (4.5 で `Ctrl+T` から移動) |
| `SUPER CTRL + ALT + E` | 世界時計 (Elsewhen, 4.5 以降) |
| `SUPER + grave` / `SUPER SHIFT + grave` | Quake 端末の表示切替 / ウィンドウを送る (4.5 以降) |
| `SUPER CTRL + ALT + F` | フルスクリーンデスクトップの切替 (4.5 以降) |
| `SUPER + Q` / `SUPER + A` | ウィンドウを閉じる / 全選択 (4.5 以降) |

### クリップボード・スクリーンショット

| キー | 動作 |
| --- | --- |
| `SUPER C` / `SUPER V` / `SUPER X` | コピー / ペースト / カット (universal。ターミナルでも GUI と同じ感覚で効く) |
| `SUPER CTRL + V` | クリップボード履歴 |
| `SUPER CTRL + E` | 絵文字 |
| `PRINT` / `ALT + PRINT` | スクリーンショット / 画面録画 |
| `SUPER CTRL + PRINT` | スクショから OCR (文字抽出) |
| `SUPER + PRINT` | カラーピッカー |

### 通知・音量・明るさ

| キー | 動作 |
| --- | --- |
| `SUPER + ,` | 最新の通知を消す / 開く / ボタンを押す (4.5 以降) |
| `SUPER SHIFT + ,` | 通知をすべて消す |
| `SUPER ALT + ,` | 最後の通知を消す (4.5 以降。以前は「開く」) |
| `SUPER CTRL + ,` | 通知をキーボードで操作 (4.5 以降) |
| `SUPER CTRL + ALT + ,` | 通知のミュート切替 (4.5 以降。以前は `Ctrl+,`) |
| `SUPER SHIFT ALT + ,` | 通知履歴 |
| `XF86AudioRaiseVolume` / `XF86AudioLowerVolume` | 音量 上下 (ALT 併用で微調整) |
| `XF86AudioMute` / `XF86AudioMicMute` | スピーカー / マイクのミュート |
| `SHIFT + XF86AudioMute` | 音声出力の切替 |
| `XF86MonBrightnessUp` / `XF86MonBrightnessDown` | 明るさ 上下 (ALT 併用で微調整, SHIFT 併用で最大 / 最小) |
| `XF86KbdBrightnessUp` / `XF86KbdBrightnessDown` | キーボードバックライト |
| `XF86AudioPlay` / `XF86AudioNext` / `XF86AudioPrev` | 再生 / 次 / 前の曲 |

### この環境固有 (IME / 音声入力 / 表示)

| キー | 動作 |
| --- | --- |
| `SUPER` 単押し (左右どちらでも) | IME トグル (macOS の Command 単押しと同じ) |
| `かな` / `英数` | IME を mozc / keyboard-us へ明示切替 |
| 右 `Alt` 押しっぱなし / `F9` / 右 `Shift` 押しっぱなし | 音声入力 (Hex, push-to-talk) |
| `SUPER SHIFT + K` | 押したキーを画面に表示 (Keystrokes) |
| `SUPER CTRL + L` | 画面ロック |
| `SUPER CTRL + I` | アイドル時ロックの切替 |
| `SUPER + I` / `SUPER SHIFT + I` | 入力言語の切替 / 戻す (Omarchy 4.5 の `omarchy-input-method cycle`) |
| `SUPER CTRL + N` | ネットワーク (4.5 以降。ナイトライトは Trigger > Toggle へ移動) |
| `SUPER CTRL + Delete` | ラップトップ画面の切替 |
| `SUPER ALT + BRACKETLEFT` / `SUPER ALT + BRACKETRIGHT` | ウェブカメラオーバーレイの縮小 / 拡大 |

## 無効化・差し替えしている設定

`hypr/bindings.lua` で `hl.unbind` しているもの。復活させる場合は該当行を削除して
`hyprctl reload` する。`omarchy_default_bindings = false` や
`omarchy_preinstalled_bindings = false` は使っておらず, 既定の上に最小限の
unbind / 再 bind だけを重ねている。

### 無効化しているキーバインド

| キー | Omarchy 既定の動作 | 無効化の理由 | 代替手段 |
| --- | --- | --- | --- |
| `SUPER + SHIFT + SPACE` | Toggle top bar (`omarchy-toggle-bar`) | 当時 IME 切替に使っていた `CTRL + SPACE` と押し方が近く誤爆しやすい。誤爆で `~/.local/state/omarchy/toggles/bar-off` が立ち, バーが画面外 (y = -26) に隠れたままになった | `omarchy-toggle-bar off` (表示) / `on` (非表示) を直接実行する。フラグ名が `bar-off` のため `on` が「非表示」になる点に注意 |
| `SUPER + /` | Monitor scaling up (`omarchy-hyprland-monitor-scaling`) | 誤爆で画面全体の scale が変わっていた (1 秒間に 5 回 down した記録あり)。アプリ内ズーム (`CTRL + +/-`) は別機能のため影響なし | `omarchy-hyprland-monitor-scaling up` を直接実行する |
| `SUPER + ALT + /` | Monitor scaling down (`omarchy-hyprland-monitor-scaling`) | 上と同じ | `omarchy-hyprland-monitor-scaling down` を直接実行する |

4.5 でも既定の `SUPER + SHIFT + SPACE` (`bind_toggle` bar, `bindings/utilities.lua`) と
`SUPER + SLASH` / `SUPER + ALT + SLASH` (monitor scaling, `bindings/tiling.lua`) は
残っているため, `hl.unbind` は 3 件とも維持する。`hyprctl reload` 後に
`hyprctl binds` で該当する description (`Toggle top bar` / `Monitor scaling`) が
消えていることを確認済み。

### 差し替えているキーバインド

既定の動作を unbind したうえで, 別の動作を割り当てているもの。

| キー | 元の動作 | 現在の動作 | 備考 |
| --- | --- | --- | --- |
| `Shift_R` / `SHIFT + Shift_R` | Shift (修飾キー) | 右 Shift 単押しで音声入力の push-to-talk (`Hex`) | JIS 配列に右 Alt が無いため追加。`non_consuming` のため Shift キーとしての文字入力は維持される。他の修飾キーを押している間は発火しない |

`SUPER + CTRL + X` / `F9` / `ALT + Alt_R` は Omarchy 4.5 では既定の dictation バインド
(`default/hypr/bindings/dictation.lua`) がそのまま張る。選択中のバックエンドが Hex なら
そのまま Hex が動くため, `hypr/bindings.lua` 側での差し替えは 4.0.x のみ。

バーの表示を手動で切り替える場合は `omarchy-toggle-bar off` (表示) /
`omarchy-toggle-bar on` (非表示) を使う。フラグ名が `bar-off` のため `on` が「非表示」に
なる点に注意。

## T2 音声 (内蔵スピーカーのブチブチ)

`t2bce_audio` はスピーカー (`hw:0,0`, 4ch) とヘッドホン (`hw:0,2`, 2ch) を別 PCM で公開する。
以前は `~/.config/wireplumber/wireplumber.conf.d/t2-audio.conf` で
`api.alsa.split-enable = false` と `session.suspend-timeout-seconds = 0` を T2 の PCM に
当てていた (ヘッドホン抜き差し後にスピーカーが無音になる問題への対策)。

しかしこの構成では**内蔵スピーカーの再生にブチブチというノイズが乗る**。
`suspend=0` の出力 PCM は `t2bce_audio` の再生位置をリセットできず、入力にも当てると
マイク PCM が常時オープンになってコーデックが全二重で動くため。PipeWire 既定の split
経路と idle suspend に戻すと解消するので、`t2-audio.conf` は削除した。

`~/.config/pipewire/pipewire.conf.d/10-t2-larger-quantum.conf` (quantum を 1024 に
固定する drop-in) も削除した。これは split を無効化した構成で 4ch スピーカーが
既定の 256 サンプルで underrun していたための対策だった。split 既定に戻した後は
`clock.force-quantum` を 256 にしても `pw-top` の ERR は 0 のまま (4ch 再生中に
約 13 秒計測)。PipeWire 1.6.9 の既定 quantum は 1024 なので、固定を外しても
通常再生のバッファ長は変わらない。

- 3.5mm ジャックを抜いたあとにスピーカーが無音になる症状が再発した場合は,
  `systemctl --user restart wireplumber` で復帰する。恒久的に split を無効化しない
- マイクや出力の PCM を `session.suspend-timeout-seconds = 0` で開きっぱなしにしない

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

`~/.config/hypr/monitors.lua` はリポジトリの `omarchy/.config/hypr/monitors.lua` に symlink され、
`bin/link.sh` で Linux 専用ターゲットとして管理される。

- 外部ディスプレイ (DP-3) を上 (Display 1)、内蔵 (eDP-1) を下 (Display 2) に縦配置
- 配置ルールは接続状態にかかわらず常に宣言する。Hyprland は未接続出力のルールを
  保持し、接続時に自動適用するため、起動後に外部を抜き挿ししても画面順は崩れない
- ワークスペースはモニターへ固定しない。Omarchy 4.5 以降は各モニターが 1-10 を
  持ち (`default/hypr/monitor-workspaces.lua`)、`SUPER+1..0` はフォーカス中の
  モニターのスロットを選ぶ。4.0.x 向けの `workspace_rule` 固定は 4.5 の
  ブロック割り当てと競合するため削除した
- 長時間サスペンドからの復帰後に外部が認識されない場合に備え、
  `omarchy-hyprland-monitor-resume` がログイン時に常駐し、復帰時に必要なら
  `hyprctl reload` でモニター状態を再適用する
  (手動実行: `omarchy-hyprland-monitor-resume --now`)。4.5 にも
  systemd-sleep / `PrepareForSleep` を使ったモニター復旧フックは無く
  (`system-sleep` は fprintd / force-igpu のみ, `omarchy-system-sleep-monitor` は
  ロック専用), `omarchy-hyprland-monitor-watch` も socket イベント起点のため
  復帰時には何も起きない。この常駐スクリプトは引き続き必要
  (確認: `--now` は外部接続済み・有効時に何もせず exit 0)。

## 1Password の SSH 承認ダイアログ

`ssh` などで 1Password の SSH キーを使うと「1Password アクセスリクエスト」
ダイアログが開く。これがフォーカスを失うと SSH がタイムアウトし,
`agent refused operation` になるため, `omarchy-1password-focus-guard` が
ダイアログ表示中はフォーカスを固定する。`autostart.lua` からログイン時に起動する。

- 対象: class が `com.onepassword.OnePassword`, title が `1Password` の
  floating ウィンドウで, サイズが 650x550 以下 (Quick Access はこれより大きい)
- 承認 / 拒否 / タイムアウトでダイアログが閉じれば自動的に解除される
- ログ: `journalctl -t omarchy-1password-focus-guard -f`
- 一時停止: `pkill -f omarchy-1password-focus-guard`

1Password のアップデートで class やダイアログのサイズが変わった場合は,
スクリプト内の判定を合わせる。

注意: GDK_SCALE 用の変数名を Omarchy 既定の `omarchy_gdk_scale` にしない。
`omarchy-hyprland-monitor-scaling` は 4.5 でも `local omarchy_gdk_scale = ...` と
リテラルの `hl.env("GDK_SCALE", "...")` を `sed -i` で書き換えるため, 既定名だと
誤爆時に GDK_SCALE が書き換わる (実際に 2 → 1 になった)。`gdk_scale` +
`tostring()` にしているためどちらの sed にも一致しない。
なお 4.5 の同コマンドは変更後の scale を `monitors.lua` の該当 `hl.monitor` ルールへ
直接書き込む (`persist_scale`)。symlink は維持されるが, 直接実行するとリポジトリ側
ファイルの値が更新される (その場限りではない)。`SUPER + /` / `SUPER + ALT + /` は
誤爆防止のため unbind 済み。

## 音声入力 (Hex)

Hex (`~/.local/bin/hex`) を Omarchy の dictation バックエンドとして使う。
`make omarchy` または `make omarchy_hex` で導入し, 4.5 以降ではバックエンドを
hex に切り替える (`omarchy dictation use hex`)。

注意: 4.5 へ更新すると migration が「既存の dictation ユーザーは Voxtype のまま」に
するため (`~/.config/omarchy/defaults/dictation` に `voxtype` を書き込む), Hex に
戻すには上記コマンドを明示的に実行する。`make omarchy` もこの切り替えを行う。

Omarchy 4.5 の既定キーは **F9 / 右 Alt 長押し** (push-to-talk) と
**SUPER + CTRL + X** (トグル)。dotfiles では JIS 配列に右 Alt が無いため,
**右 Shift 長押し** も同じ push-to-talk に割り当てる。右 Alt は外部キーボード用に残す。
右 Shift は文字入力にも使うため, SUPER / CTRL / ALT を先に押している組み合わせでは
開始しないようにしている (Shift キー自体はアプリにも渡る)。

Omarchy 4.0.x には dictation バックエンドの仕組みが無いため, `hypr/bindings.lua` が
同じキーを直接 Hex (`omarchy-dictation-hex`) に割り当てる。4.5 以降は Omarchy の
`default/hypr/bindings/dictation.lua` に任せ, 右 Shift の追加分だけを張る。

- Hex 設定のショートカット (`Alt + Space` など) は Hyprland では使われない
- Hex の Annotate も既定で F9 のため, 使う場合は Hex 側で別キーにする
- キャンセルは `omarchy-dictation-hex cancel` を任意のキーに割り当てる
  (Omarchy 4.5 の `omarchy dictation` に cancel は無い)

## symlink とバックアップ

- リンク先に実体ファイル/ディレクトリがある場合は内容を失わないよう
  `*.bak.<timestamp>` へ退避してから symlink します。
- `.gitconfig` は XDG 配置の `~/.config/git/config` へリンクします
  (omarchy 既定の git 設定を上書き)。4.5 でも `~/.gitconfig` が無い状態で
  `git config --list --show-origin` がこのファイルを読むことを確認済み。
- `.tmux.conf` は Linux では XDG 配置の `~/.config/tmux/tmux.conf` へリンクします。
  tmux 3.8 も `~/.tmux.conf` と XDG の両方を読み, XDG 側が後に適用されます
  (4.5 は `~/.tmux.conf` を配布せず, `/usr/share/omarchy/config/tmux/tmux.conf` を
  `omarchy-refresh-tmux` で XDG 側へ置く)。`~/.tmux.conf` は作らないため,
  テスト用サーバー (`tmux -L audit new-session`) で `mode-keys vi` などの設定が
  適用されることを確認済み。
- 注意: omarchy の migration が `sed -i` で `~/.config/tmux/tmux.conf` を直接編集すると
  symlink が実体ファイルに置き換わります (4.5 の `1784401744.sh` など)。
  `ls -l` でリンクのままか確認し, 実体化していたら `make link` で再リンクします
  (実体ファイルは `*.bak.<timestamp>` へ退避されます)。`omarchy-refresh-tmux` は
  `cp -f` で symlink 先のリポジトリ側ファイルを上書きする点にも注意してください。
- mise は symlink 先を新しいパスとして扱うため, 初回は `mise trust` が必要になる
  ことがあります (`mise trust ~/Projects/Personal/dotfiles` など)。
