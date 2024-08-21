set fileencodings=utf-8,ucs-bom,euc-jp,iso-2022-jp,sjis,cp932,utf-16,utf-16le

"set verbosefile=~/vimlog

call plug#begin('~/.config/nvim/plugged')

" lsp
Plug 'neovim/nvim-lspconfig'

" sinippet
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'

" JavaScript/TypeScript
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'leafOfTree/vim-vue-plugin'
Plug 'MaxMEllon/vim-jsx-pretty'
Plug 'peitalin/vim-jsx-typescript'
Plug 'styled-components/vim-styled-components'
Plug 'jparise/vim-graphql'

" Ruby/Ruby on Rails
Plug 'tpope/vim-rails'
Plug 'tpope/vim-endwise'
Plug 'slim-template/vim-slim'
Plug 'tpope/vim-haml'

" Rust
Plug 'rust-lang/rust.vim'

" Go
Plug 'mattn/vim-goimports'

" Docker
Plug 'ekalinin/Dockerfile.vim'

" filer
Plug 'mattn/vim-molder'
Plug 'mattn/vim-molder-operations'

" colorschme
Plug 'morhetz/gruvbox'
Plug 'cocopon/iceberg.vim'

" others
Plug 'thinca/vim-quickrun'
Plug 'kana/vim-smartchr'
Plug 'vim-scripts/closetag.vim'
Plug 'hashivim/vim-terraform', { 'for': 'terraform' }
Plug 'editorconfig/editorconfig-vim'
Plug 'github/copilot.vim'

call plug#end()

filetype on

" base
au!
syntax on

let g:keyboard_type = 'US'
let g:has_external_us_keyboard = strlen(system('ioreg -n IOUSB -l | grep -E "(HHKB|Keychron Q11)"')) > 0

colorscheme e2esound

filetype indent on
filetype plugin on

" IME Off when search or insert mode
set iminsert=0
set imsearch=0

" display
set number
set signcolumn=yes
set listchars=eol:$,tab:>\ ,extends:<
set ambiwidth=double
set showmatch
set notitle
set completeopt=menuone,preview,noinsert,noselect
set shortmess+=c
set nf=
" no beep
set visualbell t_vb=
" wrap
set whichwrap=b,s,h,l,<,>,[,]
set formatoptions+=mM

set browsedir=buffer
if has('win32') || has('win64') || has('mac')
  set clipboard+=unnamed
endif

" file
set hidden
set autoread

" search
set incsearch
set smartcase
set wrapscan
set hlsearch
noremap <esc><esc> :nohlsearch<CR><esc>

" indent
set autoindent
set cindent
set smartindent
set backspace=2

" no backup or tmp files
set noundofile
set noswapfile
set nobackup

" window split
set splitbelow
set splitright

" vimdiff
set diffopt-=filler diffopt=iwhite,horizontal

" load ~/.vimrc_local if exists
if filereadable($HOME . '/.nvimrc_local')
  source $HOME/.nvimrc_local
endif

" 100_index.vim
set tabstop=2
set shiftwidth=2
set expandtab

augroup tabSetting
  autocmd!
  autocmd FileType html,css setlocal tabstop=2 shiftwidth=2
  autocmd FileType javascript setlocal tabstop=2 shiftwidth=2
  autocmd FileType markdown setlocal tabstop=2 shiftwidth=2
  autocmd FileType slim,haml setlocal tabstop=2 shiftwidth=2
  autocmd filetype php setlocal tabstop=4 shiftwidth=4
  autocmd filetype python setlocal tabstop=4 shiftwidth=4
  autocmd FileType go setlocal noexpandtab tabstop=2 shiftwidth=2
augroup END

" 101_folding.vim
set foldenable
set foldmethod=indent
set fillchars=vert:\1

augroup folding
  autocmd!
  autocmd FileType gitcommit,hgcommit setlocal nofoldenable
  autocmd FileType quickrun setlocal nofoldenable
  autocmd FileType scss,css setlocal foldmethod=marker foldmarker={,}
  autocmd FileType html,xhtml setlocal foldmethod=indent
augroup END

" 102_shortcut.vim
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
  if g:keyboard_type != 'US'
    let g:keyboard_type = 'US'
  endif
endif

" 103_file_alias.vim
augroup alias
  autocmd!
  autocmd BufRead,BufNewFile *.md,*.md.erb setlocal filetype=markdown
  autocmd BufRead,BufNewFile *.scala.html setlocal filetype=scala
  autocmd FileType js setlocal ft=javascript
  autocmd BufRead,BufNewFile *.ts set filetype=typescript
  autocmd FileType rb,watchr,vagrantfile,Guardfile setlocal ft=ruby
  autocmd FileType smarty,tpl,ciunit,ctp setlocal ft=php
  autocmd FileType sql setlocal ft=mysql
  autocmd FileTYpe scss.css setlocal ft=scss
  autocmd FileType .envrc setlocal ft=sh
augroup END

" 104_smartcher.vim
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

" 105_event.vim
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

" 106_textwidth.vim
augroup width
  autocmd!
  autocmd FileType gitcommit,hgcommit setlocal textwidth=72
  autocmd FileType rst setlocal textwidth=80
  autocmd FileType javascript,coffee setlocal textwidth=80
  autocmd FileType php setlocal textwidth=80
  if exists('&colorcolumn')
    autocmd FileType rst,gitcommit,hgcommit setlocal colorcolumn=+1
  endif
augroup END

" 109_statusline.vim
set wildmenu
set cmdheight=2
set showcmd
set statusline=\%t\%=\[%l/%L]\[%{&filetype}]\[%{&fileencoding}]\[%{g:keyboard_type}]
set laststatus=2

" skip: 200_lsp.vim

" 201_vsnip.vim
let g:vsnip_snippet_dir=$HOME . '/.config/nvim/vsnip'

" Jump forward or backward
imap <expr> <Tab>   vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)' : '<Tab>'
smap <expr> <Tab>   vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)' : '<Tab>'
imap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>'
smap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>'

" 299_plugin_settings.vim
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
