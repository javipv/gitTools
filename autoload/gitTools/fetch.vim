" Script Name: gitTools/fetch.vim
 "Description: 
"
" Copyright:   (C) 2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: 
"
"

"- functions -------------------------------------------------------------------


" Perform git fetch
" Cmd: Gitf
function! gitTools#fetch#Fetch()
    let l:cmd = g:gitTools_gitCmd." fetch"

    " Lauch command on background with Jobs.vim plugin.
    let l:callback = [ "gitTools#fetch#FetchCallback", l:cmd ]
    call gitTools#tools#SystemCmd(l:cmd, l:callback, 1)

    redraw
    echo l:cmd." ... in progress on background (Check state with :Jobsl)"
endfunction


" Recover result of git fetch command launched on background with Jobs.vim plugin.
function! gitTools#fetch#FetchCallback(cmd, output)
    if !exists('a:output')
        call gitTools#tools#Warn("Git result not found. ".a:cmd)
    endif

    if empty(glob(a:output)) 
        call gitTools#tools#Warn("Git result empty. ".a:cmd)
    endif

    " Open result file
    silent exec "new ".a:output

    " Add header on top
    let l:textList = [ " [gitTools.vim] ".a:cmd." " ]
    let l:text = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
    normal ggO
    put=l:text
    normal ggdd

    setl noswapfile
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    setl nonu

    " Change name
    let l:date = strftime("%y%m%d_%H%M")
    "let l:local = gitTools#info#GetCurrentBranch()
    let l:local = gitTools#branch#Current()
    let l:local = substitute(l:local, '/', '-', 'g')
    let l:filename = "_".l:date."_gitFetch___".l:local

    silent exec("0file")
    silent! exec("file ".l:filename)

    " Resize window
    let l:lastRow = line("$")
    if l:lastRow < winheight(0)
        silent exec("resize ".l:lastRow)
    endif
endfunction

