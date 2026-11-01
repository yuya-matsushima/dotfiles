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

-- Omarchy 4.5 以降は default/hypr/bindings/dictation.lua が, 選択中の
-- dictation バックエンドに対して Right Alt / F9 / SUPER + CTRL + X を張る。
-- 4.0.x にはその仕組みが無いため, 4.5 と同じキーを Hex に割り当てる。
local dictation_command

if o.cmd_present("omarchy-dictation") then
  -- 4.5 以降。標準の 3 キーは Omarchy が張るので, ここでは追加の
  -- 右 Shift だけを, 選択中バックエンドが使えるときに有効にする。
  local pipe = io.popen("omarchy-default-dictation 2>/dev/null", "r")
  local backend = pipe and pipe:read("*l")
  if pipe then
    pipe:close()
  end
  if backend and backend:match("^[%w%-]+$") and not o.cmd_missing(backend) then
    dictation_command = "omarchy-dictation"
  end
elseif o.cmd_present("hex") and o.cmd_present("omarchy-dictation-hex") then
  -- 4.0.x。Omarchy 既定 (voxtype) を外して 4.5 と同じキーを Hex に張る。
  dictation_command = "omarchy-dictation-hex"

  hl.unbind("SUPER + CTRL + X")
  hl.unbind("F9")
  hl.unbind("ALT + Alt_R")

  o.bind("SUPER + CTRL + X", "Toggle dictation", dictation_command .. " toggle")
end

-- 押したら start, 離したら stop。Omarchy 4.5 の o.bind_hold と同じ flags。
-- 修飾キーは押下と解放で mask が変わるため, release 側は ignore_mods にする。
-- 4.0.x には o.bind_hold が無いため, press/release の 2 本で表す。
local function bind_hold(keys, command, options)
  local release_options = {}
  for key, value in pairs(options or {}) do
    release_options[key] = value
  end
  release_options.release = true
  release_options.ignore_mods = true
  release_options.non_consuming = true
  release_options.transparent = true

  o.bind(keys, "Start dictation (push-to-talk)", command .. " start", options)
  o.bind(keys, "Stop dictation (push-to-talk)", command .. " stop", release_options)
end

if dictation_command then
  if o.cmd_missing("omarchy-dictation") then
    -- 4.0.x のみ。4.5 は Omarchy 標準の bind に任せる。
    bind_hold("F9", dictation_command)
    -- Right Alt は他の修飾キーと組み合わせても開始する (4.5 と同じ)。
    -- 組み合わせたいときは Left Alt を使う。
    bind_hold("ALT + Alt_R", dictation_command, { ignore_mods = true })
  end

  -- JIS 配列には右 Alt が無いため, 右 Shift にも同じ push-to-talk を割り当てる。
  -- 外部キーボードの右 Alt はそのまま残す。
  --
  -- 修飾キー単体の bind は, 押下時点の mask に自分自身がまだ含まれないため,
  -- press 側は ignore_mods で受ける必要がある。ただしそのままだと
  -- SUPER / CTRL / ALT を先に押している組み合わせでも発火するので,
  -- ディスパッチャ側で他の修飾キーが押されていないことを確認する。
  -- Shift 自体は文字入力にも使うため non_consuming でアプリにも渡す。
  hl.unbind("Shift_R")
  hl.unbind("SHIFT + Shift_R")

  local shift_dictating = false

  hl.bind("Shift_R", function()
    for _, key in ipairs({ "Super_L", "Super_R", "Control_L", "Control_R", "Alt_L", "Alt_R" }) do
      if hl.is_key_down(key) then
        return
      end
    end
    shift_dictating = true
    hl.dispatch(hl.dsp.exec_cmd(dictation_command .. " start"))
  end, {
    description = "Start dictation (push-to-talk)",
    ignore_mods = true,
    non_consuming = true,
  })

  hl.bind("Shift_R", function()
    if not shift_dictating then
      return
    end
    shift_dictating = false
    hl.dispatch(hl.dsp.exec_cmd(dictation_command .. " stop"))
  end, {
    description = "Stop dictation (push-to-talk)",
    release = true,
    ignore_mods = true,
    non_consuming = true,
    transparent = true,
  })
end
