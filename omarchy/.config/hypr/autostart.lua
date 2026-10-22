-- ~/.local/bin のユーザー上書きを /usr/share/omarchy/bin より優先させる。
-- (カスタム omarchy-screensaver を有効にするため。詳細: hypr/envs.lua)
require("hypr.envs")

-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Apple T2: re-link streams that are left attached to a vanished sink after
-- the headphone jack is unplugged.
o.exec_on_start("omarchy-audio-stream-recover")
