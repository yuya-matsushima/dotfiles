-- ============================================================================
-- Editor Enhancement Plugins
-- Auto-close tags, EditorConfig support
-- ============================================================================

return {
  -- Auto-close HTML/JSX tags (replaces vim-closetag)
  {
    'windwp/nvim-ts-autotag',
    event = 'InsertEnter',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('nvim-ts-autotag').setup({
        filetypes = {
          'html',
          'javascript',
          'typescript',
          'javascriptreact',
          'typescriptreact',
          'vue',
          'xml',
          'php',
          'eruby',
        },
      })
    end,
  },

  -- EditorConfig support
  {
    'editorconfig/editorconfig-vim',
    event = { 'BufReadPre', 'BufNewFile' },
    init = function()
      -- Disable for git commit messages (match .vimrc)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'gitcommit', 'hgcommit' },
        callback = function()
          vim.b.EditorConfig_disable = 1
        end,
      })
    end,
  },
}
