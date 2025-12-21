-- ============================================================================
-- Language-Specific Plugins
-- Plugins without better Neovim alternatives
-- ============================================================================

return {
  -- Ruby/Rails support
  { 'tpope/vim-rails', ft = 'ruby' },
  { 'tpope/vim-endwise', ft = { 'ruby', 'vim' } },

  -- Template engines
  { 'slim-template/vim-slim', ft = 'slim' },
  { 'tpope/vim-haml', ft = 'haml' },

  -- Rust
  -- Note: Syntax highlighting is handled by Treesitter, but this plugin provides
  -- extra functionality like automatic formatting (rustfmt).
  {
    'rust-lang/rust.vim',
    ft = 'rust',
    init = function()
      vim.g.rustfmt_autosave = 1
    end,
  },

  -- Go
  { 'mattn/vim-goimports', ft = 'go' },
}
