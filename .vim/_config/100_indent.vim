set tabstop=2
set shiftwidth=2
set expandtab

augroup tabSetting
  autocmd!
  autocmd FileType html,css setlocal tabstop=2 shiftwidth=2
  autocmd FileType javascript setlocal tabstop=2 shiftwidth=2
  autocmd FileType markdown setlocal tabstop=2 shiftwidth=2
  autocmd FileType slim,haml setlocal tabstop=2 shiftwidth=2
  autocmd FileType php setlocal tabstop=4 shiftwidth=4
  autocmd FileType go setlocal noexpandtab tabstop=2 shiftwidth=2
augroup END
