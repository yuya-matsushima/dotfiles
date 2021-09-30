" closetag.vim
let g:closetag_filenames='*.html,.php,*.js,*.xml,*.erb'

" quickrun.vim
silent! nmap <unique>qq <Plug>(quickrun)

" editorconfig.vim
au FileType gitcommit,hgcommit let b:EditorConfig_disable = 1
