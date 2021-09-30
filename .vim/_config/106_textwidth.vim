augroup width
  autocmd!
  autocmd FileType gitcommit,hgcommit setlocal textwidth=72
  autocmd FileType rst setlocal textwidth=80
  autocmd FileType javascript,coffee setlocal textwidth=80
  autocmd FileType php setlocal textwidth=80
  if exists('&colorcolumn')
    autocmd FileType rst,gitcommit,hgcommit setlocal colorcolumn=+1
  endif
augroup END
