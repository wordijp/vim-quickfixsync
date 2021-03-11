" @param bufnr
function! quickfixsync#utils#textprop#prop_getadded(...) abort
  let l:bufnr = get(a:, 1, 0)
  let l:bufnrs = (l:bufnr != 0) ? [l:bufnr] : filter(range(1, bufnr('$')), 'buflisted(v:val)')
  return filter(map(l:bufnrs, 's:getAddedInternal(v:val)'), '!empty(v:val.props)')
endfunction

" ---

function! s:getAddedInternal(bufnr) abort
  let l:props = []
  for l:x in prop_type_list()
    let l:added = s:getAddedInternalByProptype(a:bufnr, l:x)
    if !empty(l:added)
      call add(l:props, l:added)
    endif
  endfor

  " combine each props
  " result see) sample/prop_getadded_flatten_and_uniq.json
  let l:props = quickfixsync#utils#range#flattenAndUniq(l:props,
    \ {a, b -> a.lnum == b.lnum ? 0 : a.lnum > b.lnum ? 1 : -1})

  " normalize
  " TODO: Enable after `prop_remove` support `col` field.
  "let l:props = map(l:props, {_, v1 -> map(v1.list, {_, v2 -> extend({'lnum': v1.lnum}, v2)})})
  "let l:props = quickfixsync#utils#range#flatten(l:props)

  return {
    \ 'bufnr': a:bufnr,
    \ 'props': l:props,
    \ }
endfunction

function! s:getAddedInternalByProptype(bufnr, proptype) abort
  let l:added = []

  let l:lnum = 1
  " NOTE: There is bufnr that cannot get `winid`
  "let l:nline = line('$', win_getid(a:bufnr))
  "while l:lnum <= l:nline " <- NG
  while 1
    " NOTE: `prop_find` find only the first. :(
    let l:found = v:none
    try
      let l:found = prop_find({
        \ 'bufnr': a:bufnr,
        \ 'lnum': l:lnum,
        \ 'type': a:proptype,
        \ })
    catch
      " lnum is out of range
      break
    endtry
    if empty(l:found)
      break
    endif
    if l:found.lnum < l:lnum
      let l:lnum += 1
      continue
    endif
    
    call add(l:added, {
      \ 'lnum': l:found.lnum,
      \ 'list': prop_list(l:found.lnum, {'bufnr': a:bufnr})
      \ })
    
    let l:lnum = l:found.lnum + 1
  endwhile

  return l:added
endfunction
