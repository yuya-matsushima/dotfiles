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
            only_render_image_at_cursor = false,
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

  -- Markdown rendering with image support
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = 'markdown',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      '3rd/image.nvim',
    },
    config = function()
      require('render-markdown').setup({
        file_types = { 'markdown' },
        render_modes = { 'n', 'c' },
        anti_conceal = {
          enabled = true,
        },
      })
    end,
  },

  -- Markdown workflow enhancement
  {
    'jakewvincent/mkdnflow.nvim',
    ft = 'markdown',
    config = function()
      require('mkdnflow').setup({
        modules = {
          bib = true,
          buffers = true,
          conceal = true,
          cursor = true,
          folds = true,
          links = true,
          lists = true,
          maps = true,
          paths = true,
          tables = true,
          yaml = false,
        },
        filetypes = { md = true, rmd = true, markdown = true },
        create_dirs = true,
        perspective = {
          priority = 'first',
          fallback = 'current',
          root_tell = false,
          nvim_wd_heel = false,
        },
        wrap = false,
        bib = {
          default_path = nil,
          find_in_root = true,
        },
        silent = false,
        links = {
          style = 'markdown',
          name_is_source = false,
          conceal = false,
          context = 0,
          implicit_extension = nil,
          transform_implicit = false,
          transform_explicit = function(text)
            text = text:gsub(' ', '-')
            text = text:lower()
            return text
          end,
        },
        new_file_template = {
          use_template = false,
          placeholders = {
            before = {
              title = "link_title",
              date = "os_date",
            },
            after = {}
          },
          template = "# {{ title }}",
        },
        to_do = {
          symbols = {' ', '-', 'X'},
          update_parents = true,
          not_started = ' ',
          in_progress = '-',
          complete = 'X'
        },
        tables = {
          trim_whitespace = true,
          format_on_move = true,
          auto_extend_rows = false,
          auto_extend_cols = false,
        },
        yaml = {
          bib = { override = false },
        },
        mappings = {
          MkdnEnter = {{'n', 'v'}, '<CR>'},
          MkdnTab = false,
          MkdnSTab = false,
          MkdnNextLink = {'n', '<Tab>'},
          MkdnPrevLink = {'n', '<S-Tab>'},
          MkdnNextHeading = {'n', ']]'},
          MkdnPrevHeading = {'n', '[['},
          MkdnGoBack = {'n', '<BS>'},
          MkdnGoForward = {'n', '<Del>'},
          MkdnCreateLink = false,
          MkdnCreateLinkFromClipboard = {{'n', 'v'}, '<leader>p'},
          MkdnFollowLink = false,
          MkdnDestroyLink = {'n', '<M-CR>'},
          MkdnTagSpan = {'v', '<M-CR>'},
          MkdnMoveSource = {'n', '<F2>'},
          MkdnYankAnchorLink = {'n', 'yaa'},
          MkdnYankFileAnchorLink = {'n', 'yfa'},
          MkdnIncreaseHeading = {'n', '+'},
          MkdnDecreaseHeading = {'n', '-'},
          MkdnToggleToDo = {{'n', 'v'}, '<C-Space>'},
          MkdnNewListItem = false,
          MkdnNewListItemBelowInsert = {'n', 'o'},
          MkdnNewListItemAboveInsert = {'n', 'O'},
          MkdnExtendList = false,
          MkdnUpdateNumbering = {'n', '<leader>nn'},
          MkdnTableNextCell = {'i', '<Tab>'},
          MkdnTablePrevCell = {'i', '<S-Tab>'},
          MkdnTableNextRow = false,
          MkdnTablePrevRow = {'i', '<M-CR>'},
          MkdnTableNewRowBelow = {'n', '<leader>ir'},
          MkdnTableNewRowAbove = {'n', '<leader>iR'},
          MkdnTableNewColAfter = {'n', '<leader>ic'},
          MkdnTableNewColBefore = {'n', '<leader>iC'},
          MkdnFoldSection = {'n', '<leader>f'},
          MkdnUnfoldSection = {'n', '<leader>F'},
        }
      })
    end,
  },

  -- Visual enhancement for markdown headings and code blocks
  {
    'lukas-reineke/headlines.nvim',
    ft = 'markdown',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('headlines').setup({
        markdown = {
          query = vim.treesitter.query.parse(
            'markdown',
            [[
              (atx_heading [
                (atx_h1_marker)
                (atx_h2_marker)
                (atx_h3_marker)
                (atx_h4_marker)
                (atx_h5_marker)
                (atx_h6_marker)
              ] @headline)

              (thematic_break) @dash

              (fenced_code_block) @codeblock

              (block_quote_marker) @quote
              (block_quote (paragraph (inline (block_continuation) @quote)))
              (block_quote (paragraph (block_continuation) @quote))
              (block_quote (block_continuation) @quote)
            ]]
          ),
          headline_highlights = {
            'Headline1',
            'Headline2',
            'Headline3',
            'Headline4',
            'Headline5',
            'Headline6',
          },
          bullet_highlights = {
            '@text.title.1.marker.markdown',
            '@text.title.2.marker.markdown',
            '@text.title.3.marker.markdown',
            '@text.title.4.marker.markdown',
            '@text.title.5.marker.markdown',
            '@text.title.6.marker.markdown',
          },
          bullets = { '◉', '○', '✸', '✿' },
          codeblock_highlight = 'CodeBlock',
          dash_highlight = 'Dash',
          dash_string = '-',
          quote_highlight = 'Quote',
          quote_string = '┃',
          fat_headlines = true,
          fat_headline_upper_string = '▃',
          fat_headline_lower_string = '🬂',
        },
      })

      -- Custom highlight groups
      vim.cmd([[
        highlight Headline1 guibg=#1e2718
        highlight Headline2 guibg=#21262d
        highlight Headline3 guibg=#1c1c26
        highlight Headline4 guibg=#1e2029
        highlight Headline5 guibg=#1e202a
        highlight Headline6 guibg=#1c1f24
        highlight CodeBlock guibg=#1c1c1c
        highlight Dash guibg=#1c1c1c guifg=#6c6c6c
        highlight Quote guifg=#6c6c6c
      ]])
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
