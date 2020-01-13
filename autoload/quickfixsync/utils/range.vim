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

function! quickfixsync#utils#range#intersection(lst1, lst2) abort
  " NOTE: required sorted list
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
