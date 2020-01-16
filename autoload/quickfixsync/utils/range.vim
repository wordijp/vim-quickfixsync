function! quickfixsync#utils#range#firstOr(expr1, expr2, or)
  if type(a:expr1) == 3
    for l:x in a:expr1
      if a:expr2(l:x) | return l:x | endif
    endfor
    return a:or
  elseif type(a:expr1) == 4
    for [l:k, l:v] in items(a:expr1)
      if a:expr2(l:k, l:v) | return {l:k : l:v} | endif
    endfor
    return a:or
  endif

  throw 'invalid type, not list or dictionary.'
endfunction

function! quickfixsync#utils#range#any(expr1, expr2)
  "return len(filter(a:expr1, a:expr2)) > 0 ? v:true : v:false

  if type(a:expr1) == 3
    for l:x in a:expr1
      if a:expr2(l:x) | return v:true | endif
    endfor
    return v:false
  elseif type(a:expr1) == 4
    for [l:k, l:v] in items(a:expr1)
      if a:expr2(l:k, l:v) | return v:true | endif
    endfor
    return v:false
  endif

  throw 'invalid type, not list or dictionary.'
endfunction

" @note: required sorted list
function! quickfixsync#utils#range#intersection(lst1, lst2) abort
  let l:intersect = []

  let l:lst1_i = 0
  let l:lst1_n = len(a:lst1)
  let l:lst2_i = 0
  let l:lst2_n = len(a:lst2)
  while l:lst1_i < l:lst1_n && l:lst2_i < l:lst2_n
    if a:lst1[l:lst1_i] == a:lst2[l:lst2_i]
      call add(l:intersect, a:lst1[l:lst1_i])
      let l:lst1_i += 1
      let l:lst2_i += 1
    elseif a:lst1[l:lst1_i] < a:lst2[l:lst2_i]
      let l:lst1_i += 1
    else
      let l:lst2_i += 1
    endif
  endwhile

  return l:intersect
endfunction

" @note: required sorted and nested list
function! quickfixsync#utils#range#flattenAndUniq(lst, ...) abort
  let l:Fcmp = get(a:, 1, {a, b -> a == b ? 0 : a > b ? 1 : -1})

  let l:n = len(a:lst)
  if l:n == 0 | return [] | endif
  if l:n == 1 | return s:ary(a:lst[0]) | endif

  let l:iota = range(0, l:n-1)

  let l:enum = {
    \  'NONE': 0,
    \  'EXIST': 1,
    \  'END': 2,
    \ }
  let l:its = map(copy(l:iota), {_, v -> [l:enum.NONE, quickfixsync#utils#iterator#new(s:ary(a:lst[v]))]})

  let l:ret = []
  while 1
    " update list value
    for l:i in l:iota
      if l:its[l:i][0] == l:enum.NONE
        let l:its[l:i][0] = (l:its[l:i][1].moveNext()) ? l:enum.EXIST : l:enum.END
      endif
    endfor

    " search min
    let l:exists = filter(copy(l:iota), {_, v -> l:its[v][0] ==  l:enum.EXIST})
    if empty(l:exists)
      break
    endif
    let l:idx = s:min_index(l:exists, {a, b -> l:Fcmp(l:its[a][1].current(), l:its[b][1].current())})
    
    " add unique element
    call add(l:ret, l:its[l:exists[l:idx]][1].current())

    " remove equal
    let l:equals = filter(copy(l:exists), {_, v -> (v == l:exists[l:idx]) || (l:Fcmp(l:its[l:exists[l:idx]][1].current(), l:its[v][1].current()) == 0)})
    for l:i in l:equals
      let l:its[l:i][0] = l:enum.NONE
    endfor
  endwhile

  return l:ret
endfunction

function! quickfixsync#utils#range#flatten(lst) abort
  let l:lst = []
  for l:x in a:lst
    let l:lst += s:ary(l:x)
  endfor
  return l:lst
endfunction

" ---

function! s:min_index(lst, fcmp) abort
  let l:n = len(a:lst)
  if l:n == 0 | return -1 | endif

  let l:min_i = 0

  for l:i in range(1, l:n-1)
    if a:fcmp(a:lst[l:min_i], a:lst[l:i]) > 0
      let l:min_i = l:i
    endif
  endfor

  return l:min_i
endfunction

function! s:ary(elm) abort
  return (type(a:elm) == 3) ? a:elm : [a:elm]
endfunction
