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

-- 外部 (DP-3) と内蔵 (eDP-1) の monitor / workspace ルールは接続状態に
-- かかわらず常に宣言する。Hyprland は未接続出力のルールを保持し、接続時に
-- 自動で適用する (該当ワークスペースもそのモニターへ移動する)。
-- 読み込み時点の検出に頼ると、起動後に外部を挿したときレイアウトと
-- SUPER+1..0 の割り当てが内蔵基準のままになり、画面順が崩れる。
--
-- 縦配置: 外部 (DP-3) を上 (Display 1, 0x0)、内蔵 (eDP-1) をその真下
-- (Display 2)。外部の論理高さ = 2160 / (4/3) = 1620px なので y=1620。
hl.monitor({ output = "DP-3", mode = "preferred", position = "0x0", scale = external_scale })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x1620", scale = internal_scale })

-- SUPER+1..0 が選ぶワークスペースをモニターに固定:
--   SUPER+1..5 = 外部 (Display 1), SUPER+6..0 = 内蔵 (Display 2)
-- 注意: 範囲指定 (1-5) は使えないため、個別に列挙する。
for ws = 1, 5 do
  hl.workspace_rule({ workspace = tostring(ws), monitor = "DP-3" })
end
for ws = 6, 10 do
  hl.workspace_rule({ workspace = tostring(ws), monitor = "eDP-1" })
end

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
