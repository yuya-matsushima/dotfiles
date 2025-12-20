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
      { '-', '<cmd>Neotree reveal<cr>', desc = 'Open Neo-tree at current file' },
    },
    config = function()
      require('neo-tree').setup({
        close_if_last_window = false,
        enable_git_status = true,
        enable_diagnostics = true,
        default_component_configs = {
          indent = {
            with_expanders = true,
            expander_collapsed = "",
            expander_expanded = "",
          },
        },
        filesystem = {
          filtered_items = {
            hide_dotfiles = false,  -- Match g:molder_show_hidden=1
            hide_gitignored = false,
          },
          follow_current_file = {
            enabled = true,
          },
          -- Automatically expand current directory
          use_libuv_file_watcher = true,
        },
        window = {
          position = "left",
          width = 30,
        },
      })
    end,
  },
}
