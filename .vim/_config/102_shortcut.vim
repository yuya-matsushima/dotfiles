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

" replace the colon and semicolon when a US keyboard
" or external US keyboard is connected.
if g:keyboard_type == 'US' || g:has_external_us_keyboard
  noremap ; :
  noremap : ;
endif
