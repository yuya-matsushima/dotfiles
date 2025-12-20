-- ============================================================================
-- Auto LCD (Change Directory) Utility
-- Migrated from .vim/autoload/lcd.vim
-- ============================================================================

local M = {}

-- Automatically change local directory to current file's directory
function M.changeDir()
  local bufname = vim.fn.expand('%:p:h')

  -- Skip for special buffers
  if bufname ~= 'quickrun:' and bufname ~= '' then
    vim.cmd('lcd ' .. vim.fn.fnameescape(bufname))
  end
end

return M
