-- ============================================================================
-- GitHub Copilot Configuration
-- Replaces copilot.vim with copilot.lua
-- ============================================================================

return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      -- Check environment variable
      local enabled = vim.env.DISABLE_COPILOT ~= '1'

      -- asdf のグローバル Node.js (lts) を使用 (ディレクトリ固有の設定を無視)
      local asdf_node = vim.fn.system('ASDF_NODEJS_VERSION=lts asdf where nodejs 2>/dev/null'):gsub('\n', '')
      local node_path = asdf_node ~= '' and (asdf_node .. '/bin/node') or 'node'

      require('copilot').setup({
        copilot_node_command = node_path,
        panel = {
          enabled = false,
        },
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 75,
          keymap = {
            accept = false,          -- Handled by Smart Tab in completion.lua
            accept_word = false,
            accept_line = false,
            next = '<M-]>',
            prev = '<M-[>',
            dismiss = '<C-]>',
          },
        },
        filetypes = {
          ['*'] = enabled,
          gitcommit = enabled,
          markdown = enabled,
        },
      })
    end,
  },

  -- Copilot CMP integration
  {
    'zbirenbaum/copilot-cmp',
    dependencies = { 'zbirenbaum/copilot.lua' },
    config = function()
      require('copilot_cmp').setup()
    end,
  },

  -- Copilot Chat
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'zbirenbaum/copilot.lua' },
      { 'nvim-lua/plenary.nvim' },
    },
    cmd = 'CopilotChat',
    keys = {
      { '<leader>cc', '<cmd>CopilotChatToggle<cr>', desc = 'Toggle Copilot Chat' },
      { '<leader>ce', '<cmd>CopilotChatExplain<cr>', desc = 'Explain code', mode = { 'n', 'v' } },
      { '<leader>cr', '<cmd>CopilotChatReview<cr>', desc = 'Review code', mode = { 'n', 'v' } },
      { '<leader>cf', '<cmd>CopilotChatFix<cr>', desc = 'Fix code', mode = { 'n', 'v' } },
      { '<leader>co', '<cmd>CopilotChatOptimize<cr>', desc = 'Optimize code', mode = { 'n', 'v' } },
      { '<leader>cd', '<cmd>CopilotChatDocs<cr>', desc = 'Generate docs', mode = { 'n', 'v' } },
      { '<leader>ct', '<cmd>CopilotChatTests<cr>', desc = 'Generate tests', mode = { 'n', 'v' } },
    },
    config = function()
      require('CopilotChat').setup({
        debug = false,
        show_help = 'yes',
        prompts = {
          Explain = 'コードを日本語で説明してください。',
          Review = 'コードをレビューしてください。改善点を日本語で教えてください。',
          Tests = 'このコードのテストを書いてください。',
          Fix = 'このコードのバグを修正してください。',
          Optimize = 'このコードを最適化してパフォーマンスを改善してください。',
          Docs = 'このコードのドキュメントを書いてください。',
        },
      })
    end,
  },
}
