" Complete.vim - Interactive completion for any ex-command
" Author: Matt Sacks <matt.s.sacks@gmail.com> 
" Version: 0.1

if exists("*Complete") || v:version < 700
  finish
endif

let s:completeDefaults = {
      \ 'maxheight': 14
    \ }

" moves the current context into the stream buffer
function! s:goToStream()
  if !exists('s:streamWinNr')
    return 0
  endif
  execute s:streamWinNr . "wincmd w"
  return 0
endfunction

" prints to the stream buffer
" a second argument of 1 can be passed to append to the stream
" otherwise, it will overwrite all contents in the stream
function! s:printToStream(lines)
  if !exists('s:streamWinNr')
    return 0
  endif

  call s:goToStream()

  " clear all text inside of the stream
  0,$delete

  " set its height to the completion list length
  let height = len(a:lines) > s:options.maxheight ?
        \ s:options.maxheight : len(a:lines) ? len(a:lines) : 1
  redraw
  execute "silent! normal z" . height . "\<CR>"

  let i = 1
  if len(a:lines) > 0
    for line in a:lines
      " limit yoself
      if i > s:options.maxheight
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
  exec s:execedWinNr . "wincmd w"
  let s:completions = s:getCommandCompletions(s:cmd . s:args)
  call s:printToStream(s:completions)
  redraw
  echo ':' . s:cmd . s:args
  return 0
endfunction

" takes in a dictionary and configures various script settings
function! s:setOptions(options)
  if empty(a:options)
    return 0
  endif

  " if we're just setting the options to the defaults, just copy the list
  if a:options == s:completeDefaults
    let s:options = copy(s:completeDefaults)
    return 0
  endif

  let s:options = {}

  for option in keys(s:completeDefaults)
    let s:options[option] = has_key(a:options, option) ?
          \ a:options[option] : s:completeDefaults[option]
  endfor

  return 0
endfunction

" cleans up any changed settings and configurations
function! s:cleanup()
  " remove the stream buffer
  exec "silent! bd! " . s:streamBufferNr

  if s:more | set more | endif

  " restore the <C-a> mapping in command mode
  if exists("s:ctrlAMap")
    exec "silent! cnoremap <C-a> " . s:ctrlAMap
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
      execute s:execedWinNr . "wincmd w"
      execute 'silent! ' . s:cmd . ' ' . s:completions[0]
    endif
    return 0

  " if the user typed backspace
  elseif inputnr == "\<BS>"
    " trim the last character from the input stream
    let s:args = s:args[0:-2]

  " if the input is CTRL-C or ESC
  elseif input == "\<C-c>" || input == "\<C-[>"
    call s:cleanup()
    exec s:execedWinNr . "wincmd w"
    return 0

  else
    let s:args .= input
  endif

  call s:printCompletions()
  return 1
endfunction

" main function - call with a command to initialize a complete-as-you-type
" buffer. 2nd optional argument is a dictionary of options
function! Complete(cmd, ...)
  let s:lines      = &lines
  let s:more       = &more
  let s:ctrlAMap   = maparg("<C-a>", "c")
  let s:execedBufferNr = bufnr('')
  let s:execedWinNr = winnr()

  set nomore
  if !empty(s:ctrlAMap) | execute "cunmap <C-a>" | endif

  " initialize argument
  let s:args = " "

  " there's an argument prefix
  if a:cmd =~ '\s\S\+$'
    let s:cmd = strpart(a:cmd, 0, stridx(a:cmd, ' '))
    let s:args .= matchstr(a:cmd, '\s\zs\S\+\ze$')
  else
    let s:cmd = a:cmd
  endif

  " if there was an options object given
  if a:0 > 0 && type(a:1) == 4
    call s:setOptions(a:1)
  else
    call s:setOptions(s:completeDefaults)
  endif

  " create the stream
  bot 1new
  " if this is from a netrw buffer, then things get broken real quick
  if getbufvar(s:execedBufferNr, '&ft') == 'netrw'
    " move it to the bottom
    wincmd J
  endif

  let s:streamWinNr    = winnr()
  let s:streamBufferNr = bufnr('')

  " initialize
  setl statusline=C\ O\ M\ P\ L\ E\ T\ E
  call s:printCompletions()
  while 1
    if s:completeLoop() == 0
      break
    endif
  endwhile

  " bd doesn't work from netrw either! yayy
  if getbufvar(s:execedBufferNr, '&ft') == 'netrw'
    windo silent! if empty(expand('%:p')) | close | endif
  endif

  return 0
endfunction
