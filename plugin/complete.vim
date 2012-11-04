" Complete.vim - Interactive completion for any ex-command
" Author: Matt Sacks <matt.s.sacks@gmail.com> 
" Version: 0.1

if exists("*Complete") || v:version < 700
  finish
endif

" moves the current context into the stream buffer
function! s:goToStreamBuffer()
  if !exists('s:streamBufferNr')
    return 0
  endif
  execute "silent! b" . s:streamBufferNr
  return ''
endfunction

" prints to the stream buffer
" a second argument of 1 can be passed to append to the stream
" otherwise, it will overwrite all contents in the stream
function! s:printToStream(lines)
  if !exists('s:streamBufferNr')
    return 0
  endif

  call s:goToStreamBuffer()

  " clear all text inside of the stream
  normal ggdG

  " set its height to the completion list length
  let height = len(a:lines) > 8 ? 8 : len(a:lines)
  redraw
  execute "silent! normal z" . height . "\<CR>"

  let i = 1
  if len(a:lines) > 0
    for line in a:lines
      " limit yoself
      if i > 8
        break
      endif

      call setline(i, line)
      let i += 1
    endfor
  else
    call setline(i, "NO RESULTS")
  endif
endfunction

" returns a list of all completions available for a given ex-command
function! s:getCommandCompletions(command)
  let completions = {}
  " all credit goes to the SkyBison plugin for this.
  execute "silent normal :" . a:command .
        \ "\<c-a>\<c-\>eextend(completions, {'cmdline':getcmdline()}).cmdline\n"
  if has_key(completions, 'cmdline')
    return split(strpart(
            \ completions['cmdline'],
            \ stridx(completions['cmdline'], ' ')+1
          \ ), ''
        \ )
  else
    return []
  endif
endfunction

" takes the given command + anything typed and prints the completions into the
" stream buffer
function! s:printCompletions()
  exec "silent! b" . s:execedBufferNr
  let s:completions = s:getCommandCompletions(s:cmd . s:args)
  call s:printToStream(s:completions)
  redraw
  echo ':' . s:cmd . s:args
  return 0
endfunction

" cleans up any changed settings and configurations
function! s:cleanup()
  " remove the stream buffer
  call s:goToStreamBuffer()
  bd!

  exec "set laststatus=" . s:laststatus
  if s:more | set more | endif

  " restore the <C-a> mapping in command mode
  if !empty("s:ctrlAMap")
    exec "cno <C-a> " . s:ctrlAMap
  endif

  if s:cursorline | set cursorline | endif
  return 0
endfunction

" the code being executed every second once Complete() is called
function! s:completeLoop()
  let inputnr = getchar()
  let input   = nr2char(inputnr)

  " if the user typed enter
  if input == "\<CR>" 
    call s:cleanup()
    if len(s:completions) > 0
      execute "silent! " .s:cmd . ' ' . s:completions[0]
    endif
    return 0

  " if the user typed backspace
  elseif inputnr == "\<BS>"
    " trim the last character from the input stream
    let s:args = s:args[0:-2]

  " if the input is CTRL-C or ESC
  elseif input == "\<C-c>" || input == "\<C-[>"
    call s:cleanup()
    return 0

  else
    let s:args .= input
  endif

  call s:printCompletions()
  return 1
endfunction

" main function - call with a command to initialize a complete-as-you-type
" buffer
function! Complete(cmd)
  let s:cursorline = &cursorline
  let s:laststatus = &laststatus
  let s:more       = &more
  let s:ctrlAMap   = maparg("<C-a>", "c")
  let s:execedBufferNr = bufnr('')

  set laststatus=0
  set nomore
  set nocursorline
  if !empty("s:ctrlAMap") | execute "cunmap <C-a>" | endif

  " initialize argument
  let s:args = " "

  " there's an argument prefix
  if a:cmd =~ '\s\S\+$'
    let s:cmd = strpart(a:cmd, 0, stridx(a:cmd, ' '))
    let s:args .= matchstr(a:cmd, '\s\zs\S\+\ze$')
  else
    let s:cmd = a:cmd
  endif

  " create the stream
  bot 1new
  " if this is from a netrw buffer, then things get broken real quick
  if getbufvar(s:execedBufferNr, '&ft') == 'netrw'
    " move it to the bottom
    wincmd J
  endif

  " the stream buf number
  let s:streamBufferNr = bufnr('')

  " initialize
  call s:printCompletions()
  while 1
    if s:completeLoop() == 0
      break
    endif
  endwhile

  " sometimes we get into a nasty state where netrw shits on everything
  if getbufvar(s:execedBufferNr, '&ft') == 'netrw' &&
        \ winheight('') < 10
    only
    let s:hasRun = 1
  endif
  return 0
endfunction
