let s:supports_signs = exists('*sign_define') && (has('nvim') || has('patch-8.1.0772'))
let s:enabled = 0

" TODO: highlight text
" TODO: virtual text (for nvim)

" ---

function! quickfixsync#enable() abort
  if s:enabled | return | endif

  if g:quickfixsync_signs_enabled | call quickfixsync#signs#enable() | endif
  augroup quickfixsync_event
    autocmd! BufWritePost * call s:bufWritePostHook()
  augroup END

  let s:enabled = 1
endfunction

function! quickfixsync#disable() abort
  if !s:enabled | return | endif

  call quickfixsync#signs#disable()
  augroup quickfixsync_event
    autocmd!
  augroup END

  let s:enabled = 0
endfunction

function! quickfixsync#update() abort
  if s:supports_signs | call quickfixsync#signs#update() | endif
endfunction

" ---

function! s:bufWritePostHook() abort
  let l:buf = bufnr('%')

  if !s:skip_file(l:buf)
    call quickfixsync#update()
  endif
endfunction

function! s:skip_file(buf) abort
  " see) vim-syntastic/syntastic `s:_skip_file`
  " NOTE: Minimal checks to unnecessary updates.
  " (Only the target is updated anyway)
  return (getbufvar(a:buf, '&buftype') !=# '')
    \ || getwinvar(0, '&diff')
    \ || getwinvar(0, '&previewwindow')
endfunction
