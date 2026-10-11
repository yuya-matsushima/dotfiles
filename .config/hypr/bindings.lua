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
-- IME 切替の CTRL + SPACE と押し方が近く, 誤爆で bar-off フラグが立ったまま
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
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- IME (fcitx5/mozc) toggle.
-- Hyprland の Wayland IME (zwp_input_method_v2) では fcitx5 から見える入力
-- コンテキストが常に 1 つで, ON/OFF 状態はグローバルになる。アプリ単位の状態
-- 保持は原理的にできないため行わない (詳細: docs/omarchy.md)。
-- また fcitx5 は Hyprland ではトリガキーを直接受け取れないため, compositor 側で
-- ~/.local/bin/ime-toggle を叩いて current IM を mozc <-> keyboard-us で切り替える。
-- (従来の fcitx5-remote -t による active/inactive トグルは keyboard-us 上で
-- mozc に戻せず「直接入力」に取り残される問題があった。ime-toggle は
-- IM を明示的に切り替えることで状態遷移を一意にする)
-- 注意: このキーは Hyprland が消費するため, アプリ側には Ctrl+Space は渡らない。
o.bind("CTRL + SPACE", "IME toggle (fcitx5/mozc)", os.getenv("HOME") .. "/.local/bin/ime-toggle")

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
