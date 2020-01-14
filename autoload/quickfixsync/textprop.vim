let s:enabled = 0

let s:define = quickfixsync#include#_('define.vim')
let s:loc = quickfixsync#include#_('loc.vim')

let s:prop_type_prefix = 'vim_qfsync_hl_'

if !hlexists('QFSyncErrorHighlight')
  highlight link QFSyncErrorHighlight Error
endif
if !hlexists('QFSyncWarningHighlight')
  highlight link QFSyncWarningHighlight Todo
endif
if !hlexists('QFSyncInformationHighlight')
  highlight link QFSyncInformationHighlight Normal
endif
if !hlexists('QFSyncHintHighlight')
  highlight link QFSyncHintHighlight Normal
endif

" ---

function! quickfixsync#textprop#enable() abort
  if s:enabled | return | endif

  call s:defineDefaultProps()

  let s:enabled = 1
endfunction

function! quickfixsync#textprop#disable() abort
  if !s:enabled | return | endif

  call s:undefineDefaultProps()

  let s:enabled = 0
endfunction

function! quickfixsync#textprop#update() abort
  " exist bufnr list
  let l:bufnrs = filter(range(1, bufnr('$')), 'buflisted(v:val)')
  call s:updateInternal(l:bufnrs)
endfunction

function! quickfixsync#textprop#updateBuf(bufnr) abort
  let l:bufnrs = [a:bufnr]
  call s:updateInternal([a:bufnr])
endfunction

" ---

function! s:updateInternal(bufnrs) abort
  if !s:enabled
    call quickfixsync#textprop#enable()
  endif

  let l:locs = []
  if get(g:, 'quickfixsync_qftype', '') =~ 'Location'
    let l:locs = getloclist(0)
  else
    let l:locs = getqflist()
  endif

  let l:props = quickfixsync#utils#textprop#prop_getadded()

  let l:prop_bufnrs = map(copy(l:props), 'v:val.bufnr')
  let l:loc_bufnrs = map(copy(l:locs), 'v:val.bufnr')
  let l:union_bufnrs = uniq(sort(extend(l:prop_bufnrs, l:loc_bufnrs), {a, b -> a == b ? 0 : a > b ? 1 : -1}))

  let l:target_bufnrs = quickfixsync#utils#range#intersection(a:bufnrs, l:union_bufnrs)

  let l:bufnr2indexes = s:loc.buildBufnr2IndexesByLoclist(l:locs)
  for l:bufnr in l:target_bufnrs
    call s:updateBufferProps(
      \ l:bufnr, quickfixsync#utils#range#firstOr(l:props, {t -> t.bufnr == l:bufnr}, {'props':[]}).props,
      \ l:locs, get(l:bufnr2indexes, l:bufnr, [])
      \ )
  endfor
endfunction

function! s:defineDefaultProps() abort
  for l:i in range(1, 4)
    call prop_type_add(s:type2propname(l:i), {
      \ 'highlight': s:define.default_signname_map[l:i] . 'Highlight',
      \ 'combine': v:true,
      \ })
  endfor
endfunction

function! s:undefineDefaultProps() abort
  for l:i in range(1, 4)
    call prop_type_delete(s:type2propname(l:i))
  endfor
endfunction

function! s:type2propname(type) abort
  return s:prop_type_prefix . s:define.type2signindex[a:type]
endfunction

function! s:updateBufferProps(bufnr, buf_props, locs, buf_locIndexes) abort
  " remove unnecessary props
  for l:x in a:buf_props
    let l:lnum_buf_locIndexes = filter(copy(a:buf_locIndexes), {_, v -> a:locs[v].lnum == l:x.lnum})
    if quickfixsync#utils#range#any(l:x.list, {t -> !quickfixsync#utils#range#any(l:lnum_buf_locIndexes, {u -> t.col == a:locs[u].col})})
    " TODO: Fix after support `col` field by `prop_remove()`
    "if !quickfixsync#utils#range#any(a:buf_locIndexes, {t -> a:locs[t].lnum == l:x.lnum && a:locs[t].col == l:x.col})}) " <- I want to do

      " remove all the line
      " (I want `col` field)
      for l:y in l:x.list
        call prop_remove({
          \ 'bufnr': a:bufnr,
          \ 'type': l:y.type,
          \ 'all': v:true,
          \ }, l:x.lnum)
      endfor

      " repair out of target
      for l:y in l:x.list
        if quickfixsync#utils#range#any(a:buf_locIndexes, {t -> a:locs[t].lnum == l:x.lnum && a:locs[t].col == l:y.col})
          call prop_add(l:x.lnum, l:y.col, {
            \ 'end_lnum': l:x.lnum,
            \ 'end_col': l:y.col + l:y.length,
            \ 'bufnr': a:bufnr,
            \ 'type': l:y.type,
            \ })
        endif
      endfor
    endif
  endfor

  " add required props
  let l:buf_props_n = len(a:buf_props)
  for l:x in a:buf_locIndexes
    if l:buf_props_n == 0 || !quickfixsync#utils#range#any(a:buf_props, {t -> t.lnum == a:locs[l:x].lnum && quickfixsync#utils#range#any(t.list, {u -> a:locs[l:x].col == u.col})})
      let l:propname = s:type2propname(a:locs[l:x].type)
      " NOTE: `end_col` is +1, because quickfix list has no `length`.

      let l:line = getbufline(a:bufnr, a:locs[l:x].lnum)
      let l:line_length = len(l:line) > 0 ? len(l:line[0]) : 0
      if l:line_length == 0 | continue | endif

      let l:col = s:min(l:line_length, a:locs[l:x].col)
      call prop_add(a:locs[l:x].lnum, l:col, {
        \ 'end_lnum': a:locs[l:x].lnum,
        \ 'end_col': l:col + 1,
        \ 'bufnr': a:bufnr,
        \ 'type': l:propname,
        \ })
    endif
  endfor
endfunction

function! s:min(a, b) abort
  return a:a < a:b ? a:a : a:b
endfunction
