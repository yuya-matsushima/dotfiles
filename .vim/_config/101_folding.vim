set foldenable
set foldmethod=indent
set fillchars=vert:\1

augroup folding
  autocmd!
  autocmd FileType gitcommit,hgcommit setlocal nofoldenable
  autocmd FileType quickrun setlocal nofoldenable
  autocmd FileType scss,css setlocal foldmethod=marker foldmarker={,}
  autocmd FileType html,xhtml setlocal foldmethod=indent
augroup END
