-- ============================================================================
-- Oil.nvim Configuration
-- Replaces neo-tree / vim-molder
-- ============================================================================

return {
  {
    'stevearc/oil.nvim',
    lazy = false,
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      { '-', '<cmd>Oil<cr>', desc = 'Open parent directory' },
    },
    config = function()
      require('oil').setup({
        -- Default options: https://github.com/stevearc/oil.nvim#configuration
        default_file_explorer = true,
        columns = {
          -- 'icon', -- Removed icons as per simplification plan
        },
        view_options = {
          -- Show files and directories that start with "."
          show_hidden = true,
        },
        -- Window configuration
        window = {
          max_width = 0,
          max_height = 0,
          border = "rounded",
          win_options = {
            winblend = 0,
          },
        },
      })
    end,
  },
}
