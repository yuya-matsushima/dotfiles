-- ============================================================================
-- Treesitter Configuration (nvim-treesitter main branch, Neovim 0.12+)
--
-- master ブランチは Nvim 0.12 と API 非互換 (nvim-treesitter#8618) のため
-- main ブランチへ移行。main は full rewrite で `nvim-treesitter.configs` を廃止し,
-- highlight / indent を自動では有効化しないため, FileType autocmd で明示的に起動する。
-- ============================================================================

-- Treesitter でハイライトを有効化する filetype 一覧。
-- parser 名と filetype 名が異なるもの (markdown_inline など) は対応する filetype を列挙する。
local ENABLED_FILETYPES = {
  'bash',
  'css',
  'go',
  'html',
  'javascript',
  'javascriptreact',
  'json',
  'lua',
  'markdown',
  'python',
  'query',
  'ruby',
  'rust',
  'toml',
  'tsx',
  'typescript',
  'typescriptreact',
  'vim',
  'vimdoc',
  'yaml',
}

-- インストールする parser 一覧 (parser 名ベース)。
local ENSURE_INSTALLED = {
  'bash',
  'css',
  'go',
  'html',
  'javascript',
  'json',
  'lua',
  'markdown',
  'markdown_inline',
  'python',
  'query',
  'ruby',
  'rust',
  'toml',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'yaml',
}

-- ============================================================================
-- Incremental Selection (master branch 相当の代替実装)
-- main branch では incremental_selection が廃止されたため, Neovim 組み込みの
-- vim.treesitter API で同等機能を提供する。<C-n> で拡張, <C-p> で縮小, <C-s> で scope まで拡張。
-- ============================================================================
local function setup_incremental_selection(bufnr)
  local stack = {}

  local function select_node(node)
    if not node then return end
    local srow, scol, erow, ecol = node:range()
    vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
    vim.cmd('normal! v')
    -- 終端は exclusive なので 1 文字戻す
    local end_col = ecol > 0 and ecol - 1 or 0
    local end_row = ecol > 0 and erow or math.max(erow - 1, 0)
    vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
  end

  local function init_selection()
    local node = vim.treesitter.get_node()
    if not node then return end
    stack = { node }
    select_node(node)
  end

  local function node_incremental()
    local top = stack[#stack]
    if not top then
      init_selection()
      return
    end
    local parent = top:parent()
    if parent then
      table.insert(stack, parent)
      select_node(parent)
    end
  end

  local function scope_incremental()
    local top = stack[#stack]
    if not top then
      init_selection()
      return
    end
    local node = top:parent()
    while node and node:named() == false do
      node = node:parent()
    end
    if node then
      table.insert(stack, node)
      select_node(node)
    end
  end

  local function node_decremental()
    if #stack <= 1 then return end
    table.remove(stack)
    select_node(stack[#stack])
  end

  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set('n', '<C-n>', init_selection, vim.tbl_extend('force', opts, { desc = 'TS: init selection' }))
  vim.keymap.set('x', '<C-n>', node_incremental, vim.tbl_extend('force', opts, { desc = 'TS: node incremental' }))
  vim.keymap.set('x', '<C-s>', scope_incremental, vim.tbl_extend('force', opts, { desc = 'TS: scope incremental' }))
  vim.keymap.set('x', '<C-p>', node_decremental, vim.tbl_extend('force', opts, { desc = 'TS: node decremental' }))
end

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false, -- main branch は lazy-load 非対応
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').setup({
        install_dir = vim.fn.stdpath('data') .. '/site',
      })

      -- 必要な parser を (未導入ならば) インストール。非同期で走る。
      require('nvim-treesitter').install(ENSURE_INSTALLED)

      -- 対象 filetype で highlight / indent / incremental selection を有効化
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('user_treesitter', { clear = true }),
        pattern = ENABLED_FILETYPES,
        callback = function(args)
          local bufnr = args.buf

          -- parser が未インストールだと vim.treesitter.start() がエラーを投げるので pcall
          local ok, err = pcall(vim.treesitter.start, bufnr)
          if not ok then
            vim.schedule(function()
              vim.notify(
                ('nvim-treesitter: failed to start for %s: %s'):format(args.match, err),
                vim.log.levels.DEBUG
              )
            end)
            return
          end

          -- Indent (experimental)
          vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

          -- Incremental selection
          setup_incremental_selection(bufnr)
        end,
      })
    end,
  },
}
