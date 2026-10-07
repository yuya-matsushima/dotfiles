-- ============================================================================
-- Neovim Options Configuration
-- Migrated from .vimrc lines 5-149
-- ============================================================================

local opt = vim.opt
local g = vim.g

-- ============================================================================
-- PATH SETUP FOR MISE
-- ============================================================================
-- mise のグローバル Node.js (lts) を PATH の先頭に追加
-- ディレクトリ固有の .tool-versions / mise.toml で古い Node.js が設定されていても
-- Neovim のプラグイン (Copilot, Mason, LSP) は常に LTS を使用する
local mise_node_path = vim.fn.system('mise -C ~ where node 2>/dev/null'):gsub('\n', '')
if mise_node_path ~= '' and vim.fn.isdirectory(mise_node_path .. '/bin') == 1 then
  vim.env.PATH = mise_node_path .. '/bin:' .. vim.env.PATH
end

-- ============================================================================
-- FILE ENCODING
-- ============================================================================

opt.fileencodings = 'utf-8,ucs-bom,sjis,cp932,utf-16,utf-16le'

-- ============================================================================
-- DISPLAY SETTINGS
-- ============================================================================

opt.number = true
opt.signcolumn = 'yes'
opt.listchars = { eol = '$', tab = '> ', extends = '<' }
opt.ambiwidth = 'double'
opt.showmatch = true
opt.title = false
-- Note: completeopt is configured in completion.lua
opt.shortmess:append('c')

-- increment/decrement for numbers
opt.nrformats = { "bin", "hex" }

-- ============================================================================
-- NO BEEP
-- ============================================================================

opt.visualbell = true
opt.errorbells = false

-- ============================================================================
-- WRAPPING
-- ============================================================================

opt.whichwrap = 'b,s,h,l,<,>,[,]'
opt.formatoptions:append('mM')

-- ============================================================================
-- CLIPBOARD
-- ============================================================================

if jit.os == 'OSX' or jit.os == 'Windows' then
  opt.clipboard:append('unnamed')
end

-- ============================================================================
-- FILE HANDLING
-- ============================================================================

opt.hidden = true
opt.autoread = true

-- ============================================================================
-- SEARCH SETTINGS
-- ============================================================================

opt.incsearch = true
opt.smartcase = true
opt.wrapscan = true
opt.hlsearch = true

-- ============================================================================
-- INDENT SETTINGS
-- ============================================================================

opt.autoindent = true
opt.cindent = true
opt.smartindent = true
opt.backspace = { 'indent', 'eol', 'start' }

-- Default indentation (2 spaces)
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

-- ============================================================================
-- NO BACKUP OR TEMP FILES
-- ============================================================================

opt.undofile = false
opt.swapfile = false
opt.backup = false

-- ============================================================================
-- WINDOW SPLIT
-- ============================================================================

opt.splitbelow = true
opt.splitright = true

-- ============================================================================
-- VIMDIFF
-- ============================================================================

opt.diffopt:remove('filler')
opt.diffopt:append({ 'iwhite', 'horizontal', 'algorithm:histogram', 'linematch:60' })

-- ============================================================================
-- FOLDING
-- ============================================================================

if vim.fn.has('folding') == 1 then
  opt.foldenable = false
  opt.foldmethod = 'indent'
  opt.fillchars = { vert = '|' }
end

-- ============================================================================
-- COMMAND LINE
-- ============================================================================

opt.wildmenu = true
opt.cmdheight = 2
opt.showcmd = true

-- ============================================================================
-- STATUS LINE
-- ============================================================================

opt.laststatus = 2

-- ============================================================================
-- IME SETTINGS
-- ============================================================================

opt.iminsert = 0
opt.imsearch = 0

-- ============================================================================
-- KEYBOARD TYPE DETECTION
-- ============================================================================

-- Detect the built-in keyboard layout ('US' or 'JIS').
-- 通常の US マシンは 'US', JIS 配列のマシンは 'JIS' を返す。
-- まれに JIS 配列の Mac を使うが、その場合でも外付け US キーボード接続時は
-- US 扱いにしたいので has_external_us_keyboard と OR で判定する。
-- 明示指定したい場合は NVIM_KEYBOARD_TYPE=JIS を環境変数に設定する。
local function detect_keyboard_type()
  local override = vim.env.NVIM_KEYBOARD_TYPE
  if override == 'US' or override == 'JIS' then
    return override
  end
  if jit.os == 'OSX' then
    local src = vim.fn.system(
      'defaults read com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID 2>/dev/null')
    if src:match('Japanese') or src:match('JIS') then
      return 'JIS'
    end
  elseif jit.os == 'Linux' then
    local status = vim.fn.system('localectl status 2>/dev/null')
    if status:match('Keymap: jp') or status:match('Layout: jp') then
      return 'JIS'
    end
  end
  return 'US'
end

-- Detect an external US keyboard (HHKB / Keychron Q11).
-- macOS は ioreg, Linux は /sys/bus/usb/devices/*/{product,manufacturer} を走査する。
local function has_external_us_keyboard()
  if jit.os == 'OSX' then
    return vim.fn.system('ioreg -n IOUSB -l | grep -E "(HHKB|Keychron Q11)"') ~= ''
  elseif jit.os == 'Linux' then
    for _, key in ipairs({ 'product', 'manufacturer' }) do
      for _, path in ipairs(vim.fn.glob('/sys/bus/usb/devices/*/' .. key, false, true)) do
        local ok, lines = pcall(vim.fn.readfile, path)
        if ok then
          for _, line in ipairs(lines) do
            if line:match('HHKB') or line:match('Keychron Q11') then
              return true
            end
          end
        end
      end
    end
  end
  return false
end

g.keyboard_type = detect_keyboard_type()
g.has_external_us_keyboard = has_external_us_keyboard()

-- Automatically set keyboard type to US if external keyboard is detected
if g.has_external_us_keyboard then
  g.keyboard_type = 'US'
end

-- ============================================================================
-- MOUSE SETTINGS
-- ============================================================================

-- Enable mouse in all modes (visual, normal, insert, command-line)
-- This allows:
-- 1. Mouse selection and copying in visual mode
-- 2. Window/pane focus with mouse clicks
-- 3. Seamless integration with terminal emulator's auto-copy feature
-- 4. Compatible with tmux mouse mode (set -g mouse on)
opt.mouse = 'a'
