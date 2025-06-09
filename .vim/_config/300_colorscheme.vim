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

