-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- GDK_SCALE は compositor の scale と揃える (食い違うと GTK/Chromium 系で
-- IME 候補ウィンドウの座標がずれる)。
local gdk_scale = 2
-- 注意: 変数名を Omarchy 既定の omarchy_monitor_scale / omarchy_gdk_scale にしない。
-- omarchy-hyprland-monitor-scaling (SUPER + / , SUPER + ALT + /) はその行を見つけると
-- sed -i で書き換え, symlink を実体ファイルに置き換えてしまう。別名にしておけば
-- ショートカットでの scale 変更はその場限り (再起動・reload で本ファイルの値に戻る)。
-- モニター別スケール。同じ値に揃えると高 DPI の内蔵 (225 DPI) の文字が
-- 外部 4K (162 DPI) より小さく見えるため、内蔵を高めに振る。
-- 注意: Hyprland は「物理ピクセル ÷ scale が整数論理ピクセルになる」scale しか
-- 受け付けず、指定値は最も近い許容値に丸められる。2560x1600 の許容値に 1.8 は
-- 無く (隣は 5/3 と 2.0)、3840x2160 の許容値に 1.4 は無い (隣は 4/3 と 1.5)。
-- そのため内蔵 5/3 (≒1.667) / 外部 4/3 (≒1.333) を使う
-- (Hyprland #8117 / #16003, Omarchy #7559 参照)。
local external_scale = 4 / 3  -- 外部 (DP-3): 4K (≒1.333)
local internal_scale = 5 / 3  -- 内蔵 (eDP-1): 高 DPI (≒1.667)

hl.env("GDK_SCALE", tostring(gdk_scale))

-- 外部 (DP-3) と内蔵 (eDP-1) の monitor ルールは接続状態にかかわらず常に
-- 宣言する。Hyprland は未接続出力のルールを保持し、接続時に自動で適用する
-- ため、起動後に外部を挿しても画面順は崩れない。
--
-- 縦配置: 外部 (DP-3) を上 (Display 1, 0x0)、内蔵 (eDP-1) をその真下
-- (Display 2)。外部の論理高さ = 2160 / (4/3) = 1620px なので y=1620。
hl.monitor({ output = "DP-3", mode = "preferred", position = "0x0", scale = external_scale })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x1620", scale = internal_scale })

-- ワークスペースをモニターへ固定しない。
-- Omarchy 4.5 以降は各モニターが 1-10 のワークスペースを持ち (内蔵が 1-10、
-- 次のモニターが 11-20 のブロック)、SUPER+1..0 はフォーカス中のモニターの
-- スロット 1..10 を選ぶ (default/hypr/monitor-workspaces.lua)。
-- 4.0.x 向けに SUPER+1..5 を外部、6..0 を内蔵へ固定していた workspace_rule は、
-- このブロック割り当てと競合して接続時にワークスペースを renumber させるため
-- 削除した。モニター間の移動は SUPER+SHIFT+ALT+矢印 (ワークスペース) /
-- SUPER+SHIFT+CTRL+矢印 (ウィンドウ) を使う。

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
