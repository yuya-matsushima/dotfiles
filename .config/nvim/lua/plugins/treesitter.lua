-- ============================================================================
-- Treesitter Configuration
-- Provides syntax highlighting and code understanding using Tree-sitter
-- ============================================================================

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require('nvim-treesitter.configs').setup({
        -- Automatically install missing parsers when entering buffer
        auto_install = true,

        -- Syntax Highlighting
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },

        -- Smart Indentation
        indent = {
          enable = true,
        },

        -- Incremental Selection (expand/shrink selection based on syntax tree)
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<C-n>',
            node_incremental = '<C-n>',
            scope_incremental = '<C-s>',
            node_decremental = '<C-p>',
          },
        },
      })
    end,
  },
}
