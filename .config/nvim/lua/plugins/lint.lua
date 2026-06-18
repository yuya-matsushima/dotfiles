-- ============================================================================
-- Linting (nvim-lint)
-- LSP がカバーしない linter を補完する。eslint/ruff は LSP 側で動くため対象外。
-- dotfiles リポジトリ向けに shell script (shellcheck) と markdown (markdownlint)。
-- ============================================================================

return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPost', 'BufWritePost', 'BufNewFile' },
  config = function()
    local lint = require('lint')

    lint.linters_by_ft = {
      sh = { 'shellcheck' },
      bash = { 'shellcheck' },
      -- zsh も shellcheck の対象に含める (zsh 専用構文は警告が出る場合あり)
      zsh = { 'shellcheck' },
      markdown = { 'markdownlint' },
    }

    local function available_linters()
      local ft = vim.bo.filetype
      local names = lint.linters_by_ft[ft] or {}
      return vim.tbl_filter(function(name)
        local cmd = lint.linters[name] and lint.linters[name].cmd
        return cmd and vim.fn.executable(cmd) == 1
      end, names)
    end

    local group = vim.api.nvim_create_augroup('NvimLint', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost', 'InsertLeave' }, {
      group = group,
      callback = function()
        lint.try_lint(available_linters())
      end,
    })
  end,
}
