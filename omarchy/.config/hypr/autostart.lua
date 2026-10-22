-- ~/.local/bin のユーザー上書きを /usr/share/omarchy/bin より優先させる。
-- (カスタム omarchy-screensaver を有効にするため。詳細: hypr/envs.lua)
require("hypr.envs")

-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Apple T2: re-link streams that are left attached to a vanished sink after
-- the headphone jack is unplugged.
o.exec_on_start("omarchy-audio-stream-recover")

-- 長時間サスペンドからの復帰後, 外部ディスプレイが Hyprland のモニター一覧から
-- 消える / mode を失うことがあるため, 復帰時にモニター状態を再適用する。
o.exec_on_start("omarchy-hyprland-monitor-resume")

-- 1Password がパスワード入力を求める画面を出している間, フォーカスを固定する。
o.exec_on_start("omarchy-1password-focus-guard")
