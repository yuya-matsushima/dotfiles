-- ============================================================================
-- lazy.nvim Plugin Manager Bootstrap
-- ============================================================================

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

-- Auto-install lazy.nvim if not present
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require('lazy').setup('plugins', {
  defaults = {
    lazy = true,  -- Enable lazy loading by default
  },
  performance = {
    rtp = {
      disabled_plugins = {
        'gzip',
        'matchit',
        'matchparen',
        'netrwPlugin',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
  checker = {
    enabled = false,  -- Don't automatically check for plugin updates
  },
  change_detection = {
    notify = false,  -- Don't notify when config changes
  },
})
