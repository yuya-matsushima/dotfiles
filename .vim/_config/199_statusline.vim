" Command line settings
set wildmenu        " Enhanced command line completion
set cmdheight=2     " Command line height
set showcmd         " Show incomplete commands

" Status line configuration
set laststatus=2    " Always show status line

" Helper function for Copilot status
function! IsCopilotEnabled()
  if exists('g:copilot_enabled') && g:copilot_enabled == 1
    return ' [AI]'
  else
    return ''
  endif
endfunction

" Custom status line
" Format: filename [modified] ... [line/total] [filetype] [encoding] [keyboard] [copilot]
set statusline=
set statusline+=%f                                  " File path
set statusline+=%m                                  " Modified flag [+]
set statusline+=%=                                  " Switch to right side
set statusline+=[%l/%L]                             " Current line / Total lines
set statusline+=\ [%{&filetype}]                    " File type
set statusline+=\ [%{&fileencoding?&fileencoding:&encoding}]  " File encoding
set statusline+=\ [%{g:keyboard_type}]              " Keyboard type (US/JIS)
set statusline+=%{IsCopilotEnabled()}               " Copilot status
