" Script Name: gitTools/showref.vim
 "Description: 
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: 
"
"

"- functions -------------------------------------------------------------------


" Get the git show-ref command answer.
function! gitTools#showref#args(args)
    let args = "_".a:args
    silent! let args = substitute(l:args, '-', '', 'g')
    silent! let args = substitute(l:args, ' ', '_', 'g')

    let cmd = g:gitTools_gitCmd." show-ref ".a:args
    redraw
    echo l:cmd
    call gitTools#tools#WindowSplitMenu(4)

    let text = system(l:cmd)

    if l:text =~ "fatal: not a git repository"
        let l:desc   = substitute(l:text,'','','g')
        let l:desc   = substitute(l:text,'\n','','g')
        call gitTools#tools#Error("ERROR: git branch. ".l:desc)
        return ""
    endif

    if l:text == "" 
        call gitTools#tools#Error("ERROR: git show-ref Empty result")
        return ""
    endif

    redraw
    call gitTools#tools#WindowSplit()
    call gitTools#tools#WindowSplitEnd()

    " Open result file
    "silent exec "edit ".a:output
    silent put = l:text
    normal ggdd

    "echom "Lines1: '".getline(".")."' Lines:".line("$")
    if getline(".") == "" && line("$") == 1
        quit
        redraw
        call gitTools#tools#Warn("Empty")
        return
    endif

    redraw
    echo "[gitTools.vim] Found ".line("$")." rev-list"

    " Rename buffer
    let l:date = strftime("%y%m%d_%H%M")
    let l:name = "_".l:date."_gitShowRef".l:args

    silent! exec("0file")
    silent! exec("bd! ".l:name)
    silent! exec("file! ".l:name)

    " Add header
    let l:list = [ " [gitTools.vim] ".l:cmd." " ]
    let l:header = gitTools#tools#EncloseOnRectangle(l:list, "bold", "")
    normal gg
    silent put=l:header
    normal ggdd3jp

    " Set buffer parameters
    setl noswapfile
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    setl nonu
endfunction

