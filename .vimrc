set fileencodings=utf-8,ucs-bom,euc-jp,iso-2022-jp,sjis,cp932,utf-16,utf-16le

"set verbosefile=~/vimlog

call plug#begin('~/.vim/plugged')

" vim-lsp
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'mattn/vim-lsp-icons'

" sinippet
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

" Go
Plug 'mattn/vim-goimports'

" Docker
Plug 'ekalinin/Dockerfile.vim'

" filer
Plug 'mattn/vim-molder'
Plug 'mattn/vim-molder-operations'

" colorschme
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
let g:has_external_us_keyboard = strlen(system('ioreg -n IOUSB -l | grep HHKB')) > 0
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
if filereadable($HOME . '/.vimrc_local')
  source $HOME/.vimrc_local
endif

call map(sort(split(globpath(&runtimepath, '_config/*.vim'))), {->[execute('exec "so" v:val')]})
