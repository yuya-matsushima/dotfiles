-- ============================================================================
-- Snippet Configuration (LuaSnip)
-- Provides fast and extensible snippet engine with VSCode-style snippets
-- ============================================================================

-- Snippet keybindings setup
local function setup_snippet_keymaps()
  local luasnip = require('luasnip')

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, {
      noremap = true,
      silent = true,
      desc = desc,
    })
  end

  -- Expand snippet at cursor
  map({ 'i', 's' }, '<C-K>', function()
    luasnip.expand()
  end, 'Expand snippet')

  -- Jump to next snippet placeholder (Shift-Tab handled in completion.lua)
  map({ 'i', 's' }, '<C-L>', function()
    if luasnip.expand_or_jumpable() then
      luasnip.expand_or_jump()
    end
  end, 'Expand or jump to next placeholder')

  -- Jump to previous snippet placeholder
  map({ 'i', 's' }, '<C-H>', function()
    if luasnip.jumpable(-1) then
      luasnip.jump(-1)
    end
  end, 'Jump to previous placeholder')
end

-- Load snippet sources
local function load_snippets()
  local vscode_loader = require('luasnip.loaders.from_vscode')

  -- Load custom VSCode-style snippets from config directory
  local custom_snippets_path = vim.fn.stdpath('config') .. '/snippets'
  vscode_loader.lazy_load({ paths = { custom_snippets_path } })

  -- Load friendly-snippets (common language snippets)
  vscode_loader.lazy_load()
end

return {
  -- LuaSnip: Fast snippet engine
  {
    'L3MON4D3/LuaSnip',
    event = 'InsertEnter',
    build = 'make install_jsregexp',
    dependencies = {
      'rafamadriz/friendly-snippets',
    },
    config = function()
      load_snippets()
      setup_snippet_keymaps()
    end,
  },

  -- friendly-snippets: VSCode-style snippet collection
  {
    'rafamadriz/friendly-snippets',
    lazy = true,
  },
}
