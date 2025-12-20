-- ============================================================================
-- Whitespace Trim Utilities
-- Migrated from .vim/autoload/trim.vim
-- ============================================================================

local M = {}

-- Remove trailing whitespace (preserve markdown's 2-space line breaks)
function M.RTrim()
  local cursor = vim.fn.getpos('.')

  if vim.bo.filetype == 'markdown' then
    -- Preserve 2-space line breaks in markdown
    vim.cmd([[silent! %s/\s\+\(\s\{2}\)$/\1/e]])
  else
    -- Remove all trailing whitespace
    vim.cmd([[silent! %s/\s\+$//e]])
  end

  vim.fn.setpos('.', cursor)
end

-- Remove leading tabs/spaces from blank lines
function M.LTrimTabAndSpace()
  local cursor = vim.fn.getpos('.')
  vim.cmd([[silent! %s/^[\t ]\+$//e]])
  vim.fn.setpos('.', cursor)
end

return M
