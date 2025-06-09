" GitHub Copilot settings
if empty(globpath(&rtp, 'autoload/copilot.vim'))
  finish
endif

" Enable Copilot for specific filetypes
let g:copilot_filetypes = {
      \ '*': v:true,
      \ 'gitcommit': v:true,
      \ 'markdown': v:true,
      \ }

" Key mappings for Copilot
imap <silent><script><expr> <C-J> copilot#Accept("\<CR>")
let g:copilot_no_tab_map = v:true