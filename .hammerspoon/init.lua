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

-- IME の英字/ひらがなを cmd 単体押しで切り替え
local simpleCmd = false
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

local function toggleIMESwitch(event)
  local t = event:getType()
  local f = event:getFlags()
  local c = event:getKeyCode()

  if t == hs.eventtap.event.types.flagsChanged then
    -- cmdが押された瞬間、他の修飾キーがなければsimpleCmdをtrue
    if f['cmd'] and not f['shift'] and not f['alt'] and not f['ctrl'] then
      simpleCmd = true
    -- cmdが離された瞬間、simpleCmdがtrueならIME切り替え
    elseif not f['cmd'] and simpleCmd then
      if hs.keycodes.currentMethod() == romajiMode then
        hs.keycodes.setMethod(hiraganaMode)
      else
        hs.keycodes.setMethod(romajiMode)
      end
      simpleCmd = false
    else
      simpleCmd = false
    end
  elseif t == hs.eventtap.event.types.keyDown then
    -- cmd以外のキーが押されたらsimpleCmdをfalse
    if simpleCmd and not (c == map['cmd'] or c == map['rightcmd']) then
      simpleCmd = false
    end
  end
end

toggleIMESwitcher = hs.eventtap.new(
  {hs.eventtap.event.types.keyDown, hs.eventtap.event.types.flagsChanged},
  toggleIMESwitch
)
toggleIMESwitcher:start()

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
