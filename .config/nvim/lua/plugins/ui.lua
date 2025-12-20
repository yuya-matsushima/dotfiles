-- ============================================================================
-- UI Configuration
-- Status line, icons, and color preview
-- ============================================================================

return {
  -- Status line
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      -- Function to check Copilot status
      local function copilot_status()
        local ok, copilot = pcall(require, 'copilot.api')
        if ok and copilot.is_enabled then
          return '[AI]'
        end
        return ''
      end

      -- Function to get keyboard type
      local function keyboard_type()
        return '[' .. (vim.g.keyboard_type or 'JIS') .. ']'
      end

      require('lualine').setup({
        options = {
          theme = 'auto',
          component_separators = '',
          section_separators = '',
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = {
            {
              'filename',
              path = 1,  -- Relative path
            }
          },
          lualine_x = {
            copilot_status,
            keyboard_type,
            'encoding',
            'fileformat',
            'filetype',
          },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        },
      })
    end,
  },

  -- File icons
  { 'nvim-tree/nvim-web-devicons', lazy = true },

  -- Color preview (replaces vim-css-color)
  {
    'NvChad/nvim-colorizer.lua',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('colorizer').setup({
        filetypes = { '*' },
        user_default_options = {
          RGB = true,
          RRGGBB = true,
          names = true,
          RRGGBBAA = true,
          rgb_fn = true,
          hsl_fn = true,
          css = true,
          css_fn = true,
        },
      })
    end,
  },
}
