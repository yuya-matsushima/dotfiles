-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- fcitx5 の入力切替を Hyprland のフォーカスイベントに追従させる常駐スクリプト。
-- 詳細: .local/bin/hypr-fcitx-sync
o.launch_on_start("hypr-fcitx-sync")
