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

      require('copilot').setup({
        panel = {
          enabled = false,
        },
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 75,
          keymap = {
            accept = '<C-L>',        -- Alternative to Tab
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
}
