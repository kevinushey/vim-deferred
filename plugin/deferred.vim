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

function! s:Verbose(...)

    if a:0 > 0
        let Level = a:1
    else
        let Level = 0
    endif

    return exists('g:verbose') && g:verbose > Level

endfunction

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

function! s:SplitOnFirstSpace(string)
    let FirstSpaceIdx = stridx(a:string, ' ')
    let First = strpart(a:string, 0, FirstSpaceIdx)
    let Rest = strpart(a:string, FirstSpaceIdx + 1)
    return [First, Rest]
endfunction

function! DeferredExecuteOnce(quoted)

    let Splat = s:SplitOnFirstSpace(a:quoted)

    let ID = Splat[0]
    let Command = Splat[1]

    let VariableName = 'g:deferred_' . ID
    if exists(VariableName)
        return
    endif

    execute Command
    execute "let " . VariableName . " = 1"

endfunction

function! DeferredFunction(call)
    let Command = ':call ' . call
    Defer Command
endfunction

function! s:DeferCommand(events, command)

    let CommandID = s:DeferredCount

    for Event in a:events

        let GroupID = s:DeferredCount
        let s:DeferredCount += 1

        " TODO: Construct these in a neater way. There's a
        " bunch of ugliness because user events and
        " internal events are specified in a different
        " way.
        if count(s:InternalAutocmdEvents, Event)
            let MaybeUser = ''
            let EventString = Event . " * "
        else
            let MaybeUser = "User"
            let EventString = "User " . Event . " "
        endif

        let GroupName = "Deferred_" . GroupID
        let AutoCommand = EventString .
                    \ 'DeferredExecuteOnce ' . CommandID . ' ' . a:command

        let DeleteCommand = 'autocmd! ' . GroupName . ' ' . MaybeUser . " " . Event

        if s:Verbose()
            echomsg "Deferring command: " . AutoCommand
            echomsg "Killing with: " . DeleteCommand
        endif

        execute "augroup " . GroupName
        execute "   autocmd!"
        execute "   autocmd " . AutoCommand . " | " . DeleteCommand
        execute "augroup end"

    endfor

endfunction

command! -nargs=* DeferredExecuteOnce
            \ call DeferredExecuteOnce(<q-args>)

function! s:DeferUntilCommand(quoted)
    let splat = s:SplitOnFirstSpace(a:quoted)
    return s:DeferCommandImpl(split(splat[0], ','), splat[1])
endfunction

" Example:
" 
"    Defer :echo 'Hello!'
"
" The command will be called after an event in the
" 'g:DeferredEvents' set is triggered.
command! -nargs=* Defer
\ call <SID>DeferCommand(g:DeferredEvents, <q-args>)

" Example:
"
"    DeferUntil BufEnter :echo 'Hello!'
"
" The command will be called after the autocmd event
" specified as the first 'argument' to the command is
" entered. The set of arguments should be specified as a
" comma-delimited string with no spaces.
command! -nargs=* DeferUntil
\ call <SID>DeferUntilCommand(<q-args>)

" Allow ':' to trigger deferred events.
function! DeferColon()
    doautocmd User OnNormalModeColon
    return ":"
endfunction

if strlen(maparg(':', 'n')) == 0
    nnoremap <expr>: DeferColon()
endif


