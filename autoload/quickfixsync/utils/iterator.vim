" class like Iterator
" usage)
"   let it = quickfixsync#utils#iterator([2, 3, 5])
"   while it.moveNext()
"     echo it.current()
"   endwhile
let s:Iterator = {}

function! quickfixsync#utils#iterator#new(lst) abort
  let l:inst = deepcopy(s:Iterator)

  let l:inst.lst = a:lst
  let l:inst.idx = -1
  let l:inst.length = len(a:lst)

  return l:inst
endfunction

function! s:Iterator.moveNext() abort
  let self.idx += 1
  return self.idx < self.length
endfunction

function! s:Iterator.current() abort
  return self.lst[self.idx]
endfunction
