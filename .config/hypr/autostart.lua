-- ~/.local/bin のユーザー上書きを /usr/share/omarchy/bin より優先させる。
-- (カスタム omarchy-screensaver を有効にするため。詳細: hypr/envs.lua)
require("hypr.envs")

-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- fcitx5 の入力切替を Hyprland のフォーカスイベントに追従させる常駐スクリプト。
-- 詳細: .local/bin/hypr-fcitx-sync
o.launch_on_start("hypr-fcitx-sync")
