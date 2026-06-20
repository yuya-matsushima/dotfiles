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

    lint.linters.mermaid_lint = {
      cmd = 'mermaid-lint',
      stdin = false,
      append_fname = true,
      args = { '--format', 'json' },
      stream = 'stdout',
      ignore_exitcode = true,
      parser = function(output, bufnr)
        local diagnostics = {}
        local ok, decoded = pcall(vim.json.decode, output)
        if not ok or not decoded or not decoded.files then
          return diagnostics
        end
        local is_mermaid = vim.bo[bufnr].filetype == 'mermaid'
        for _, file in ipairs(decoded.files) do
          for _, diagram in ipairs(file.diagrams) do
            local base = diagram.line or 0
            if diagram.error then
              local abs_line = is_mermaid and (base + diagram.error.line - 2) or (base + diagram.error.line - 1)
              table.insert(diagnostics, {
                lnum = abs_line,
                col = (diagram.error.col or 1) - 1,
                severity = vim.diagnostic.severity.ERROR,
                source = 'mermaid-lint',
                message = diagram.error.message,
              })
            end
            for _, warn in ipairs(diagram.warnings or {}) do
              local abs_line = is_mermaid and (base + warn.line - 2) or (base + warn.line - 1)
              table.insert(diagnostics, {
                lnum = abs_line,
                col = 0,
                severity = vim.diagnostic.severity.WARN,
                source = 'mermaid-lint',
                message = warn.message,
              })
            end
          end
        end
        return diagnostics
      end,
    }

    lint.linters_by_ft = {
      sh = { 'shellcheck' },
      bash = { 'shellcheck' },
      -- zsh も shellcheck の対象に含める (zsh 専用構文は警告が出る場合あり)
      zsh = { 'shellcheck' },
      markdown = { 'markdownlint', 'mermaid_lint' },
      mermaid = { 'mermaid_lint' },
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
