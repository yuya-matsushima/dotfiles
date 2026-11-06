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
-- ここでは追加の右 Shift だけを, 選択中バックエンドが使えるときに有効にする。
local dictation_command

if o.cmd_present("omarchy-dictation") then
  local pipe = io.popen("omarchy-default-dictation 2>/dev/null", "r")
  local backend = pipe and pipe:read("*l")
  if pipe then
    pipe:close()
  end
  if backend and backend:match("^[%w%-]+$") and not o.cmd_missing(backend) then
    dictation_command = "omarchy-dictation"
  end
end

if dictation_command then
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
  local shift_locked = false
  local pending_stop = false
  local press_serial = 0
  local long_press = false
  -- 2回目の押下を待つ時間。この間に押し直すとロック録音になる。
  local double_tap_ms = 300
  -- これ以上押し続けたら push-to-talk の長押しとみなす。
  local hold_ms = 400

  local function run_dictation(action)
    hl.dispatch(hl.dsp.exec_cmd(dictation_command .. " " .. action))
  end

  local function stop_dictation()
    shift_dictating = false
    shift_locked = false
    pending_stop = false
    run_dictation("stop")
  end

  hl.bind("Shift_R", function()
    for _, key in ipairs({ "Super_L", "Super_R", "Control_L", "Control_R", "Alt_L", "Alt_R" }) do
      if hl.is_key_down(key) then
        return
      end
    end
    -- ロック中にもう一度押したら停止する。
    if shift_locked then
      stop_dictation()
      return
    end
    -- 直前のタップから続けて押した場合は, 録音を止めずにロックへ移る。
    if pending_stop then
      pending_stop = false
      shift_locked = true
      return
    end
    shift_dictating = true
    long_press = false
    press_serial = press_serial + 1
    local serial = press_serial
    hl.timer(function()
      if press_serial == serial then
        long_press = true
      end
    end, { timeout = hold_ms, type = "oneshot" })
    run_dictation("start")
  end, {
    description = "Start dictation (push-to-talk, double-tap to lock)",
    ignore_mods = true,
    non_consuming = true,
  })

  hl.bind("Shift_R", function()
    if not shift_dictating or shift_locked then
      return
    end
    if long_press then
      stop_dictation()
      return
    end
    -- タップは少し待ってから止める。すぐ押し直されたらロックとして継続する。
    pending_stop = true
    hl.timer(function()
      if pending_stop then
        stop_dictation()
      end
    end, { timeout = double_tap_ms, type = "oneshot" })
  end, {
    description = "Stop dictation (push-to-talk)",
    release = true,
    ignore_mods = true,
    non_consuming = true,
    transparent = true,
  })
end

-- macOS の .hammerspoon/init.lua と同じく, CTRL + J で改行 (SHIFT + ENTER) を挿入する。
-- ENTER が「送信」になるチャット系アプリだけを対象にする。ターミナルやエディタでは
-- CTRL + J (= LF) をそのままアプリへ渡したいので, 対象アプリがアクティブなときだけ
-- バインドを有効化する (macOS 版の application watcher と同じ考え方)。
--
-- ネイティブアプリは WM_CLASS を小文字で, Omarchy の web app は
-- chrome-<host>_<path>-Default というクラス名を小文字で比較する。
local ctrl_j_targets = {
  "^discord$",
  "^slack$",
  "^telegram",
  "^teams%-for%-linux$",
  "^element",
  "chatgpt%.com",
  "claude%.ai",
  "gemini%.google%.com",
  "app%.slack%.com",
  "teams%.microsoft%.com",
  "notion%.so",
}

local function ctrl_j_target_active(window)
  local class = ((window and window.class) or ""):lower()
  for _, pattern in ipairs(ctrl_j_targets) do
    if class:find(pattern) then
      return true
    end
  end
  return false
end

local ctrl_j_newline = hl.bind(
  "CTRL + J",
  hl.dsp.send_shortcut({ mods = "SHIFT", key = "Return" }),
  { description = "Insert newline (SHIFT + ENTER)" }
)

ctrl_j_newline:set_enabled(ctrl_j_target_active(hl.get_active_window()))

hl.on("window.active", function(window)
  ctrl_j_newline:set_enabled(ctrl_j_target_active(window))
end)
