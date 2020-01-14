if exists('g:quickfixsync_loaded')
  finish
endif
let g:quickfixsync_loaded = 1

let g:quickfixsync_qftype = get(g:, 'quickfixsync_qftype', '')
let g:quickfixsync_auto_enable = get(g:, 'quickfixsync_auto_enable', 1)
" from) vim-lsp
let g:quickfixsync_signs_enabled = get(g:, 'quickfixsync_signs_enabled', exists('*sign_define') && (has('nvim') || has('patch-8.1.0772')))
let g:quickfixsync_signname_map = get(g:, 'quickfixsync_signname_map', {})

if g:quickfixsync_auto_enable
  augroup quickfixsync_auto_enable
    autocmd!
    autocmd VimEnter * call quickfixsync#enable()
  augroup END
endif
