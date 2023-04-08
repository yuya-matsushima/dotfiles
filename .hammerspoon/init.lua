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
