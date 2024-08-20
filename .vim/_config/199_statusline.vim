function! IsCopilotEnabled()
  if exists('g:copilot_enabled') && g:copilot_enabled == 1
    return '🤖'
  else
    return ''
  endif
endfunction

set wildmenu
set cmdheight=2
set showcmd
set statusline=\%t\%=\[%l/%L]\[%{&filetype}]\[%{&fileencoding}]\[%{g:keyboard_type}]%{IsCopilotEnabled()}
set laststatus=2
