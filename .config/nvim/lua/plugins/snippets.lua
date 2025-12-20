-- ============================================================================
-- Snippet Configuration (LuaSnip)
-- Replaces vim-vsnip
-- ============================================================================

return {
  {
    'L3MON4D3/LuaSnip',
    event = 'InsertEnter',
    build = 'make install_jsregexp',
    dependencies = {
      'rafamadriz/friendly-snippets',
    },
    config = function()
      local luasnip = require('luasnip')

      -- Load VSCode-style snippets from custom directory
      require('luasnip.loaders.from_vscode').lazy_load({
        paths = { vim.fn.stdpath('config') .. '/snippets' }
      })

      -- Load friendly-snippets (optional common snippets)
      require('luasnip.loaders.from_vscode').lazy_load()

      -- Keybindings for snippet navigation (Shift-Tab handled in completion.lua)
      vim.keymap.set({ 'i', 's' }, '<C-K>', function() luasnip.expand() end, { silent = true })
    end,
  },

  -- Common snippets collection
  { 'rafamadriz/friendly-snippets' },
}
