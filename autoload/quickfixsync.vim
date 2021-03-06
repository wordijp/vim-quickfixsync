let s:enabled = 0
let s:timer = 0

" ---

function! quickfixsync#enable() abort
  if s:enabled | return | endif

  " comment out due to highlight link delay
  " NOTE: auto enable in update
  "if g:quickfixsync_signs_enabled | call quickfixsync#signs#enable() | endif
  "if g:quickfixsync_textprop_enabled | call quickfixsync#textprop#enable() | endif

  " enable `autocmd BufReadPost quickfix ...` at startup.
  " NOTE: As long as you try, it won't fire unless a buffer is created.
  "       see `ex_copen()` url) https://github.com/vim/vim/blob/master/src/quickfix.c#L4150
  "       call `qf_open_new_cwindow()` is only this.
  call s:enableInitialQuickfixBufReadPost()

  augroup quickfixsync_event
    autocmd!
    autocmd BufReadPost quickfix call s:quickfixBufReadPostHook()
    autocmd BufEnter * call s:bufEnterHook()
  augroup END

  let s:enabled = 1
endfunction

function! quickfixsync#disable() abort
  if !s:enabled | return | endif

  call quickfixsync#signs#disable()
  call quickfixsync#textprop#disable()

  augroup quickfixsync_event
    autocmd!
  augroup END

  let s:enabled = 0
endfunction

function! quickfixsync#update() abort
  if g:quickfixsync_signs_enabled | call quickfixsync#signs#update() | endif
  if g:quickfixsync_textprop_enabled | call quickfixsync#textprop#update() | endif
endfunction

function! quickfixsync#updateBuf(bufnr) abort
  if g:quickfixsync_signs_enabled | call quickfixsync#signs#updateBuf(a:bufnr) | endif
  if g:quickfixsync_textprop_enabled | call quickfixsync#textprop#updateBuf(a:bufnr) | endif
endfunction

" ---

function! s:quickfixBufReadPostHook() abort
  if s:timer > 0
    call timer_stop(s:timer)
    let s:timer = 0
  endif

  let l:bufnr = bufnr('%')
  let l:tickMonitor = {
    \ 'count': 0,
    \ 'retry': 40,
    \ 'bufnr': l:bufnr,
    \ 'changedtick': getbufinfo(l:bufnr)[0].changedtick,
    \ 'on_update': function('quickfixsync#update'),
    \ }
  function! l:tickMonitor.checkUpdate(timer) abort
    " wait for update
    let l:changedtick = getbufinfo(self.bufnr)[0].changedtick
    if self.changedtick == l:changedtick
      if self.count < self.retry
        let self.count += 1
        return
      endif
    endif

    call timer_stop(s:timer)
    let s:timer = 0

    if self.changedtick != l:changedtick
      call self.on_update()
    endif
  endfunction

  let s:timer = timer_start(50, l:tickMonitor.checkUpdate, {'repeat': -1})
endfunction

function! s:bufEnterHook() abort
  let l:bufnr = bufnr('')
  if !s:skip_file(l:bufnr)
    call quickfixsync#updateBuf(l:bufnr)
  endif
endfunction

function! s:enableInitialQuickfixBufReadPost() abort
  if get(g:, 'quickfixsync_qftype', '') =~ 'Location'
    call s:createLocationBuffer()
  else
    call s:createQFBuffer()
  endif
endfunction

function! s:createLocationBuffer() abort
  if getloclist(0, {'qfbufnr': 1}).qfbufnr != 0 | return | endif

  try
    :silent lopen
  catch
    call setloclist(0, [])
    :silent lopen
  finally
    :silent lclose
  endtry
endfunction

function! s:createQFBuffer() abort
  if getqflist({'qfbufnr': 1}).qfbufnr != 0 | return | endif

  try
    :silent copen
  catch
    call setqflist([])
    :silent copen
  finally
    :silent cclose
  endtry
endfunction

function! s:skip_file(buf) abort
  " see) vim-syntastic/syntastic `s:_skip_file`
  " NOTE: Minimal checks to unnecessary updates.
  " (Only the target is updated anyway)
  return (getbufvar(a:buf, '&buftype') !=# '')
    \ || getwinvar(0, '&diff')
    \ || getwinvar(0, '&previewwindow')
endfunction
