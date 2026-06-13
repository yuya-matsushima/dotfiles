-- ============================================================================
-- Discoverability & Motion
-- which-key: キーマップのポップアップ表示 (desc から自動取得)
-- flash:     ラベルジャンプ / Treesitter ノード選択 (標準 s=置換は温存し <leader>s に割当)
-- trouble:   診断 / 参照 / quickfix の一覧 UI
-- todo-comments: TODO/FIX/HACK 等のハイライト + 検索
-- ============================================================================

return {
  -- which-key: leader 配下のキーをポップアップ表示
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      preset = 'modern',
    },
    config = function(_, opts)
      local wk = require('which-key')
      wk.setup(opts)
      -- 既存の leader グループにラベルを付与
      wk.add({
        { '<leader>c', group = 'code/format' },
        { '<leader>f', group = 'find' },
        { '<leader>g', group = 'git' },
        { '<leader>m', group = 'markdown' },
        { '<leader>x', group = 'trouble/diagnostics' },
      })
    end,
  },

  -- flash: ラベルジャンプ + Treesitter 選択
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {},
    keys = {
      {
        '<leader>s',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').jump()
        end,
        desc = 'Flash jump',
      },
      {
        '<leader>S',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').treesitter()
        end,
        desc = 'Flash Treesitter',
      },
    },
  },

  -- trouble: 診断/参照/quickfix の一覧
  {
    'folke/trouble.nvim',
    cmd = 'Trouble',
    opts = {},
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics (Trouble)' },
      { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer Diagnostics (Trouble)' },
      { '<leader>xs', '<cmd>Trouble symbols toggle focus=false<cr>', desc = 'Symbols (Trouble)' },
      { '<leader>xl', '<cmd>Trouble lsp toggle focus=false win.position=right<cr>', desc = 'LSP refs/defs (Trouble)' },
      { '<leader>xq', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix (Trouble)' },
    },
  },

  -- todo-comments: TODO/FIX/HACK 等の検出・検索
  {
    'folke/todo-comments.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    -- signs は無効化 (signcolumn は gitsigns/診断と共用で狭いため)。
    -- さらに ambiwidth=double 環境ではデフォルト icon(グリフ+空白=3cell) が
    -- sign_define で E239 を起こし _setup が中断 → ハイライトも止まる。
    -- signs() を no-op に差し替えて sign_define 自体を抑止する。
    opts = {
      signs = false,
    },
    config = function(_, opts)
      require('todo-comments.config').signs = function() end
      require('todo-comments').setup(opts)
    end,
    keys = {
      {
        ']t',
        function()
          require('todo-comments').jump_next()
        end,
        desc = 'Next todo comment',
      },
      {
        '[t',
        function()
          require('todo-comments').jump_prev()
        end,
        desc = 'Prev todo comment',
      },
      { '<leader>ft', '<cmd>TodoTelescope<cr>', desc = 'Todo (Telescope)' },
      { '<leader>xt', '<cmd>Trouble todo toggle<cr>', desc = 'Todo (Trouble)' },
    },
  },
}
