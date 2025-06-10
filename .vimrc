" ============================================================================
" Vim Configuration File
" ============================================================================

" File encoding settings
set fileencodings=utf-8,ucs-bom,sjis,cp932,utf-16,utf-16le

"set verbosefile=~/vimlog

" ============================================================================
" PLUGIN MANAGEMENT
" ============================================================================

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
Plug 'pangloss/vim-javascript', { 'for': ['javascript', 'javascriptreact'] }
Plug 'leafgarland/typescript-vim', { 'for': ['typescript', 'typescriptreact'] }
Plug 'leafOfTree/vim-vue-plugin', { 'for': 'vue' }
Plug 'MaxMEllon/vim-jsx-pretty', { 'for': ['javascript', 'javascriptreact', 'typescript', 'typescriptreact'] }
Plug 'peitalin/vim-jsx-typescript', { 'for': ['typescript', 'typescriptreact'] }
Plug 'styled-components/vim-styled-components', { 'for': ['javascript', 'javascriptreact', 'typescript', 'typescriptreact'] }
Plug 'jparise/vim-graphql', { 'for': ['graphql', 'javascript', 'typescript'] }

" Ruby/Ruby on Rails
Plug 'tpope/vim-rails', { 'for': 'ruby' }
Plug 'tpope/vim-endwise', { 'for': ['ruby', 'vim'] }
Plug 'slim-template/vim-slim', { 'for': 'slim' }
Plug 'tpope/vim-haml', { 'for': 'haml' }

" Rust
Plug 'rust-lang/rust.vim', { 'for': 'rust' }

" Go
Plug 'mattn/vim-goimports', { 'for': 'go' }

" Docker
Plug 'ekalinin/Dockerfile.vim', { 'for': 'dockerfile' }

" filer
Plug 'mattn/vim-molder'
Plug 'mattn/vim-molder-operations'

" colorschme
Plug 'morhetz/gruvbox'
Plug 'cocopon/iceberg.vim'

" others
Plug 'thinca/vim-quickrun'
Plug 'kana/vim-smartchr'
Plug 'alvan/vim-closetag'
Plug 'hashivim/vim-terraform', { 'for': 'terraform' }
Plug 'editorconfig/editorconfig-vim'
Plug 'github/copilot.vim'

" fzf
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Git integration
Plug 'airblade/vim-gitgutter'

" Markdown
Plug 'preservim/vim-markdown', { 'for': 'markdown' }

call plug#end()

" ============================================================================
" BASIC SETTINGS
" ============================================================================

filetype on
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

" ============================================================================
" COPILOT LAZY LOADING
" ============================================================================

" Lazy load Copilot on demand
command! CopilotEnable call plug#load('copilot.vim')
command! CopilotDisable Copilot disable

" Auto-load Copilot for specific filetypes
augroup copilot_lazy_load
  autocmd!
  autocmd FileType javascript,typescript,python,ruby,go,rust,vim call plug#load('copilot.vim')
augroup END

" ============================================================================
" INDENTATION SETTINGS
" ============================================================================

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

" ============================================================================
" FOLDING SETTINGS
" ============================================================================

" Folding settings
if has('folding')
  set foldenable
  set foldmethod=indent
  set fillchars=vert:\|

  augroup folding
    autocmd!
    autocmd FileType gitcommit,hgcommit setlocal nofoldenable
    autocmd FileType quickrun setlocal nofoldenable
    autocmd FileType scss,css setlocal foldmethod=marker foldmarker={,}
    autocmd FileType html,xhtml setlocal foldmethod=indent
  augroup END
endif

" ============================================================================
" KEYBOARD SHORTCUTS
" ============================================================================

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

" ============================================================================
" FILE TYPE ALIASES
" ============================================================================

augroup alias
  autocmd!
  autocmd BufRead,BufNewFile *.md,*.md.erb setlocal filetype=markdown
  autocmd BufRead,BufNewFile *.scala.html setlocal filetype=scala
  autocmd BufRead,BufNewFile *.ts setlocal filetype=typescript
  autocmd BufRead,BufNewFile Vagrantfile,Guardfile setlocal filetype=ruby
  autocmd BufRead,BufNewFile *.envrc setlocal filetype=sh
  autocmd FileType sql setlocal ft=mysql
  autocmd FileType scss.css setlocal ft=scss
augroup END

" ============================================================================
" SMART CHARACTER INPUT
" ============================================================================

" Smart character input settings
if !empty(globpath(&rtp, 'autoload/smartchr.vim'))
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
endif

" ============================================================================
" BUFFER EVENTS
" ============================================================================

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

" ============================================================================
" TEXT WIDTH SETTINGS
" ============================================================================

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

" ============================================================================
" STATUS LINE
" ============================================================================

" Command line settings
set wildmenu        " Enhanced command line completion
set cmdheight=2     " Command line height
set showcmd         " Show incomplete commands

" Status line configuration
set laststatus=2    " Always show status line

" Helper function for Copilot status
function! IsCopilotEnabled()
  if exists('g:copilot_enabled') && g:copilot_enabled == 1
    return '[AI]'
  else
    return ''
  endif
endfunction

" Custom status line
" Format: filename[modified] ... [line/total][filetype][encoding][US/JIS][AI]
set statusline=
set statusline+=%f                                  " File path
set statusline+=%m                                  " Modified flag [+]
set statusline+=%=                                  " Switch to right side
set statusline+=[%l/%L]                             " Current line / Total lines
set statusline+=[%{&filetype}]                      " File type
set statusline+=[%{&fileencoding?&fileencoding:&encoding}]    " File encoding
set statusline+=[%{g:keyboard_type}]                " Keyboard type (US/JIS)
set statusline+=%#CopilotStatus#%{IsCopilotEnabled()}%#StatusLine#  " Copilot status

" ============================================================================
" LSP SETTINGS
" ============================================================================

if !empty(globpath(&rtp, 'autoload/lsp.vim'))
  function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    setlocal signcolumn=yes
    nmap <buffer> gd <plug>(lsp-peek-definition)
    nmap <buffer> gr <plug>(lsp-references)
    nmap <buffer> gi <plug>(lsp-implementation)
    nmap <buffer> gt <plug>(lsp-type-definition)
    nmap <buffer> gp <plug>(lsp-previous-diagnostic)
    nmap <buffer> gn <plug>(lsp-next-diagnostic)
    nmap <buffer> K <plug>(lsp-hover)
    nmap <buffer> <f2> <plug>(lsp-rename)
    inoremap <expr> <cr> pumvisible() ? "\<c-y>\<cr>" : "\<cr>"
  endfunction

  augroup lsp_install
    au!
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
  augroup END
  command! LspDebug let lsp_log_verbose=1 | let lsp_log_file = expand('~/.lsp.log')

  let g:lsp_diagnostics_enabled = 1
  let g:lsp_diagnostics_echo_cursor = 1
  let g:lsp_diagnostics_signs_enabled = 1
  let g:lsp_diagnostics_highlights_enabled = 1
  let g:lsp_diagnostics_virtual_text_enabled = 0
  let g:lsp_document_highlight_enabled = 1

  " asyncomplete settings
  let g:asyncomplete_auto_popup = 1
  let g:asyncomplete_auto_completeopt = 0
  let g:asyncomplete_popup_delay = 200
  let g:asyncomplete_min_chars = 2

  " lsp-settings
  let g:lsp_settings_filetype_typescript = ['typescript-language-server', 'eslint-language-server']
  let g:lsp_settings_filetype_javascript = ['typescript-language-server', 'eslint-language-server']
endif

" ============================================================================
" SNIPPET SETTINGS
" ============================================================================

if !empty(globpath(&rtp, 'autoload/vsnip.vim'))
  let g:vsnip_snippet_dir=$HOME . '/.vim/vsnip'

  " Jump forward or backward
  imap <expr> <Tab>   vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)' : '<Tab>'
  smap <expr> <Tab>   vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)' : '<Tab>'
  imap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>'
  smap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>'
endif

" ============================================================================
" COPILOT SETTINGS
" ============================================================================

" GitHub Copilot settings
if !empty(globpath(&rtp, 'autoload/copilot.vim'))
  " Enable Copilot for specific filetypes
  let g:copilot_filetypes = {
        \ '*': v:true,
        \ 'gitcommit': v:true,
        \ 'markdown': v:true,
        \ }

  " Key mappings for Copilot
  imap <silent><script><expr> <C-L> copilot#Accept("\<CR>")
  let g:copilot_no_tab_map = v:true
endif

" ============================================================================
" PLUGIN SETTINGS
" ============================================================================

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

" vim-markdown
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_new_list_item_indent = 2

" vim-gitgutter
let g:gitgutter_diff_base = 'HEAD'

" ============================================================================
" COLOR SCHEME SETTINGS
" ============================================================================

let g:colorscheme_settings = [
\ {'name': 'e2esound', 'mode': 'dark'},
\ {'name': 'e2esound', 'mode': 'light'},
\ {'name': 'gruvbox', 'mode': 'dark'},
\ {'name': 'gruvbox', 'mode': 'light'},
\ {'name': 'iceberg', 'mode': 'dark'},
\ {'name': 'iceberg', 'mode': 'light'},
\ ]
let g:colorscheme_index = 0

function! SwitchColorScheme()
    let g:colorscheme_index += 1
    if g:colorscheme_index >= len(g:colorscheme_settings)
        let g:colorscheme_index = 0
    endif
    let scheme = g:colorscheme_settings[g:colorscheme_index]
    execute 'colorscheme ' . scheme.name
    execute 'set background=' . scheme.mode
endfunction

" ============================================================================
" LOCAL CONFIGURATION
" ============================================================================

" load ~/.vimrc_local if exists
if filereadable($HOME . '/.vimrc_local')
  source $HOME/.vimrc_local
endif
