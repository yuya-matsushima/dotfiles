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
local function toggleIMESwitch(event)
  local c = event:getKeyCode()
  local f = event:getFlags()
  if event:getType() == hs.eventtap.event.types.keyDown then
    if f['cmd'] then
      simpleCmd = true
    end
  elseif event:getType() == hs.eventtap.event.types.flagsChanged then
    if not f['cmd'] then
      if simpleCmd == false and (c == map['cmd'] or c == map['rightcmd'])then
        if hs.keycodes.currentMethod() == 'Romaji' then
          hs.keycodes.setMethod('Hiragana')
        else
          hs.keycodes.setMethod('Romaji')
        end
      end
      simpleCmd = false
    end
  end
end

toggleIMESwitcher = hs.eventtap.new(
  {hs.eventtap.event.types.keyDown, hs.eventtap.event.types.flagsChanged},
  toggleIMESwitch
)
toggleIMESwitcher:start()
