if exists('g:quickfixsync_loaded')
  finish
endif
let g:quickfixsync_loaded = 1

let g:_quickfixsync_autoload_path = expand('<sfile>:p:h:h').'/autoload'

let g:quickfixsync_auto_enable = get(g:, 'quickfixsync_auto_enable', 1)
let g:quickfixsync_qftype = get(g:, 'quickfixsync_qftype', '')
" from) vim-lsp
let g:quickfixsync_signs_enabled = get(g:, 'quickfixsync_signs_enabled', exists('*sign_define') && (has('nvim') || has('patch-8.1.0772')))
let g:quickfixsync_signname_map = get(g:, 'quickfixsync_signname_map', {})
" TODO: neovim
"let g:quickfixsync_highlights_enabled = get(g:, 'quickfixsync_highlights_enabled', exists('*nvim_buf_add_highlight'))
"let g:quickfixsync_textprop_enabled = get(g:, 'lsp_textprop_enabled', exists('*prop_add') && !g:quickfixsync_highlights_enabled)
"
let g:quickfixsync_textprop_enabled = get(g:, 'lsp_textprop_enabled', exists('*prop_add'))

if g:quickfixsync_auto_enable
  augroup quickfixsync_auto_enable
    autocmd!
    autocmd VimEnter * call quickfixsync#enable()
  augroup END
endif
