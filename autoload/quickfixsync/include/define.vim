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

function _QuickfixSyncInclude() abort
  return {
    \ 'type2signindex': s:type2signindex,
    \ 'default_signname_map': s:default_signname_map
    \ }
endfunction
