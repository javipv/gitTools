" Script Name: gitTools/grep.vim
 "Description: 
"
" Copyright:   (C) 2023-2024 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: jobs.vim
"
"

"- functions -------------------------------------------------------------------


" Use the git grep command
" Arg1: [text], text to be searched.
" Arg2: [file], file where searching the text.
" Commands: Gitg
function! gitTools#grep#Grep(options,...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let l:optionsName = substitute(a:options, "-", "", "g")
    let l:pattern = ""

    if len(a:000) >= 1
        let l:pattern = gitTools#tools#TrimString(a:1)
    endif

    if len(a:000) >= 2
        let l:file = gitTools#tools#TrimString(a:2)
    endif

    if l:pattern == ""
        let l:pattern = expand("<cword>")
        redraw
        if confirm("[gitTools.vim] Search pattern: '".l:pattern."'?", "&yes\n&no", 1) == 2
            redraw
            let l:pattern = input("[gitTools.vim] Search pattern: ")
        endif
    endif

    if l:pattern == ""
        call gitTools#tools#Error("ERROR: empty grep pattern.")
        return
    endif

    let l:date     = strftime("%y%m%d_%H%M")
    let l:name     = "_".l:date."_gitGrep_".l:optionsName."___".l:pattern.".log"
    let l:command  = g:gitTools_gitCmd." grep ".a:options." '".l:pattern."' -- *"
    let l:callback = ["gitTools#grep#GrepEnd", l:name, l:command]

    redraw
    echo l:command
    call gitTools#tools#WindowSplitMenu(3)
    call gitTools#tools#SystemCmd(l:command, l:callback, 1)
endfunction


function! gitTools#grep#GrepEnd(name, cmd, resfile)
    if !exists('a:resfile') || empty(glob(a:resfile)) 
        call gitTools#tools#Warn("Git log search empty")
        return
    endif

    let fileList = readfile(a:resfile)

    if l:fileList[0]  =~ "fatal: not a git repository"
        call gitTools#tools#Error("ERROR: not a git repository")
        return
    endif

    call gitTools#tools#WindowSplit()

    " Rename buffer
    silent! exec("0file")
    silent! exec("bd! ".a:name)
    silent! exec("file! ".a:name)

    " Add header
    let l:textList = [ " [gitTools.vim] ".a:cmd ]
    let l:header = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
    silent put=l:header

    " Add the log info
    silent put =  readfile(a:resfile)
    normal ggdd

    call delete(a:resfile)
    call gitTools#tools#WindowSplitEnd()
    redraw
    set ft=diff

    "call s:SetSyntaxAndHighlighting("")

    " Set buffer parameters
    setl noswapfile
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    setl nonu
endfunction


