# Neovim Configuration Migration Plan

## Status: ✅ COMPLETE

**Migration Date**: 2025-12-20
**Completion Date**: 2025-12-20
**Branch**: feature/add-nvim-config
**PR**: #49

All features successfully migrated and tested. No known issues.

## Overview

This document describes the migration of the Vim configuration (.vimrc + .vim/) to Neovim using modern Lua-based configuration with native LSP, lazy.nvim plugin manager, and full feature parity.

## Configuration Structure

All files are located in `~/Project/Personal/dotfiles/.config/nvim/` and symlinked to `~/.config/nvim`.

```
.config/nvim/
├── init.lua                    # Entry point
├── lua/
│   ├── config/
│   │   ├── lazy.lua           # Plugin manager bootstrap
│   │   ├── options.lua        # Vim options
│   │   ├── keymaps.lua        # Keyboard shortcuts
│   │   └── autocmds.lua       # Autocommands
│   ├── plugins/               # Plugin configurations
│   │   ├── lsp.lua           # Mason + LSP
│   │   ├── completion.lua    # nvim-cmp + Smart Tab
│   │   ├── copilot.lua       # GitHub Copilot
│   │   ├── snippets.lua      # LuaSnip
│   │   ├── treesitter.lua    # Syntax highlighting
│   │   ├── telescope.lua     # Fuzzy finder
│   │   ├── neo-tree.lua      # File explorer
│   │   ├── git.lua           # Git integration
│   │   ├── ui.lua            # Status line, colors
│   │   ├── editor.lua        # Editor enhancements
│   │   └── language.lua      # Language-specific plugins
│   └── utils/
│       ├── lcd.lua           # Auto-change directory
│       ├── trim.lua          # Whitespace trimming
│       └── comma.lua         # Comma conversion
├── colors/
│   └── e2esound.vim          # Custom color scheme
└── snippets/
    ├── package.json
    ├── typescript.json
    └── ruby.json
```

## Plugin Migration

### Core Changes

| Vim Plugin | Neovim Alternative | Reason |
|------------|-------------------|---------|
| vim-plug | lazy.nvim | Modern plugin manager with automatic lazy loading |
| vim-lsp + vim-lsp-settings | nvim-lspconfig + mason.nvim | Native LSP is faster and better integrated |
| asyncomplete | nvim-cmp | More powerful completion engine |
| vim-vsnip | LuaSnip | Lua-native snippet engine with VSCode format support |
| fzf.vim | telescope.nvim | Native Neovim integration, better previews |
| vim-molder | neo-tree.nvim | More features, git integration |
| vim-gitgutter | gitsigns.nvim | Lua-native, faster |
| vim-javascript/typescript-vim | nvim-treesitter | Better syntax highlighting |
| vim-closetag | nvim-ts-autotag | Treesitter-based auto-close |
| vim-css-color | nvim-colorizer.lua | Lua-native color preview |
| copilot.vim | copilot.lua + copilot-cmp | Better nvim-cmp integration |

### Plugins Kept As-Is

These plugins work well in Neovim and have no better alternatives:

- vim-rails, vim-endwise (Ruby/Rails)
- rust.vim (Rust formatting)
- vim-goimports (Go imports)
- vim-astro (Astro framework)
- vim-slim, vim-haml (Template engines)
- vim-terraform (Terraform)
- Dockerfile.vim (Docker)
- vim-markdown (Markdown)
- vim-graphql (GraphQL)
- vim-styled-components (Styled components)
- vim-jsx-pretty, vim-jsx-typescript (JSX/TSX)
- editorconfig-vim (EditorConfig support)

## Features Preserved

### 1. Custom Functions

All custom autoload functions were migrated to Lua:

- **lcd.lua**: Auto-change directory to current file's location
- **trim.lua**: RTrim (preserves markdown 2-space line breaks), LTrimTabAndSpace
- **comma.lua**: Convert Japanese comma (、) to Western comma (, )

### 2. LSP Configuration

All LSP servers configured with same keybindings:

- **gd**: Go to definition
- **gr**: Find references
- **gi**: Go to implementation
- **gt**: Go to type definition
- **K**: Hover documentation
- **F2**: Rename
- **gp**: Previous diagnostic
- **gn**: Next diagnostic

Diagnostic settings match .vimrc:
- Signs enabled
- Virtual text disabled
- Echo diagnostics on CursorHold

### 3. Smart Tab Function

Tab key priority (matching .vimrc behavior):
1. Accept Copilot suggestion (if visible)
2. Navigate completion menu (if visible)
3. Expand/jump snippet (if available)
4. Trigger completion (if words before cursor)
5. Default Tab behavior

### 4. Copilot Integration

- Lazy loading by filetype (js, ts, py, rb, go, rust, vim)
- Environment variable check (DISABLE_COPILOT=1)
- Status line indicator [AI]
- C-L as alternative accept key

### 5. Keyboard Shortcuts

- ESC ESC: Clear search highlight
- ;/: swap for US keyboard (auto-detected)
- Sudow command for sudo save

### 6. File Type Settings

- Indentation rules (2 spaces for web, 4 for py/php, tabs for go)
- Folding settings per filetype
- File type aliases (.md → markdown, Vagrantfile → ruby)
- Text width settings (gitcommit: 72, others: 80)

### 7. Auto-Commands

- BufEnter: Auto-change directory
- BufWritePre: Trim whitespace (preserving markdown line breaks)
- BufWritePre *.md: Convert Japanese commas

### 8. Color Scheme

e2esound theme migrated with changes:
- Removed `set transparency=12` (handle at terminal level)
- Removed terminal color codes (Neovim handles automatically)
- All color definitions preserved
- GitGutter/Copilot highlights preserved

### 9. Snippets

- TypeScript: 7 snippets (class, interface, type, function, etc.)
- Ruby: 14 snippets (RSpec: describe, context, it, let, before, etc.)
- Format: VSCode-compatible JSON (works with LuaSnip)

### 10. Status Line

lualine.nvim configuration with:
- Mode indicator
- Branch, diff, diagnostics
- Filename (relative path)
- Copilot status [AI]
- Keyboard type [US/JIS]
- Encoding, format, filetype
- Location, progress

## Features Not Migrated

### vim-smartchr

Not migrated due to complexity. The plugin provides smart character input (e.g., typing = cycles through =, ==, ===).

**Reason**: Low priority feature, complex implementation.

**Alternative**: LSP auto-pairs provides similar functionality for basic cases.

**Future**: Can implement custom Lua functions if needed.

### vim-quickrun

Kept as-is. Works perfectly in Neovim.

**Alternative considered**: toggleterm.nvim, but vim-quickrun works fine.

## Optimizations for Neovim

### Removed Settings

These settings are unnecessary in Neovim:

1. **Terminal color codes** (`&t_8f`, `&t_8b`): Neovim handles true color automatically
2. **Transparency setting**: Should be handled at terminal level (Alacritty config)
3. **asyncomplete delay**: nvim-cmp is instant, no delay needed

### Performance Improvements

Expected improvements over Vim:

1. **Startup time**: lazy.nvim automatic lazy loading → 2-3x faster
2. **LSP response**: Native LSP → more responsive than vim-lsp
3. **Syntax highlighting**: Treesitter → more accurate and faster
4. **Completion**: nvim-cmp → faster than asyncomplete

## Usage

### Installation

```bash
# Create symlink
make nvim_link

# Install plugins
make nvim_plugin

# Test configuration
make nvim_test
```

### Uninstallation

```bash
# Remove symlink
make nvim_unlink
```

### Testing Checklist

All tests completed successfully on 2025-12-20:

- [x] Open nvim, check no errors on startup
- [x] Verify color scheme loads (e2esound)
- [x] Test LSP in TypeScript file (gd, gr, K, F2, diagnostics)
- [x] Test completion with Tab key and Ctrl+n/Ctrl+p navigation
- [x] Test Copilot suggestions and Tab acceptance
- [x] Test ESC ESC to clear search highlight
- [x] Test Telescope fuzzy finder (:Telescope find_files)
- [x] Test Neo-tree file explorer (-)
- [x] Verify Mason LSP servers installed (ts_ls, eslint, pyright, solargraph, gopls, rust_analyzer)

## Issues Fixed During Testing

### 1. Treesitter Module Path Error
**Problem**: `module 'nvim-treesitter.configs' not found`
**Solution**: Changed from `nvim-treesitter.configs` to `nvim-treesitter.config` (API change in recent versions)
**Commit**: 6bb98d1

### 2. LSP Keybindings Not Working
**Problem**: F2 rename and other LSP keybindings not being set
**Solution**: Migrated from `on_attach` callback to `LspAttach` autocmd (correct approach for Neovim 0.11+ `vim.lsp.config` API)
**Commit**: c891a0e

### 3. Completion Menu Navigation
**Problem**: Ctrl+n/Ctrl+p not working to navigate completion items
**Solution**: Added explicit Ctrl+n and Ctrl+p mappings in nvim-cmp configuration
**Commit**: d93d2c7

### 4. Completion Window Width
**Problem**: Completion menu too wide
**Solution**: Added `window.completion.max_width = 60` configuration
**Commit**: 9e91672

### 5. Neo-tree Folder Expansion
**Problem**: Neo-tree opening with folders collapsed
**Solution**: Changed keybinding from `toggle` to `reveal` to auto-expand to current file location
**Commit**: 8c6cf81

### 6. Folding Behavior
**Problem**: Files opening with folds collapsed
**Solution**: Aligned with .vimrc behavior (folding enabled globally, disabled for specific filetypes including neo-tree)
**Commits**: 57f5209, 443ee72 (revert)

## Known Issues

None. All features successfully migrated and tested.

## Future Enhancements

### Optional Improvements

1. **Convert color scheme to Lua**: e2esound.vim could be rewritten using Neovim's highlight API
2. **Implement vim-smartchr in Lua**: Custom smart character input functions
3. **Add which-key.nvim**: Keyboard shortcut helper
4. **Add trouble.nvim**: Better diagnostic list UI
5. **Add indent-blankline**: Visual indent guides

### Monitoring

After using Neovim for a while, consider:

1. **Profiling startup time**: `:Lazy profile`
2. **Checking LSP performance**: `:LspInfo`
3. **Health check**: `:checkhealth`
4. **Reviewing plugin updates**: `:Lazy update`

## Rollback Plan

If issues arise:

1. Both Vim and Neovim configs are separate (no conflicts)
2. Switch back: use `vim` instead of `nvim`
3. Remove symlink: `make nvim_unlink`
4. Keep .vimrc and .vim/ directory intact

## References

- [Neovim Documentation](https://neovim.io/doc/)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
