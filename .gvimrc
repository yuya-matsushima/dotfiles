" font
set guifont=JetBrainsMonoNerdFontCompleteM-Regular:h18

" window
set columns=100
set lines=50

" mouse
set mouse=a
set nomousefocus
set mousehide

" hide toolbar
set guioptions-=T

" printing
set printheader=%F%=%N\ /\ %{line('$')/73+1}
set printoptions=wrap:y
set printoptions=number:y
set printoptions=portrait:y
set printoptions+=paper:A4
set printoptions=duplex:off

" load ~/.vimrc_local if exists
if filereadable($HOME . '/.gvimrc_local')
  source $HOME/.gvimrc_local
endif
