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

-- 右 CMD で IME 切り替え
-- IME 切替キーを単一キーで押す
local KEY_CMD_RIGHT = 54
local toggleIME = function()
  -- CMD + space で IME 変換設定を前提
  hs.eventtap.keyStroke({ "cmd" }, "space", 800)
end
hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(e)
	local c = e:getKeyCode()
	local f = e:getFlags()
	if f['cmd'] and c == KEY_CMD_RIGHT then toggleIME() end
end):start()
