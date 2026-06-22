-- ============================================================================
-- Formatting (conform.nvim)
-- 言語別フォーマッタを宣言的に管理。旧 lsp.lua の手書き BufWritePre autocmd
-- (Python/Go/Rust) を置き換える。formatter 未指定の ft は lsp_format='fallback'
-- により LSP フォーマットに落ちる (solargraph 等)。
-- ============================================================================

return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>cf',
      function()
        require('conform').format({ async = true, lsp_format = 'fallback' })
      end,
      mode = { 'n', 'v' },
      desc = 'Format buffer/range',
    },
  },
  opts = {
    default_format_opts = {
      lsp_format = 'fallback',
    },
    format_on_save = function(bufnr)
      local dominated_by_project = {
        javascript = true,
        javascriptreact = true,
        typescript = true,
        typescriptreact = true,
        json = true,
        jsonc = true,
        css = true,
        html = true,
      }
      if dominated_by_project[vim.bo[bufnr].filetype] then
        return false
      end
      return { timeout_ms = 1000, lsp_format = 'fallback' }
    end,
    formatters_by_ft = {
      python = { 'ruff_format', 'ruff_organize_imports' },
      go = { 'goimports' },
      rust = { 'rustfmt' },
      lua = { 'stylua' },
      yaml = { 'prettierd', 'prettier', stop_after_first = true },
      markdown = { 'prettierd', 'prettier', stop_after_first = true },
    },
  },
}
