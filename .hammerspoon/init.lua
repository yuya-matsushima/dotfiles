local application = require("hs.application")
local spaces = require("hs.spaces")

-- App をショートカットで開閉
local toggleApp = function(appName)
  local app = application.get(appName)

  if app == nil then
    application.launchOrFocus(appName)
    -- アプリがインストールされていない場合何もしない
  elseif app:isFrontmost() then
    app:hide()
  else
    local active_space = spaces.focusedSpace()
    local win = app:focusedWindow()
    spaces.moveWindowToSpace(win, active_space)
    app:setFrontmost()
  end
end

-- Determine Terminal App (Ghostty or Alacritty)
local terminalApp = "Alacritty"
if hs.application.infoForBundleID("com.mitchellh.ghostty") ~= nil then
  terminalApp = "Ghostty"
end

-- US MacBook Pro
hs.hotkey.bind({ "ctrl" }, "delete", function() toggleApp(terminalApp) end)
hs.hotkey.bind({ "ctrl" }, "=", function() toggleApp("Obsidian") end)
hs.hotkey.bind({ "ctrl" }, "-", function() toggleApp("ChatGPT") end)
hs.hotkey.bind({ "ctrl" }, "0", function() toggleApp("Claude") end)

-- 修飾キー単体押しの処理 (Cmd: IME 切り替え, Ctrl: Spotlight トグル)
local simpleCmd = false
local simpleCtrl = false
local spotlightToggling = false
local map = hs.keycodes.map

-- 利用可能なIMEメソッドから動的に判定
local function detectIMEMethods()
  local methods = hs.keycodes.methods()
  local hasGoogleIME = false

  -- methods は配列形式 {1: "Hiragana", 2: "Romaji", ...} なので値を検索
  for _, method in pairs(methods) do
    if method == 'Hiragana (Google)' then
      hasGoogleIME = true
      break
    end
  end

  -- Google Japanese IME が利用可能かチェック
  -- NOTE: Mac の設定 > キーボード > 入力ソースを `ひらがな（Google）`, `英数（Google)` に設定してください。
  if hasGoogleIME then
    return 'Hiragana (Google)', 'Alphanumeric (Google)'
  else
    -- ことえり（Mac標準IME）にフォールバック
    return 'Hiragana', 'Romaji'
  end
end

local hiraganaMode, romajiMode = detectIMEMethods()

local function handleSingleModifierTap(event)
  local t = event:getType()
  local f = event:getFlags()
  local c = event:getKeyCode()

  if t == hs.eventtap.event.types.flagsChanged then
    -- Cmd 単体押し: IME 切り替え
    if f['cmd'] and not f['shift'] and not f['alt'] and not f['ctrl'] then
      simpleCmd = true
    elseif not f['cmd'] and simpleCmd then
      if not spotlightToggling then
        if hs.keycodes.currentMethod() == romajiMode then
          hs.keycodes.setMethod(hiraganaMode)
        else
          hs.keycodes.setMethod(romajiMode)
        end
      end
      simpleCmd = false
    else
      simpleCmd = false
    end

    -- Ctrl 単体押し: Spotlight トグル
    if f['ctrl'] and not f['shift'] and not f['alt'] and not f['cmd'] then
      simpleCtrl = true
    elseif not f['ctrl'] and simpleCtrl then
      simpleCmd = false
      spotlightToggling = true
      hs.timer.doAfter(0, function()
        hs.osascript.applescript([[
          tell application "System Events"
            key code 49 using {command down}
          end tell
        ]])
        hs.timer.doAfter(0.5, function() spotlightToggling = false end)
      end)
      simpleCtrl = false
    else
      simpleCtrl = false
    end
  elseif t == hs.eventtap.event.types.keyDown then
    if simpleCmd and not (c == map['cmd'] or c == map['rightcmd']) then
      simpleCmd = false
    end
    if simpleCtrl and not (c == map['ctrl'] or c == map['rightctrl']) then
      simpleCtrl = false
    end
  end
end

singleModifierTapWatcher = hs.eventtap.new(
  {hs.eventtap.event.types.keyDown, hs.eventtap.event.types.flagsChanged},
  handleSingleModifierTap
)
singleModifierTapWatcher:start()

-- Ctrl+J で改行を挿入 (特定アプリ限定)
local ctrlJTargetApps = {
  ["Slack"] = true,
  ["Obsidian"] = true,
  ["Google Chrome"] = true,
}

local ctrlJHotkey = hs.hotkey.new({ "ctrl" }, "j", function()
  hs.eventtap.keyStroke({ "shift" }, "return", 0)
end)

-- 対象アプリがアクティブな時だけ有効化
ctrlJAppWatcher = hs.application.watcher.new(function(appName, eventType, app)
  if eventType == hs.application.watcher.activated then
    if ctrlJTargetApps[appName] then
      ctrlJHotkey:enable()
    else
      ctrlJHotkey:disable()
    end
  end
end)
ctrlJAppWatcher:start()

-- 起動時に現在のアプリをチェック
local frontApp = hs.application.frontmostApplication()
if frontApp and ctrlJTargetApps[frontApp:name()] then
  ctrlJHotkey:enable()
end
