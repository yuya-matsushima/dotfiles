-- ============================================================================
-- Mason tool installer
-- conform.nvim / nvim-lint が使う formatter・linter の実体を Mason 経由で導入する。
-- (LSP サーバは mason-lspconfig の ensure_installed が担当)
-- 注: gofmt/goimports の gofmt・rustfmt は Go/Rust ツールチェーンに同梱。
-- ============================================================================

return {
  'WhoIsSethDaniel/mason-tool-installer.nvim',
  event = 'VeryLazy',
  dependencies = { 'williamboman/mason.nvim' },
  opts = {
    ensure_installed = {
      'stylua', -- Lua formatter
      'prettierd', -- JS/TS/JSON/CSS/HTML/YAML/Markdown formatter (daemon)
      'goimports', -- Go import 整理 + format
      'shellcheck', -- shell linter
      'markdownlint', -- markdown linter
    },
    run_on_start = true,
  },
}
