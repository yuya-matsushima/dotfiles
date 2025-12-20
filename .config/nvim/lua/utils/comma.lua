-- ============================================================================
-- Comma Conversion Utility
-- Migrated from .vim/autoload/comma.vim
-- ============================================================================

local M = {}

-- Convert Japanese comma (、) to Western comma with space (, )
function M.ToComma()
  local cursor = vim.fn.getpos('.')
  vim.cmd([[silent! %s/、/, /e]])
  vim.fn.setpos('.', cursor)
end

return M
