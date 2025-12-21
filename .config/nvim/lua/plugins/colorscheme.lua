return {
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("nightfox").setup({
        options = {
          transparent = true,
          terminal_colors = true,
        },
        groups = {
          all = {
            TelescopeNormal = { bg = "bg1" },
            TelescopeBorder = { fg = "bg1", bg = "bg1" },
            TelescopeTitle = { fg = "fg1", bg = "bg1" },
            TelescopePreviewNormal = { bg = "bg0" },
            TelescopePreviewBorder = { fg = "bg0", bg = "bg0" },
            TelescopePreviewTitle = { fg = "fg1", bg = "bg0" },
            TelescopePromptNormal = { bg = "bg2" },
            TelescopePromptBorder = { fg = "bg2", bg = "bg2" },
            TelescopePromptTitle = { fg = "fg1", bg = "bg2" },
          },
        },
      })

      vim.cmd("colorscheme nightfox")
    end,
  },
}
