-- ============================================================================
-- Neovim Options Configuration
-- Migrated from .vimrc lines 5-149
-- ============================================================================

local opt = vim.opt
local g = vim.g

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
opt.completeopt = { 'menuone', 'noinsert', 'noselect' }
opt.shortmess:append('c')

-- Disable increment/decrement for numbers
vim.cmd('set nf=')

-- ============================================================================
-- NO BEEP
-- ============================================================================

opt.visualbell = true
opt.errorbells = false
vim.cmd('set t_vb=')

-- ============================================================================
-- WRAPPING
-- ============================================================================

opt.whichwrap = 'b,s,h,l,<,>,[,]'
opt.formatoptions:append('mM')

-- ============================================================================
-- CLIPBOARD
-- ============================================================================

opt.browsedir = 'buffer'
if vim.fn.has('mac') == 1 then
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
opt.diffopt:append({ 'iwhite', 'horizontal' })

-- ============================================================================
-- FOLDING
-- ============================================================================

if vim.fn.has('folding') == 1 then
  opt.foldenable = true
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

g.keyboard_type = 'US'
local external_keyboard = vim.fn.system('ioreg -n IOUSB -l | grep -E "(HHKB|Keychron Q11)"')
g.has_external_us_keyboard = #external_keyboard > 0

-- Automatically set keyboard type to US if external keyboard is detected
if g.has_external_us_keyboard then
  g.keyboard_type = 'US'
end
