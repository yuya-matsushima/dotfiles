-- ============================================================================
-- Editor Enhancement
-- Auto-close tags and EditorConfig support
-- ============================================================================

return {
  -- Auto-close HTML/JSX tags using Tree-sitter
  {
    'windwp/nvim-ts-autotag',
    event = 'InsertEnter',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('nvim-ts-autotag').setup({
        filetypes = {
          'html',
          'javascript',
          'typescript',
          'javascriptreact',
          'typescriptreact',
          'vue',
          'xml',
          'php',
          'eruby',
        },
      })
    end,
  },

  -- EditorConfig: Maintain consistent coding styles
  {
    'editorconfig/editorconfig-vim',
    event = { 'BufReadPre', 'BufNewFile' },
    init = function()
      -- Disable for commit messages to preserve git defaults
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'gitcommit', 'hgcommit' },
        callback = function()
          vim.b.EditorConfig_disable = 1
        end,
      })
    end,
  },

  -- Auto-pairs: Automatic bracket/quote pairing
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup({
        check_ts = true,  -- Use TreeSitter for context-aware pairing
        ts_config = {
          lua = { 'string' },  -- Disable in Lua strings
          javascript = { 'template_string' },  -- Disable in JS template strings
        },
        fast_wrap = {
          map = '<M-e>',  -- Alt-e for fast wrapping
        },
      })
    end,
  },

  -- Image rendering in terminal
  {
    '3rd/image.nvim',
    ft = 'markdown',
    config = function()
      require('image').setup({
        backend = 'kitty',  -- Ghostty + tmux: Kitty protocol with passthrough
        tmux_show_only_in_active_window = true,
        integrations = {
          markdown = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = true,
            filetypes = { 'markdown', 'vimwiki' },
          },
        },
        max_width = nil,
        max_height = nil,
        max_width_window_percentage = nil,
        max_height_window_percentage = 50,
        window_overlap_clear_enabled = false,
        window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', '' },
      })
    end,
  },

  -- Clipboard image paste for Markdown
  {
    'HakonHarnes/img-clip.nvim',
    ft = 'markdown',
    opts = {
      default = {
        dir_path = 'images',
        prompt_for_file_name = true,
        file_name = '%Y%m%d-%H%M%S',
        use_absolute_path = false,
        relative_to_current_file = true,
        template = '![$CURSOR]($FILE_PATH)',
        url_encode_path = true,
      },
    },
  },

  -- Quick code execution
  {
    'thinca/vim-quickrun',
    keys = {
      { 'qq', '<Plug>(quickrun)', desc = 'QuickRun' },
    },
    config = function()
      vim.g.quickrun_config = {
        ['_'] = {
          outputter = 'buffer',
          ['outputter/buffer/split'] = ':botright 8sp',
          ['outputter/buffer/close_on_empty'] = 1,
        },
      }
    end,
  },

  -- Markdown preview in browser
  {
    'iamcco/markdown-preview.nvim',
    ft = 'markdown',
    build = 'cd app && npx --yes yarn install',
    config = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_refresh_slow = 0
      vim.g.mkdp_command_for_global = 0
      vim.g.mkdp_open_to_the_world = 0
      vim.g.mkdp_open_ip = ''
      vim.g.mkdp_browser = ''
      vim.g.mkdp_echo_preview_url = 0
      vim.g.mkdp_browserfunc = ''
      vim.g.mkdp_preview_options = {
        mkit = {},
        katex = {},
        uml = {},
        maid = {},
        disable_sync_scroll = 0,
        sync_scroll_type = 'middle',
        hide_yaml_meta = 1,
        sequence_diagrams = {},
        flowchart_diagrams = {},
        content_editable = false,
        disable_filename = 0,
        toc = {}
      }
      vim.g.mkdp_markdown_css = ''
      vim.g.mkdp_highlight_css = ''
      vim.g.mkdp_port = ''
      vim.g.mkdp_page_title = '「${name}」'
      vim.g.mkdp_filetypes = { 'markdown' }
      vim.g.mkdp_theme = 'dark'

      -- Keymaps
      vim.keymap.set('n', '<leader>mp', '<Plug>MarkdownPreview', { desc = 'Markdown Preview' })
      vim.keymap.set('n', '<leader>ms', '<Plug>MarkdownPreviewStop', { desc = 'Markdown Preview Stop' })
      vim.keymap.set('n', '<leader>mt', '<Plug>MarkdownPreviewToggle', { desc = 'Markdown Preview Toggle' })
    end,
  },
}
