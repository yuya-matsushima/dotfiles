augroup shortcut
  autocmd!
  autocmd FileType * imap <buffer> , ,
  autocmd FileType * imap <> <><Left>
  autocmd FileType * imap <buffer> // //
  autocmd FileType php imap <buffer> <? <?php
  autocmd FileType php imap <buffer> dec declare(strict_types=1);
  autocmd FileType ruby imap <buffer> # #
augroup END

" save as sudo
command! Sudow :w !sudo tee >/dev/null %

" for US Keyboard
if g:keyboard_type == 'US'
  noremap ; :
  noremap : ;
endif
