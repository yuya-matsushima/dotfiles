" Font settings
if has('gui_macvim')
  " MacVim specific font setting
  set guifont=JetBrainsMonoNerdFontCompleteM-Regular:h18
  " Enable font ligatures if available
  set macligatures
else
  " Generic GUI font setting
  set guifont=JetBrains\ Mono\ 18
endif

" Window settings
set columns=120         " Default window width
set lines=40           " Default window height

" MacVim specific settings
if has('gui_macvim')
  " Enable native full screen
  set fuoptions=maxhorz,maxvert
  " Use Command key for Meta
  set macmeta
  " Smooth scrolling
  set guioptions+=k
endif

" Mouse settings
set mouse=a            " Enable mouse in all modes
set nomousefocus       " Don't focus window on mouse over
set mousehide          " Hide mouse when typing

" GUI options
set guioptions-=T      " Hide toolbar
set guioptions-=r      " Hide right scrollbar
set guioptions-=L      " Hide left scrollbar
set guioptions+=e      " Use GUI tabs

" Transparency (MacVim only)
if has('gui_macvim')
  set transparency=5   " Slight transparency (0-100)
endif

" Printing settings
set printheader=%F%=%N\ /\ %{line('$')/73+1}
set printoptions=wrap:y
set printoptions=number:y
set printoptions=portrait:y
set printoptions+=paper:A4
set printoptions=duplex:off

" Load local GUI settings if exists
if filereadable($HOME . '/.gvimrc_local')
  source $HOME/.gvimrc_local
endif
