-- ============================================================================
-- Neo-tree Configuration
-- Replaces vim-molder
-- ============================================================================

return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    cmd = 'Neotree',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    keys = {
      { '-', '<cmd>Neotree toggle<cr>', desc = 'Toggle Neo-tree' },
    },
    config = function()
      require('neo-tree').setup({
        close_if_last_window = false,
        enable_git_status = true,
        enable_diagnostics = true,
        filesystem = {
          filtered_items = {
            hide_dotfiles = false,  -- Match g:molder_show_hidden=1
            hide_gitignored = false,
          },
          follow_current_file = {
            enabled = true,
          },
        },
      })
    end,
  },
}
