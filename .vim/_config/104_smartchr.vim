augroup smartchr
  autocmd!
  autocmd Filetype php,ruby,eruby,slim,javascript,typescript,coffee,python,perl,c inoremap <expr> = smartchr#one_of(' = ',' == ',' === ','=')
  autocmd Filetype php,ruby,eruby,slim,javascript,typescript,coffee,python,perl inoremap <expr> ~ smartchr#one_of('~',' =~ ')
  autocmd FileType php inoremap <expr> * smartchr#one_of('* ','/**', '*/', '*')
  autocmd Filetype markdown inoremap <expr> _ smartchr#one_of('_','__','\_')
  autocmd Filetype markdown inoremap <expr> # smartchr#one_of('# ','## ', '### ', '#### ', '##### ', '###### ', '\#')
  autocmd Filetype haml inoremap <expr> ` smartchr#one_of('%','`')

  autocmd Filetype javascript inoremap <expr> > smartchr#one_of('>',' => ')

  autocmd Filetype go inoremap <expr> = smartchr#one_of(' = ',' == ', '=')
  autocmd Filetype go inoremap <expr> : smartchr#one_of(':',' := ')
  autocmd Filetype go inoremap <expr> ! smartchr#one_of('!',' != ')
augroup END

