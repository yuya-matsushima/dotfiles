-- ユーザー上書きを有効にするための PATH 調整。
--
-- Omarchy 既定 (default.hypr.envs) は Hyprland が起動するプロセスの PATH 先頭に
-- /usr/share/omarchy/bin を挿入する。このディレクトリの中身はすべて
-- /usr/bin/omarchy-* への symlink だが, ~/.local/bin より前に解決されるため,
-- ~/.local/bin に置いたユーザー上書き (例: カスタム omarchy-screensaver) が
-- 常に隠されてしまう。
--
-- ここでは冗長な /usr/share/omarchy/bin を PATH から取り除く。omarchy-* は
-- 引き続き /usr/bin から解決され, ~/.local/bin の上書きが優先される。
-- mise shims と ~/.local/bin の相対順序は変えない。

local packaged_bin = "/usr/share/omarchy/bin"
local kept, seen = {}, {}
for entry in (os.getenv("PATH") or ""):gmatch("[^:]+") do
  if entry ~= packaged_bin and not seen[entry] then
    seen[entry] = true
    table.insert(kept, entry)
  end
end

hl.env("PATH", table.concat(kept, ":"))
