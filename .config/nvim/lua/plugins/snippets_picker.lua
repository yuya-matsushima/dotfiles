-- ============================================================================
-- Snippet Picker (Custom Telescope picker for LuaSnip)
-- Deduplicates snippets with multiple prefixes, showing each snippet once
-- ============================================================================

local function snippets_picker()
  local luasnip = require('luasnip')
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local entry_display = require('telescope.pickers.entry_display')

  -- Collect snippets, deduplicating by (filetype, name)
  local seen = {}
  local results = {}
  local available = luasnip.available()

  for ft, snippets in pairs(available) do
    local filetype = ft == '' and '-' or ft
    for _, snippet in ipairs(snippets) do
      local key = filetype .. ':' .. snippet.name
      if not seen[key] then
        seen[key] = true
        table.insert(results, {
          ft = filetype,
          name = snippet.name,
          trigger = snippet.trigger,
          description = snippet.description and snippet.description[1] or '',
        })
      end
    end
  end

  local displayer = entry_display.create({
    separator = ' ',
    items = { { width = 12 }, { width = 24 }, { width = 20 }, { remaining = true } },
  })

  pickers
    .new({}, {
      prompt_title = 'Snippets',
      finder = finders.new_table({
        results = results,
        entry_maker = function(entry)
          return {
            value = entry,
            display = function(e)
              return displayer({
                e.value.ft,
                e.value.name,
                { e.value.trigger, 'TelescopeResultsNumber' },
                e.value.description,
              })
            end,
            ordinal = entry.ft .. ' ' .. entry.name .. ' ' .. entry.trigger .. ' ' .. entry.description,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function()
        actions.select_default:replace(function(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          local trigger = selection.value.trigger
          local snippets_to_expand = {}
          luasnip.available(function(snippet)
            if snippet.trigger == trigger then
              table.insert(snippets_to_expand, snippet)
            end
            return nil
          end)

          if #snippets_to_expand > 0 then
            vim.cmd(':startinsert!')
            vim.defer_fn(function()
              luasnip.snip_expand(snippets_to_expand[1])
            end, 50)
          end
        end)
        return true
      end,
    })
    :find()
end

return snippets_picker
