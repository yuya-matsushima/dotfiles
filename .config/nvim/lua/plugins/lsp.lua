-- ============================================================================
-- LSP Configuration
-- Uses Neovim 0.11+ native LSP APIs (vim.lsp.config, vim.lsp.enable)
-- ============================================================================

-- LSP keybindings setup
local function setup_lsp_keymaps(bufnr)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, {
      buffer = bufnr,
      noremap = true,
      silent = true,
      desc = desc,
    })
  end

  -- Navigation
  map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
  map('n', 'gr', vim.lsp.buf.references, 'Go to references')
  map('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
  map('n', 'gt', vim.lsp.buf.type_definition, 'Go to type definition')

  -- Documentation
  map('n', 'K', vim.lsp.buf.hover, 'Hover documentation')

  -- Actions
  map('n', '<F2>', vim.lsp.buf.rename, 'Rename symbol')

  -- Diagnostics navigation
  map('n', 'gp', vim.diagnostic.goto_prev, 'Previous diagnostic')
  map('n', 'gn', vim.diagnostic.goto_next, 'Next diagnostic')
end

-- Diagnostic configuration
local function setup_diagnostics()
  vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
  })

  -- Show diagnostics on cursor hold
  vim.api.nvim_create_autocmd('CursorHold', {
    group = vim.api.nvim_create_augroup('LspDiagnostics', { clear = true }),
    callback = function()
      vim.diagnostic.open_float(nil, { focusable = false })
    end,
  })
end

-- LSP server configurations
local servers = {
  ts_ls = {},
  eslint = {},
  pyright = {},
  solargraph = {},
  gopls = {},
  rust_analyzer = {
    settings = {
      ['rust-analyzer'] = {
        checkOnSave = {
          command = 'clippy',
        },
      },
    },
  },
}

return {
  -- Mason: LSP server installer
  {
    'williamboman/mason.nvim',
    lazy = false,
    config = function()
      require('mason').setup()
    end,
  },

  -- nvim-lspconfig: Base LSP configuration
  {
    'neovim/nvim-lspconfig',
    lazy = false,
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      setup_diagnostics()

      -- Setup keybindings on LSP attach
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('LspKeymaps', { clear = true }),
        callback = function(args)
          setup_lsp_keymaps(args.buf)
        end,
      })
    end,
  },

  -- mason-lspconfig: Bridge between Mason and lspconfig
  {
    'williamboman/mason-lspconfig.nvim',
    lazy = false,
    dependencies = {
      'williamboman/mason.nvim',
      'neovim/nvim-lspconfig',
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- Configure LSP servers
      local function setup_server(server_name)
        local config = vim.tbl_deep_extend('force', {
          capabilities = capabilities,
        }, servers[server_name] or {})

        vim.lsp.config(server_name, config)
        vim.lsp.enable(server_name)
      end

      require('mason-lspconfig').setup({
        ensure_installed = vim.tbl_keys(servers),
        automatic_installation = true,
        handlers = {
          setup_server,
        },
      })
    end,
  },
}
