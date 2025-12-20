-- ============================================================================
-- LSP Configuration (Mason + nvim-lspconfig)
-- Uses Neovim 0.11+ vim.lsp.config API
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

      -- Use mason-lspconfig's setup_handlers for automatic LSP configuration
      require('mason-lspconfig').setup_handlers({
        -- Default handler for all servers
        function(server_name)
          vim.lsp.config(server_name, {
            capabilities = capabilities,
            on_attach = on_attach,
          })
          vim.lsp.enable(server_name)
        end,

        -- Rust analyzer with custom settings
        ['rust_analyzer'] = function()
          vim.lsp.config('rust_analyzer', {
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
          vim.lsp.enable('rust_analyzer')
        end,
      })
    end,
  },
}
