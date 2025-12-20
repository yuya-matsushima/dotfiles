-- ============================================================================
-- Autocommands Configuration
-- Migrated from .vimrc lines 173-297
-- ============================================================================

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- ============================================================================
-- INDENTATION SETTINGS
-- ============================================================================

local indent_group = augroup('IndentSettings', { clear = true })

autocmd('FileType', {
  group = indent_group,
  pattern = { 'html', 'css', 'javascript', 'markdown', 'slim', 'haml' },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})

autocmd('FileType', {
  group = indent_group,
  pattern = { 'php', 'python' },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

autocmd('FileType', {
  group = indent_group,
  pattern = 'go',
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})

-- ============================================================================
-- FOLDING SETTINGS
-- ============================================================================

local fold_group = augroup('FoldingSettings', { clear = true })

autocmd('FileType', {
  group = fold_group,
  pattern = { 'gitcommit', 'hgcommit', 'quickrun', 'neo-tree' },
  callback = function()
    vim.opt_local.foldenable = false
  end,
})

autocmd('FileType', {
  group = fold_group,
  pattern = { 'scss', 'css' },
  callback = function()
    vim.opt_local.foldmethod = 'marker'
    vim.opt_local.foldmarker = '{,}'
  end,
})

autocmd('FileType', {
  group = fold_group,
  pattern = { 'html', 'xhtml' },
  callback = function()
    vim.opt_local.foldmethod = 'indent'
  end,
})

-- ============================================================================
-- FILE TYPE ALIASES
-- ============================================================================

local alias_group = augroup('FileTypeAliases', { clear = true })

autocmd({ 'BufRead', 'BufNewFile' }, {
  group = alias_group,
  pattern = { '*.md', '*.md.erb' },
  callback = function()
    vim.bo.filetype = 'markdown'
  end,
})

autocmd({ 'BufRead', 'BufNewFile' }, {
  group = alias_group,
  pattern = '*.scala.html',
  callback = function()
    vim.bo.filetype = 'scala'
  end,
})

autocmd({ 'BufRead', 'BufNewFile' }, {
  group = alias_group,
  pattern = '*.ts',
  callback = function()
    vim.bo.filetype = 'typescript'
  end,
})

autocmd({ 'BufRead', 'BufNewFile' }, {
  group = alias_group,
  pattern = { 'Vagrantfile', 'Guardfile' },
  callback = function()
    vim.bo.filetype = 'ruby'
  end,
})

autocmd({ 'BufRead', 'BufNewFile' }, {
  group = alias_group,
  pattern = '*.envrc',
  callback = function()
    vim.bo.filetype = 'sh'
  end,
})

autocmd('FileType', {
  group = alias_group,
  pattern = 'sql',
  callback = function()
    vim.bo.filetype = 'mysql'
  end,
})

autocmd('FileType', {
  group = alias_group,
  pattern = 'scss.css',
  callback = function()
    vim.bo.filetype = 'scss'
  end,
})

-- ============================================================================
-- BUFFER EVENTS
-- ============================================================================

local buffer_group = augroup('BufferEvents', { clear = true })

-- Auto-change directory to current file
autocmd('BufEnter', {
  group = buffer_group,
  callback = function()
    require('utils.lcd').changeDir()
  end,
})

-- Trim whitespace and convert commas on save
autocmd('BufWritePre', {
  group = buffer_group,
  callback = function()
    require('utils.trim').RTrim()
    require('utils.trim').LTrimTabAndSpace()
  end,
})

autocmd('BufWritePre', {
  group = buffer_group,
  pattern = '*.md',
  callback = function()
    require('utils.comma').ToComma()
  end,
})

-- Prevent saving files with forbidden names
autocmd('BufWritePre', {
  group = buffer_group,
  pattern = { ':*', ';*' },
  callback = function()
    vim.api.nvim_err_writeln('Forbidden file name: ' .. vim.fn.expand('<afile>'))
  end,
})

-- ============================================================================
-- TEXT WIDTH SETTINGS
-- ============================================================================

local width_group = augroup('TextWidth', { clear = true })

autocmd('FileType', {
  group = width_group,
  pattern = { 'gitcommit', 'hgcommit' },
  callback = function()
    vim.opt_local.textwidth = 72
    vim.opt_local.colorcolumn = '+1'
  end,
})

autocmd('FileType', {
  group = width_group,
  pattern = 'rst',
  callback = function()
    vim.opt_local.textwidth = 80
    vim.opt_local.colorcolumn = '+1'
  end,
})

autocmd('FileType', {
  group = width_group,
  pattern = { 'javascript', 'coffee', 'php' },
  callback = function()
    vim.opt_local.textwidth = 80
  end,
})
