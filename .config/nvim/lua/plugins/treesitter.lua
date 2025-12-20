-- ============================================================================
-- Treesitter Configuration
-- Replaces vim-javascript, typescript-vim, and other syntax plugins
-- ============================================================================

return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = {
          'typescript',
          'tsx',
          'javascript',
          'jsx',
          'ruby',
          'go',
          'rust',
          'python',
          'vue',
          'astro',
          'graphql',
          'dockerfile',
          'terraform',
          'markdown',
          'markdown_inline',
          'css',
          'scss',
          'html',
          'lua',
          'vim',
          'bash',
          'json',
          'yaml',
        },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
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
