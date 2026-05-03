local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

vim.filetype.add({
  extension = {
    ["md.erb"] = "markdown",
    ["envrc"] = "sh",
    ["scss.css"] = "scss",
  },
  pattern = {
    [".*%.sql"] = "mysql",
  },
})

local ft_settings = {
  [{ 'html', 'css', 'javascript', 'markdown', 'slim', 'haml' }] = { tabstop = 2, shiftwidth = 2 },
  [{ 'php', 'python' }] = { tabstop = 4, shiftwidth = 4, textwidth = 80 },
  [{ 'go' }] = { expandtab = false, tabstop = 2, shiftwidth = 2 },
  [{ 'gitcommit', 'hgcommit' }] = { foldenable = false, textwidth = 72, colorcolumn = '+1' },
  [{ 'rst' }] = { textwidth = 80, colorcolumn = '+1' },
  [{ 'javascript', 'coffee' }] = { textwidth = 80 },
  [{ 'scss', 'css' }] = { foldmethod = 'marker', foldmarker = '{,}' },
  [{ 'html', 'xhtml' }] = { foldmethod = 'indent' },
  [{ 'quickrun', 'oil' }] = { foldenable = false },
}

local config_group = augroup('MyFTConfig', { clear = true })
for types, settings in pairs(ft_settings) do
  autocmd('FileType', {
    group = config_group,
    pattern = types,
    callback = function()
      for opt, val in pairs(settings) do
        vim.opt_local[opt] = val
      end
    end,
  })
end

-- Disable builtin EditorConfig for commit message buffers.
-- BufReadPre fires before BufRead, so vim.b.editorconfig = false is observed
-- by the builtin's BufRead callback before it applies .editorconfig properties.
autocmd({ 'BufReadPre', 'BufNewFile' }, {
  group = config_group,
  pattern = {
    'COMMIT_EDITMSG',
    'MERGE_MSG',
    'TAG_EDITMSG',
    'NOTES_EDITMSG',
    'PULL_REQUEST_EDITMSG',
    'git-rebase-todo',
    'hg-editor-*.txt',
  },
  callback = function()
    vim.b.editorconfig = false
  end,
})

local buffer_group = augroup('BufferEvents', { clear = true })

autocmd('BufWritePre', {
  group = buffer_group,
  callback = function()
    local utils_trim = require('utils.trim')
    utils_trim.RTrim()
    utils_trim.LTrimTabAndSpace()

    -- if vim.bo.filetype == 'markdown' then
    --   require('utils.comma').ToComma()
    -- end
  end,
})

-- Change Directory
autocmd('BufEnter', {
  group = buffer_group,
  callback = function()
    require('utils.lcd').changeDir()
  end,
})

-- Disable saving files with forbidden names like ":" or ";"
autocmd('BufWritePre', {
  group = buffer_group,
  pattern = { ':*', ';*' },
  callback = function()
    vim.api.nvim_err_writeln('Forbidden file name: ' .. vim.fn.expand('<afile>'))
    return true -- 保存を中断させたい場合はここで制御を検討
  end,
})
