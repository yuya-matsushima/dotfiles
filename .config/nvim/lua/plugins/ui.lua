-- ============================================================================
-- UI Configuration
-- Minimalist status line and color preview (based on .vimrc style)
-- ============================================================================

-- Copilot status indicator
local function copilot_status()
  local ok, copilot = pcall(require, 'copilot.api')
  if ok and copilot.is_enabled then
    return '[AI]'
  end
  return ''
end

-- Keyboard type indicator (JIS/US)
local function keyboard_type()
  return '[' .. (vim.g.keyboard_type or 'JIS') .. ']'
end

-- Line location indicator (current/total)
local function line_location()
  local line = vim.fn.line('.')
  local total = vim.fn.line('$')
  return '[' .. string.format('%d/%d', line, total) .. ']'
end

-- File type without icon
local function filetype_no_icon()
  return '[' .. vim.bo.filetype .. ']'
end

-- Encoding with brackets
local function encoding_bracketed()
  return '[' .. vim.bo.fileencoding .. ']'
end

return {
  -- Status line: Simple and clean like .vimrc
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = {
          theme = 'auto',
          component_separators = '',
          section_separators = '',
        },
        sections = {
          -- Left side
          lualine_a = {},  -- No mode indicator (simplified)
          lualine_b = {},  -- No git branch/diff (shown in tmux)
          lualine_c = {
            {
              'filename',
              path = 1,  -- Relative path
            },
            {
              'diagnostics',
              symbols = {
                error = 'E',
                warn = 'W',
                info = 'I',
                hint = 'H',
              },
            },
          },
          -- Right side
          lualine_x = {
            { line_location, padding = 0 },  -- Line/total (leftmost on right side)
            { filetype_no_icon, padding = 0 },
            { encoding_bracketed, padding = 0 },
            { keyboard_type, padding = 0 },
            { copilot_status, padding = 0 },
          },
          lualine_y = {},
          lualine_z = {}
        },
      })
    end,
  },

  -- File icons (required by other plugins)
  { 'nvim-tree/nvim-web-devicons', lazy = true },

  -- Color preview
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
