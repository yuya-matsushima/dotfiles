-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Omarchy 既定の SUPER + SHIFT + SPACE (Toggle top bar) を無効化する。
-- 当時 IME 切替に使っていた CTRL + SPACE と押し方が近く, 誤爆で bar-off フラグが立ったまま
-- バーが画面外に隠れていたため (詳細: docs/omarchy.md)。
-- バーを出し入れしたいときは `omarchy-toggle-bar` を直接実行する
-- (off = 表示, on = 非表示。フラグ名が bar-off のため直感と逆)。
hl.unbind("SUPER + SHIFT + SPACE")

-- Omarchy 既定の SUPER + / , SUPER + ALT + / (Monitor scaling up / down) を無効化する。
-- 誤爆で画面全体の scale が変わっていたため。アプリ内のズーム (CTRL + +/- 等) は影響しない。
-- scale を一時的に変えたいときは `omarchy-hyprland-monitor-scaling up|down` を直接実行する
-- (monitors.lua は書き換わらず, hyprctl reload で元に戻る)。
hl.unbind("SUPER + SLASH")
hl.unbind("SUPER + ALT + SLASH")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- IME (fcitx5/mozc) の切替。
-- Hyprland の Wayland IME (zwp_input_method_v2) では fcitx5 から見える入力
-- コンテキストが常に 1 つで, ON/OFF 状態はグローバルになる。アプリ単位の状態
-- 保持は原理的にできないため行わない (詳細: docs/omarchy.md)。
-- 切替は compositor 側で current IM を mozc <-> keyboard-us に明示的に切り替える
-- (fcitx5-remote -t の active/inactive トグルは keyboard-us 上で mozc に戻せず
-- 「直接入力」に取り残される問題があった)。
-- CTRL + SPACE はアプリ (nvim の補完等) に渡すため IME 切替には使わない。

-- 内蔵 JIS キーボードの 英数 / かな キーを macOS 同様の「英語へ」「日本語へ」に固定する。
-- これらが mozc に届くと mozc 内部で「直接入力」へ遷移し, fcitx5 側は mozc 有効の
-- まま英字しか入らなくなる。compositor 側で消費して IM の明示切替だけを行う。
-- jp layout では LANG1 (かな, keycode 130) が Hangul, LANG2 (英数, keycode 131) が
-- Hangul_Hanja になる (xkb pc シンボル由来)。US 配列の外付けキーボードには影響しない。
o.bind("Hangul", "IME on (かな → mozc)", "fcitx5-remote -s mozc")
o.bind("Hangul_Hanja", "IME off (英数 → keyboard-us)", "fcitx5-remote -s keyboard-us")

-- macOS (.hammerspoon/init.lua) と同じく cmd (= SUPER) の単押しで IME をトグルする。
-- release バインドは SUPER を押している間に他のキーが押されると発火しないため,
-- SUPER + 1 等の既存ショートカットとは共存する。左右どちらの SUPER でも反応する。
local ime_toggle = os.getenv("HOME") .. "/.local/bin/ime-toggle"
o.bind("SUPER + Super_L", "IME toggle (SUPER 単押し)", ime_toggle, { release = true })
o.bind("SUPER + Super_R", "IME toggle (SUPER 単押し)", ime_toggle, { release = true })

-- 音声入力 (Hex)。
-- トグル (SUPER + CTRL + X) と push-to-talk (F9 / 右 Alt) は Omarchy 4.5 の既定に任せる。
-- 4.5 の `omarchy dictation` には cancel が無いため, バックエンドが hex のときだけ
-- `omarchy-dictation-hex cancel` を直接叩く。ESC 単体はアプリへ渡す必要があるため,
-- SUPER + CTRL + ESCAPE に割り当てる。
-- 4.0.x はバックエンド選択が無く Omarchy 既定も Voxtype 前提なので, F9 と
-- SUPER + CTRL + X を Hex 用に張り直す。
local dictation_backend
if o.cmd_present("omarchy-default-dictation") then
  local pipe = io.popen("omarchy-default-dictation 2>/dev/null")
  if pipe then
    dictation_backend = pipe:read("*l")
    pipe:close()
  end
elseif o.cmd_present("hex") then
  dictation_backend = "hex"
end

if dictation_backend == "hex" and o.cmd_present("omarchy-dictation-hex") then
  o.bind("SUPER + CTRL + ESCAPE", "Cancel dictation", "omarchy-dictation-hex cancel")

  if not o.cmd_present("omarchy-default-dictation") then
    -- 4.0.x: Voxtype 前提の既定バインドを外してから Hex に差し替える。
    hl.unbind("F9")
    hl.unbind("SUPER + CTRL + X")
    o.bind("F9", "Start dictation (push-to-talk)", "omarchy-dictation-hex start")
    o.bind("F9", "Stop dictation (push-to-talk)", "omarchy-dictation-hex stop", { release = true })
    o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation-hex toggle")
  end
end

-- KeyCastr 代替: 押したキーを keycap として表示する (markpriem.keystrokes)。
-- プラグイン未導入の環境で Hyprland の設定エラーにしないため, 存在するときだけ読む。
-- 既定のトグルは SUPER + SHIFT + K。変更する場合は dofile の前に
-- KEYSTROKES_TOGGLE_BIND = "SUPER + SHIFT + J" を置く。
local keystrokes_plugin = os.getenv("HOME") .. "/.config/omarchy/plugins/markpriem.keystrokes/hypr/keystrokes.lua"
local keystrokes_file = io.open(keystrokes_plugin, "r")
if keystrokes_file then
  keystrokes_file:close()
  dofile(keystrokes_plugin)
end
