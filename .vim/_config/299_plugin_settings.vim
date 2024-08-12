" molder.vim
let g:molder_show_hidden=1

" closetag.vim
let g:closetag_filenames='*.html,.php,*.js,*.xml,*.erb'

" quickrun.vim
silent! nmap <unique>qq <Plug>(quickrun)

" editorconfig.vim
au FileType gitcommit,hgcommit let b:EditorConfig_disable = 1

" rust.vim
let g:rustfmt_autosave = 1
