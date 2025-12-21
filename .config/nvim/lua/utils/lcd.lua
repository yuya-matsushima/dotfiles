-- ============================================================================
-- Auto LCD (Change Directory) Utility
-- Migrated from .vim/autoload/lcd.vim
-- ============================================================================

local M = {}

-- Automatically change local directory to current file's directory
function M.changeDir()
  -- Skip for oil.nvim
  if vim.bo.filetype == 'oil' then
    return
  end

  local bufname = vim.fn.expand('%:p:h')

  -- Skip for oil.nvim paths
  if string.match(bufname, "^oil://") then
    return
  end

  -- Skip for special buffers
  if bufname ~= 'quickrun:' and bufname ~= '' then
    vim.cmd('lcd ' .. vim.fn.fnameescape(bufname))
  end
end

return M
