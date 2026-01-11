if exists("g:gui_vimr")
  " Add Homebrew and asdf to PATH for tools required by plugins
  let $PATH = '/opt/homebrew/bin:/usr/local/bin:' . expand('~/.asdf/shims') . ':' . $PATH

  " Font configuration
  " Note: If this doesn't work, configure via VimR → Preferences → Appearance
  VimRSetFontAndSize "UDEV Gothic 35NFLG Regular", 18
  VimRSetLinespacing 1.0
endif
