-- ============================================================================
-- Neovim Configuration Entry Point
-- ============================================================================

-- Load core configuration
require('config.options')      -- Vim options (encoding, display, search, etc.)
require('config.lazy')         -- Bootstrap lazy.nvim plugin manager
require('config.keymaps')      -- Keyboard shortcuts
require('config.autocmds')     -- Autocommands

