-- ============================================================================
-- Editor Enhancement
-- Auto-close tags and EditorConfig support
-- ============================================================================

return {
  -- Auto-close HTML/JSX tags using Tree-sitter
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

  -- EditorConfig: Maintain consistent coding styles
  {
    'editorconfig/editorconfig-vim',
    event = { 'BufReadPre', 'BufNewFile' },
    init = function()
      -- Disable for commit messages to preserve git defaults
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'gitcommit', 'hgcommit' },
        callback = function()
          vim.b.EditorConfig_disable = 1
        end,
      })
    end,
  },

  -- Auto-pairs: Automatic bracket/quote pairing
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup({
        check_ts = true,  -- Use TreeSitter for context-aware pairing
        ts_config = {
          lua = { 'string' },  -- Disable in Lua strings
          javascript = { 'template_string' },  -- Disable in JS template strings
        },
        fast_wrap = {
          map = '<M-e>',  -- Alt-e for fast wrapping
        },
      })
    end,
  },
}
