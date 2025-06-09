" molder.vim
let g:molder_show_hidden=1

" vim-closetag
let g:closetag_filenames = '*.html,*.xhtml,*.php,*.jsx,*.tsx,*.erb'
let g:closetag_xhtml_filenames = '*.xhtml,*.jsx,*.tsx'
let g:closetag_filetypes = 'html,xhtml,php,javascript,typescript,eruby'
let g:closetag_xhtml_filetypes = 'xhtml,jsx,tsx'
let g:closetag_shortcut = '>'
let g:closetag_close_shortcut = '<leader>>'

" quickrun.vim
silent! nmap <unique>qq <Plug>(quickrun)

" editorconfig.vim
au FileType gitcommit,hgcommit let b:EditorConfig_disable = 1

" rust.vim
let g:rustfmt_autosave = 1
