let s:enabled = 0

let s:type2signindex = {
  \ 'E': 1,
  \  1 : 1,
  \ 'W': 2,
  \  2 : 2,
  \ 'I': 3,
  \  3 : 3,
  \ 'H': 4,
  \  4 : 4,
  \ }
let s:default_signname_map = {
  \ 1: 'QFSyncError',
  \ 2: 'QFSyncWarning',
  \ 3: 'QFSyncInformation',
  \ 4: 'QFSyncHint',
  \ }
if !hlexists('QFSyncErrorText')
  highlight link QFSyncErrorText Error
endif
if !hlexists('QFSyncWarningText')
  highlight link QFSyncWarningText Todo
endif
if !hlexists('QFSyncInformationText')
  highlight link QFSyncInformationText Normal
endif
if !hlexists('QFSyncHintText')
  highlight link QFSyncHintText Normal
endif

let s:default_text_map = {
  \ 1: 'E',
  \ 2: 'W',
  \ 3: 'I',
  \ 4: 'H',
  \ }
let s:signindex2name = extend(s:default_signname_map, g:quickfixsync_signname_map)

" ---

function! quickfixsync#signs#enable() abort
  if s:enabled | return | endif

  call s:defineDefaultSigns()

  let s:enabled = 1
endfunction

function! quickfixsync#signs#disable() abort
  if !s:enabled | return | endif

  call s:undefineDefaultSigns()

  let s:enabled = 0
endfunction

function! quickfixsync#signs#update() abort
  " exist bufnr list
  let l:bufnrs = filter(range(1, bufnr('$')), 'buflisted(v:val)')

  let l:locs = []
  if get(g:, 'quickfixsync_qftype', '') =~ 'Location'
    let l:locs = getloclist(0)
  else
    let l:locs = getqflist()
  endif
  let l:signs = sign_getplaced('', {'group': '*'})

  let l:sign_bufnrs = map(copy(l:signs), 'v:val.bufnr')
  let l:loc_bufnrs = map(copy(l:locs), 'v:val.bufnr')
  let l:union_bufnrs = uniq(sort(extend(l:sign_bufnrs, l:loc_bufnrs)))

  let l:target_bufnrs = quickfixsync#utils#range#intersection(l:bufnrs, l:union_bufnrs)

  let l:bufnr2indexes = s:buildBufnr2IndexesByLoclist(l:locs)
  for l:bufnr in l:target_bufnrs
    call s:updateBufferSigns(
      \ l:bufnr, quickfixsync#utils#range#firstOr(l:signs, {t -> t.bufnr == l:bufnr}, {'signs':[]}).signs,
      \ l:locs, get(l:bufnr2indexes, l:bufnr, [])
      \ )
  endfor
endfunction

" ---

function! s:defineDefaultSigns() abort
  for l:i in range(1, 4)
    call sign_define(s:default_signname_map[l:i], {
      \ 'text': s:default_text_map[l:i],
      \ 'texthl': s:default_signname_map[l:i].'Text',
      \ 'linehl':s:default_signname_map[l:i].'Line'
      \ })
  endfor
endfunction

function! s:undefineDefaultSigns() abort
  for l:i in range(1, 4)
    call sign_undefine(s:default_signname_map[l:i])
  endfor
endfunction

function! s:buildBufnr2IndexesByLoclist(locs) abort
  " NOTE: for tuning, by locs list for same bufnr
  " key:bufnr, value: loclist index array
  let l:bufnr2indexes = {} 

  for l:i in range(0, len(a:locs)-1)
    let l:bufnr = a:locs[l:i].bufnr

    if !has_key(l:bufnr2indexes, l:bufnr)
      let l:bufnr2indexes[l:bufnr] = []
    endif
    call add(l:bufnr2indexes[l:bufnr], l:i)
  endfor

  return l:bufnr2indexes
endfunction

function! s:updateBufferSigns(bufnr, buf_signs, locs, buf_locIndexes) abort
  " remove unnecessary signs
  for l:x in a:buf_signs
    if !quickfixsync#utils#range#any(a:buf_locIndexes, {t -> a:locs[t].lnum == l:x.lnum})
      call sign_unplace(l:x.group, {'id': l:x.id})
    endif
  endfor

  " add required signs
  let l:buf_signs_n = len(a:buf_signs)
  for l:x in a:buf_locIndexes
    if l:buf_signs_n == 0 || !quickfixsync#utils#range#any(a:buf_signs, {t -> t.lnum == a:locs[l:x].lnum})
      let l:signname = s:signindex2name[s:type2signindex[a:locs[l:x].type]]
      call sign_place(0, '', l:signname, bufname(a:bufnr),
        \ {'lnum': a:locs[l:x].lnum, 'priority': 10})
    endif
  endfor
endfunction
