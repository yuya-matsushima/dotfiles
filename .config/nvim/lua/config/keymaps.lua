-- ============================================================================
-- Keyboard Shortcuts Configuration
-- Migrated from .vimrc lines 207-228
-- ============================================================================

local map = vim.keymap.set
local g = vim.g

-- ============================================================================
-- CLEAR SEARCH HIGHLIGHT
-- ============================================================================

-- ESC ESC to clear search highlighting
map('n', '<Esc><Esc>', ':nohlsearch<CR><Esc>', { silent = true, noremap = true })

-- ============================================================================
-- COLON AND SEMICOLON SWAP (US KEYBOARD)
-- ============================================================================

-- Swap ; and : for US keyboard or when external US keyboard is connected
if g.keyboard_type == 'US' or g.has_external_us_keyboard then
  map('n', ';', ':', { noremap = true })
  map('n', ':', ';', { noremap = true })
  map('v', ';', ':', { noremap = true })
  map('v', ':', ';', { noremap = true })
end

-- ============================================================================
-- SUDO SAVE
-- ============================================================================

-- Save as sudo
vim.api.nvim_create_user_command('Sudow', 'w !sudo tee > /dev/null %', {})

-- ============================================================================
-- MARKDOWN LINK PASTE
-- ============================================================================

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function()
    map('n', '<leader>ml', function()
      require('utils.markdown_link').paste_as_link()
    end, { buffer = true, noremap = true, desc = 'Paste/convert URL as Markdown link' })
  end,
})
