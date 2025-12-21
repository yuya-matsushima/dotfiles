-- ============================================================================
-- Completion Configuration (nvim-cmp)
-- Replaces asyncomplete with Smart Tab function
-- ============================================================================

return {
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      'hrsh7th/cmp-nvim-lua',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'zbirenbaum/copilot-cmp',
      'onsails/lspkind.nvim',
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')

      -- Helper function to check if there are words before cursor
      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        if col == 0 then
          return false
        end
        local line_content = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
        if not line_content then
          return false
        end
        return line_content:sub(col, col):match('%s') == nil
      end

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },

        mapping = {
          -- Smart Tab: Copilot → Snippet → Completion → Default
          ['<Tab>'] = cmp.mapping(function(fallback)
            -- Check if Copilot suggestion is available (copilot.lua)
            local ok, copilot = pcall(require, 'copilot.suggestion')
            if ok and copilot.is_visible() then
              copilot.accept()
            -- Check if completion menu is visible
            elseif cmp.visible() then
              cmp.select_next_item()
            -- Check if snippet is expandable or jumpable
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            -- Trigger completion if there are words before cursor
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { 'i', 's' }),

          -- Shift-Tab: Reverse direction
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),

          -- Ctrl+n: Next item
          ['<C-n>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end, { 'i', 's' }),

          -- Ctrl+p: Previous item
          ['<C-p>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { 'i', 's' }),

          -- Enter: Accept completion
          ['<CR>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.confirm({ select = false })
            else
              fallback()
            end
          end),

          -- Ctrl-Space: Manually trigger completion
          ['<C-Space>'] = cmp.mapping.complete(),
        },

        sources = cmp.config.sources({
          { name = 'nvim_lsp', priority = 1000 },
          { name = 'nvim_lua', priority = 900 },
          { name = 'luasnip', priority = 750 },
          { name = 'copilot', priority = 500 },
          { name = 'buffer', priority = 250 },
          { name = 'path', priority = 100 },
        }),

        -- Formatting with icons
        formatting = {
          format = require('lspkind').cmp_format({
            mode = 'symbol_text',  -- Show icon + text
            maxwidth = 50,
            ellipsis_char = '...',
            before = function(entry, vim_item)
              local source_names = {
                nvim_lsp = '[LSP]',
                nvim_lua = '[Lua]',
                luasnip = '[Snip]',
                copilot = '[AI]',
                buffer = '[Buf]',
                path = '[Path]',
                cmdline = '[Cmd]',
              }
              vim_item.menu = source_names[entry.source.name] or '[?]'
              return vim_item
            end,
          }),
        },

        -- Window appearance
        window = {
          completion = {
            max_width = 60,  -- Maximum width of completion menu
            max_height = 15, -- Maximum height
            border = 'rounded',
            winhighlight = 'Normal:Pmenu,FloatBorder:Pmenu,Search:None',
          },
          documentation = {
            max_width = 80,
            max_height = 20,
            border = 'rounded',
            winhighlight = 'Normal:Pmenu,FloatBorder:Pmenu,Search:None',
          },
        },

        -- Match asyncomplete settings
        completion = {
          autocomplete = { require('cmp.types').cmp.TriggerEvent.TextChanged },
          completeopt = 'menuone,noinsert,noselect',
        },

        experimental = {
          ghost_text = false,
        },
      })

      -- Cmdline completion for '/' (search)
      cmp.setup.cmdline('/', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })

      -- Cmdline completion for ':' (commands)
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline', option = { ignore_cmds = { 'Man', '!' } } }
        })
      })

      -- Integrate with nvim-autopairs if available
      local ok, cmp_autopairs = pcall(require, 'nvim-autopairs.completion.cmp')
      if ok then
        cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
      end
    end,
  },

  -- LSP source
  { 'hrsh7th/cmp-nvim-lsp' },

  -- Buffer source
  { 'hrsh7th/cmp-buffer' },

  -- Path source
  { 'hrsh7th/cmp-path' },

  -- LuaSnip source
  { 'saadparwaiz1/cmp_luasnip' },
}
