-- ============================================================================
-- Neovim Configuration Entry Point
-- ============================================================================

-- Load core configuration
require('config.options')      -- Vim options (encoding, display, search, etc.)
require('config.lazy')         -- Bootstrap lazy.nvim plugin manager
require('config.keymaps')      -- Keyboard shortcuts
require('config.autocmds')     -- Autocommands

-- ============================================================================
-- LOCAL CONFIGURATION
-- ============================================================================

-- load ~/.nvim_local.lua if exists
local local_config_path = vim.fn.expand('~/.nvim_local.lua')
if vim.fn.filereadable(local_config_path) == 1 then
  local ok, err = pcall(dofile, local_config_path)
  if not ok then
    vim.api.nvim_err_writeln('Error loading ~/.nvim_local.lua: ' .. err)
  end
end

