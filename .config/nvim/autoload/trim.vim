function! trim#RTrim()
  let s:cursor = getpos(".")
  if &filetype == "markdown"
    match Underlined /\s\{2}$/
    %s/\s\+\(\s\{2}\)$/\1/e
  else
    %s/\s\+$//e
  endif
  call setpos(".", s:cursor)
endfunction

function! trim#LTrimTabAndSpace()
  let s:cursor = getpos(".")
  %s/^(\t|\s)\+$//e
  call setpos(".", s:cursor)
endfunction
