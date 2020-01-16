function! quickfixsync#include#_(relpath)
  let l:includeDir = g:_quickfixsync_autoload_path.'/quickfixsync/include/'
  execute('source '.l:includeDir.a:relpath)

  try
    return _QuickfixSyncInclude()
  catch
  finally
    delfunction _QuickfixSyncInclude
  endtry
endfunction
