augroup bufferEvent
  autocmd!
  " CD.vim
  autocmd BufEnter * call lcd#changeDir()

  autocmd BufWritePre * call trim#RTrim()
  autocmd BufWritePre * call trim#LTrimTabAndSpace()
  autocmd BufWritePre *.md call comma#ToComma()
  autocmd BufWritePre [:;]* try | echoerr 'Forbidden file name: ' . expand('<afile>') | endtry
  " autocmd BufWritePre *.php,*.js,*.jsx,*.tsx,*.ts,*.rb,*.c setlocal fenc=utf-8
augroup END
