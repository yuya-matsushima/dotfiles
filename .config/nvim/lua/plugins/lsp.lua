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
  lua_ls = {},
  ts_ls = {},
  eslint = {},
  pyright = {
    settings = {
      pyright = {
        -- ruff に任せるため pyright の import 整理を無効化
        disableOrganizeImports = true,
      },
      python = {
        analysis = {
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = 'openFilesOnly',
        },
      },
    },
  },
  ruff = {},
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
  -- vscode-langservers-extracted 由来 (mason: html-lsp / css-lsp / json-lsp)
  html = {},
  cssls = {},
  jsonls = {},
  -- yaml-language-server
  yamlls = {},
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

      -- Python: LSP 起動前に .venv を検出して設定をマージ
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('PythonVenvDetect', { clear = true }),
        pattern = 'python',
        callback = function(args)
          local root = vim.fs.root(args.buf, { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' })
          if not root then
            return
          end
          local venv_python = root .. '/.venv/bin/python'
          if vim.uv.fs_stat(venv_python) then
            vim.lsp.config('pyright', {
              settings = {
                python = { pythonPath = venv_python },
              },
            })
            vim.lsp.config('ruff', {
              init_options = {
                settings = { interpreter = { venv_python } },
              },
            })
          end
        end,
      })

      -- Setup keybindings on LSP attach
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('LspKeymaps', { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          -- ruff の hover を無効化（pyright に任せる）
          if client and client.name == 'ruff' then
            client.server_capabilities.hoverProvider = false
          end
          setup_lsp_keymaps(args.buf)
        end,
      })

      -- 保存時フォーマットは conform.nvim (plugins/conform.lua) に集約。
      -- formatters_by_ft + lsp_format = 'fallback' で言語別に宣言的に管理する。
    end,
  },

  -- mason-lspconfig: Bridge between Mason and lspconfig
  -- v2 (Neovim 0.11+ native LSP) では handlers / automatic_installation が廃止され、
  -- vim.lsp.config() で設定し automatic_enable(既定 true) が vim.lsp.enable を実行する。
  {
    'williamboman/mason-lspconfig.nvim',
    lazy = false,
    dependencies = {
      'williamboman/mason.nvim',
      'neovim/nvim-lspconfig',
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      -- 全サーバ共通の capabilities (nvim-cmp) をグローバル '*' にマージ
      vim.lsp.config('*', {
        capabilities = require('cmp_nvim_lsp').default_capabilities(),
      })

      -- サーバ個別設定 (settings 等を持つものだけ)
      for name, cfg in pairs(servers) do
        if next(cfg) ~= nil then
          vim.lsp.config(name, cfg)
        end
      end

      -- ensure_installed で導入。automatic_enable が installed なサーバを自動有効化する。
      require('mason-lspconfig').setup({
        ensure_installed = vim.tbl_keys(servers),
      })
    end,
  },
}
