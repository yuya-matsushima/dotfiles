function! lcd#changeDir()
  if fnameescape(expand('%:p:h')) != "quickrun:"
    execute 'lcd ' fnameescape(expand('%:p:h'))
  endif
endfunction
