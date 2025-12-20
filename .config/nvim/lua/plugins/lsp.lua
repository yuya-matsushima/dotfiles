-- ============================================================================
-- LSP Configuration (Mason + nvim-lspconfig)
-- Replaces vim-lsp + asyncomplete
-- ============================================================================

return {
  -- Mason: LSP server installer
  {
    'williamboman/mason.nvim',
    lazy = false,
    config = function()
      require('mason').setup()
    end,
  },

  -- Mason-LSP bridge
  {
    'williamboman/mason-lspconfig.nvim',
    lazy = false,
    dependencies = { 'williamboman/mason.nvim' },
    config = function()
      require('mason-lspconfig').setup({
        ensure_installed = {
          'ts_ls',           -- TypeScript/JavaScript (formerly tsserver)
          'eslint',          -- ESLint
          'pyright',         -- Python
          'solargraph',      -- Ruby
          'gopls',           -- Go
          'rust_analyzer',   -- Rust
        },
        automatic_installation = true,
      })
    end,
  },

  -- LSP Config
  {
    'neovim/nvim-lspconfig',
    lazy = false,
    dependencies = {
      'williamboman/mason-lspconfig.nvim',
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- Keybindings (match vim-lsp mappings)
      local on_attach = function(client, bufnr)
        local opts = { buffer = bufnr, noremap = true, silent = true }
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', 'gp', vim.diagnostic.goto_prev, opts)
        vim.keymap.set('n', 'gn', vim.diagnostic.goto_next, opts)
      end

      -- Diagnostic settings (match .vimrc settings)
      vim.diagnostic.config({
        virtual_text = false,  -- Disabled in .vimrc
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- Show diagnostics on cursor hold (match echo_cursor behavior)
      vim.api.nvim_create_autocmd('CursorHold', {
        callback = function()
          vim.diagnostic.open_float(nil, { focusable = false })
        end,
      })

      -- TypeScript/JavaScript
      lspconfig.ts_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- ESLint
      lspconfig.eslint.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- Python
      lspconfig.pyright.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- Ruby
      lspconfig.solargraph.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- Go
      lspconfig.gopls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- Rust
      lspconfig.rust_analyzer.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          ['rust-analyzer'] = {
            checkOnSave = {
              command = 'clippy',
            },
          },
        },
      })
    end,
  },
}
