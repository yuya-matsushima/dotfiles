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
  {
    'rust-lang/rust.vim',
    ft = 'rust',
    init = function()
      vim.g.rustfmt_autosave = 1
    end,
  },

  -- Go
  { 'mattn/vim-goimports', ft = 'go' },

  -- Astro
  {
    'wuelnerdotexe/vim-astro',
    ft = 'astro',
    init = function()
      vim.g.astro_typescript = 'enable'
    end,
  },

  -- Docker
  { 'ekalinin/Dockerfile.vim', ft = 'dockerfile' },

  -- Terraform
  { 'hashivim/vim-terraform', ft = 'terraform' },

  -- Markdown
  {
    'preservim/vim-markdown',
    ft = 'markdown',
    init = function()
      vim.g.vim_markdown_folding_disabled = 1
      vim.g.vim_markdown_new_list_item_indent = 2
    end,
  },

  -- GraphQL
  { 'jparise/vim-graphql', ft = { 'graphql', 'javascript', 'typescript' } },

  -- Styled Components
  { 'styled-components/vim-styled-components', ft = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' } },

  -- JSX/TSX additional support
  { 'MaxMEllon/vim-jsx-pretty', ft = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' } },
  { 'peitalin/vim-jsx-typescript', ft = { 'typescript', 'typescriptreact' } },
}
