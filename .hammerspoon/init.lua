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
    local alacritty_win = app:focusedWindow()
    spaces.moveWindowToSpace(alacritty_win, active_space)
    app:setFrontmost()
  end
end

-- US keyboard(HHKB)
hs.hotkey.bind({ "ctrl" }, "`", function() toggleApp("Alacritty") end)
-- US MacBook Pro
hs.hotkey.bind({ "ctrl" }, "delete", function() toggleApp("Alacritty") end)
-- JP keyboard
-- hs.hotkey.bind({ "ctrl" }, "¥", function() toggleApp("Alacritty") end)

-- IME の英字/ひらがなを右 cmd で切り替え
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
      if simpleCmd == false and c == map['rightcmd'] then
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
