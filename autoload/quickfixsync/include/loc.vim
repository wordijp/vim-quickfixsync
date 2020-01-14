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

function _QuickfixSyncInclude() abort
  return {
    \ 'buildBufnr2IndexesByLoclist': function('s:buildBufnr2IndexesByLoclist'),
    \ }
endfunction
