let s:enabled = 0
let s:timer = 0

" TODO: highlight text
" TODO: virtual text (for nvim)

" ---

function! quickfixsync#enable() abort
  if s:enabled | return | endif

  if g:quickfixsync_signs_enabled | call quickfixsync#signs#enable() | endif

  " enable `autocmd BufReadPost quickfix ...` at startup.
  " NOTE: As long as you try, it won't fire unless a buffer is created.
  "       see `ex_copen()` url) https://github.com/vim/vim/blob/master/src/quickfix.c#L4150
  "       call `qf_open_new_cwindow()` is only this.
  call s:enableInitialQuickfixBufReadPost()

  augroup quickfixsync_event
    autocmd!
    "autocmd BufWritePost * call s:bufWritePostHook()
    autocmd BufReadPost quickfix call s:quickfixBufReadPostHook()
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
  if g:quickfixsync_signs_enabled | call quickfixsync#signs#update() | endif
endfunction

" ---

"function! s:bufWritePostHook() abort
"  let l:buf = bufnr('%')

"  if !s:skip_file(l:buf)
"    call quickfixsync#update()
"  endif
"endfunction

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

"function! s:skip_file(buf) abort
"  " see) vim-syntastic/syntastic `s:_skip_file`
"  " NOTE: Minimal checks to unnecessary updates.
"  " (Only the target is updated anyway)
"  return (getbufvar(a:buf, '&buftype') !=# '')
"    \ || getwinvar(0, '&diff')
"    \ || getwinvar(0, '&previewwindow')
"endfunction
