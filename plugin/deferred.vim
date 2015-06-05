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

" TODO: Populate this list dynamically.

" Autocmd Events {{{

let s:InternalAutocmdEvents = [
            \ 'BufAdd',
            \ 'BufCreate',
            \ 'BufDelete',
            \ 'BufEnter',
            \ 'BufFilePost',
            \ 'BufFilePre',
            \ 'BufHidden',
            \ 'BufLeave',
            \ 'BufNew',
            \ 'BufNewFile',
            \ 'BufRead',
            \ 'BufReadPost',
            \ 'BufReadCmd',
            \ 'BufReadPre',
            \ 'BufUnload',
            \ 'BufWinEnter',
            \ 'BufWinLeave',
            \ 'BufWipeout',
            \ 'BufWrite',
            \ 'BufWriteCmd',
            \ 'BufWritePost',
            \ 'CmdUndefined',
            \ 'CmdwinEnter',
            \ 'CmdwinLeave',
            \ 'ColorScheme',
            \ 'CompleteDone',
            \ 'CursorHold',
            \ 'CursorHoldI',
            \ 'CursorMoved',
            \ 'CursorMovedI',
            \ 'EncodingChanged',
            \ 'FileAppendCmd',
            \ 'FileAppendPost',
            \ 'FileAppendPre',
            \ 'FileChangedRO',
            \ 'FileChangedShell',
            \ 'FileChangedShellPost',
            \ 'FileEncoding',
            \ 'FileReadCmd',
            \ 'FileReadPost',
            \ 'FileReadPre',
            \ 'FileType',
            \ 'FileWriteCmd',
            \ 'FileWritePost',
            \ 'FileWritePre',
            \ 'FilterReadPost',
            \ 'FilterReadPre',
            \ 'FilterWritePost',
            \ 'FilterWritePre',
            \ 'FocusGained',
            \ 'FocusLost',
            \ 'FuncUndefined',
            \ 'GUIEnter',
            \ 'GUIFailed',
            \ 'InsertChange',
            \ 'InsertCharPre',
            \ 'InsertEnter',
            \ 'InsertLeave',
            \ 'MenuPopup',
            \ 'QuickFixCmdPre',
            \ 'QuickFixCmdPost',
            \ 'QuitPre',
            \ 'RemoteReply',
            \ 'SessionLoadPost',
            \ 'ShellCmdPost',
            \ 'ShellFilterPost',
            \ 'SourcePre',
            \ 'SourceCmd',
            \ 'SpellFileMissing',
            \ 'StdinReadPost',
            \ 'StdinReadPre',
            \ 'SwapExists',
            \ 'Syntax',
            \ 'TabEnter',
            \ 'TabLeave',
            \ 'TermChanged',
            \ 'TermResponse',
            \ 'TextChanged',
            \ 'TextChangedI',
            \ 'User',
            \ 'UserGettingBored',
            \ 'VimEnter',
            \ 'VimLeave',
            \ 'VimLeavePre',
            \ 'VimResized',
            \ 'WinEnter',
            \ 'WinLeave'
            \ ]

" }}}

function! s:DeferCommandImpl(events, command)

    for event in events

        let l:ID = s:DeferredCount
        let s:DeferredCount += 1

        let MaybeUser = ''
        if !count(s:InternalAutocmdEvents, event)
            let MaybeUser = 'User'
        endif

        let GroupName = "Deferred_" . l:ID
        let AutoCommand = MaybeUser . " " . event . " * " . Command
        let DeleteCommand = join(['autocmd!', MaybeUser, GroupName, a:events, '*'], ' ')

        echomsg AutoCommand

        execute "augroup " . GroupName
        execute "   autocmd!"
        execute "   autocmd " . AutoCommand . " | " . DeleteCommand
        execute "augroup end"

    endfor

endfunction

function! s:DeferCommand(command, events)
    return s:DeferCommandImpl(a:events, a:command)
endfunction

function! s:DeferUntilCommand(quoted)
    let FirstSpaceIdx = stridx(a:quoted, ' ')
    let Events = split(strpart(a:quoted, 0, FirstSpaceIdx), ',')
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
\ call DeferCommand(<q-args>, g:DeferredEvents)

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
    doautocmd User OnNormalModeColon
    return ":"
endfunction

if strlen(maparg(':', 'n')) == 0
    nmap <expr>: DeferColon()
endif


