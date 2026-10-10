-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- GDK_SCALE は compositor の scale と揃える (食い違うと GTK/Chromium 系で
-- IME 候補ウィンドウの座標がずれる)。
local omarchy_gdk_scale = 2
-- IME (fcitx5/mozc) の候補ウィンドウは Wayland では compositor が位置決めする。
-- 分数スケールだと座標がずれて候補が入力中の文字にかぶるため整数スケールにする
-- (Hyprland #8117 / #16003, Omarchy #7559 参照)。読みやすさは
-- omarchy-display-text-size やフォントサイズで調整する。
local omarchy_monitor_scale = 1.6

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- 外部ディスプレイ検知 (exit 0 = 外部モニター接続あり)。
-- 接続時: 外部 (DP-3) を Display 1 (0x0)、内蔵 (eDP-1) を Display 2。
-- 単体時: 内蔵のみ auto。
-- 注意: 設定読み込み時点で判定するため、起動後に外部を抜き挿しした場合は
-- hyprctl reload or omarchy hyprland monitor laptop などで反映する。
local external_connected = o.shell_succeeds("omarchy hw external monitors")

if external_connected then
  -- 縦配置: 外部 (DP-3) を上 (Display 1, 0x0)、内蔵 (eDP-1) をその真下 (Display 2)。
  -- 外部の論理高さ = 2160 / 1.6 = 1350px なので内蔵は y=1350 に配置する。
  hl.monitor({ output = "DP-3", mode = "preferred", position = "0x0", scale = omarchy_monitor_scale })
  hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x1350", scale = omarchy_monitor_scale })

  -- SUPER+1..0 が選ぶワークスペースをモニターに固定:
  --   SUPER+1..5 = 外部 (Display 1), SUPER+6..0 = 内蔵 (Display 2)
  -- 注意: workspace_rule の selectors は既存ワークスペースにのみマッチするため
  -- 範囲指定 (1-5) は使えず、個別に列挙する。
  for ws = 1, 5 do
    hl.workspace_rule({ workspace = tostring(ws), monitor = "DP-3" })
  end
  for ws = 6, 10 do
    hl.workspace_rule({ workspace = tostring(ws), monitor = "eDP-1" })
  end
else
  -- Mac 単体: 内蔵のみ
  hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = omarchy_monitor_scale })
end

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
