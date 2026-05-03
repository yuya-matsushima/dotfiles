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
}
