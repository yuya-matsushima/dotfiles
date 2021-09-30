"読点をカンマに変換
function! comma#ToComma()
  let s:cursor = getpos(".")
  %s/、/, /e
  call setpos(".", s:cursor)
endfunction
