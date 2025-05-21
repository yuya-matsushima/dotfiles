local application = require("hs.application")
local spaces = require("hs.spaces")

-- App をショートカットで開閉
local toggleApp = function(appName)
  local app = application.get(appName)

  if app == nil then
    application.launchOrFocus(appName)
  elseif app:isFrontmost() then
    app:hide()
  else
    local active_space = spaces.focusedSpace()
    local win = app:focusedWindow()
    spaces.moveWindowToSpace(win, active_space)
    app:setFrontmost()
  end
end

-- US MacBook Pro
hs.hotkey.bind({ "ctrl" }, "delete", function() toggleApp("Alacritty") end)
hs.hotkey.bind({ "ctrl" }, "\\", function() toggleApp("Visual Studio Code") end)
hs.hotkey.bind({ "ctrl" }, "=", function() toggleApp("Inkdrop") end)

-- IME の英字/ひらがなを右 cmd で切り替え
-- この設定は前提として Mac IME の "日本語-ローマ字入力" を前提
local simpleCmd = false
local map = hs.keycodes.map
local hiraganaMode = 'Hiragana'
local romajiMode = 'Romaji'

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
      if hs.keycodes.currentMethod() == 'Romaji' then
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
