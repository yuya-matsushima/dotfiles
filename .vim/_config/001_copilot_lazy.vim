" Lazy load Copilot on demand
command! CopilotEnable call plug#load('copilot.vim') | Copilot enable
command! CopilotDisable Copilot disable
command! CopilotPanel call plug#load('copilot.vim') | Copilot panel

" Auto-load Copilot for specific filetypes
augroup copilot_lazy_load
  autocmd!
  autocmd FileType javascript,typescript,python,ruby,go,rust,vim call plug#load('copilot.vim')
augroup END