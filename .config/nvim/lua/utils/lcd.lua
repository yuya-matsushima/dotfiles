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

  -- Skip for special scheme paths (oil://, diffview://)
  if string.match(bufname, "://") then
    return
  end

  -- Skip for special buffers (e.g. quickrun:, diffview:)
  if bufname ~= '' and not string.match(bufname, ":$") then
    vim.cmd('lcd ' .. vim.fn.fnameescape(bufname))
  end
end

return M
