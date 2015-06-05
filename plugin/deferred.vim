" Location:     plugin/deferred.vim
" Author:       Kevin Ushey <http://kevinushey.github.io>
" Version:      0.1
" License:      Same as Vim itself.  See :help license

if exists('g:loaded_deferred') || &cp
    finish
endif
let g:loaded_deferred = 1

" The set of autocmd events that will serve as default
" triggers for the 'Defer' command.
if !exists('g:DeferredEvents')
    let g:DeferredEvents = ['CursorHold', 'CursorHoldI', 'OnNormalModeColon']
endif

let s:DeferredCount = 0
let s:DeferredCommands = []

function! s:DeferCommandImpl(events, command)

    let l:ID = s:DeferredCount
    let s:DeferredCount += 1

    let GroupName = "Deferred_" . l:ID
    let DeleteCommand = join(['autocmd!', GroupName, a:events, '*'], ' ')

    execute "augroup " . GroupName
    execute "   autocmd!"
    execute "   autocmd " . Events . " * " . Command . " | " . DeleteCommand
    execute "augroup end"

endfunction

function! s:DeferCommand(command, events)
    return s:DeferCommandImpl(a:events, a:command)
endfunction

function! s:DeferUntilCommand(quoted)
    let FirstSpaceIdx = stridx(a:quoted, ' ')
    let Events = strpart(a:quoted, 0, FirstSpaceIdx)
    let Command = strpart(a:quoted, FirstSpaceIdx + 1)
    return s:DeferCommandImpl(Events, Command)
endfunction

" Example:
" 
"    Defer :echo 'Hello!'
"
" The command will be called after an event in the
" 'g:DeferredEvents' set is triggered.
command! -nargs=* Defer
\ call DeferCommand(<q-args>, join(g:DeferredEvents))

" Example:
"
"    DeferUntil BufEnter :echo 'Hello!'
"
" The command will be called after the autocmd event
" specified as the first 'argument' to the command is
" entered. The set of arguments should be specified as a
" comma-delimited string with no spaces.
command! -nargs=* DeferUntil
\ call DeferUntilCommand(<q-args>)

" Allow ':' to trigger deferred events.
function! DeferColon()
    doautocmd OnNormalModeColon *
    return ":"
endfunction

if strlen(maparg(':', 'n')) == 0
    nmap <expr>: DeferColon()
endif
