" Script Name: gitTools/reset.vim
 "Description: 
"
" Copyright:   (C) 2017-2021 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: jobs.vim
"
"

"- functions -------------------------------------------------------------------


" Reset the changes
" Arg1: reset type [OPTIONAL]: hard, soft, mixed.
" Arg2: commit number [OPTIONAL]. 
" Commands: Gitreset
function! gitTools#reset#GitReset(...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let l:option = ""
    let l:commitNr = ""

    if len(a:000) >= 1 && a:1 != ""
        if a:1 != "hard" && a:1 != "medium" && a:1 != "soft"
            call gitTools#tools#Error("ERROR: unkown option ".a:1." (use: soft, medium or hard")
            return
        endif
        let l:option = a:1
    endif

    if len(a:000) >= 2 && a:2 != ""
        let l:commitNr .= a:2
    endif

    if l:option == ""
        let l:optionsList = [ "soft", "mixed", "hard" ]
        echo "Git reset options:"
        let l:option = s:ChooseOption(l:optionsList)

        if l:option == ""
            let l:option = "mixed"
        endif
    endif

    if l:commitNr == ""
        let l:word = expand("<cWORD>")
        let l:line = getline('.')
        call confirm("Use hash ".l:word." from line: ".l:line)

        if l:word == ""
            call gitTools#tools#Error("ERROR: revision hash not found.")
            return
        endif

        if len(l:word) < 12
            call gitTools#tools#Error("ERROR: unknown revision hash ".l:word." (expected 12 characters)")
            return
        endif

        let l:hex = str2nr(l:word, 16)
        let l:dec = printf('%d', l:hex)

        if l:dec != 0
            let l:commitNr = l:word
        else
            call gitTools#tools#Error("ERROR: unknown revision hash ".l:hex." (expected hexdecimal number)")
            return
        endif
    endif

    let l:option = "--".l:option

    let l:gitCmd  = g:gitTools_gitCmd
    let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()

    let command  = l:gitCmd." reset ".l:option." ".l:commitNr
    let callback = ["gitTools#reset#GitResetEnd"]

    redraw
    echo l:command
    if confirm("Continue with the reset", "&yes\n&no", 2) != 1
        return
    endif

    if l:option =~ "hard"
        call confirm("ATTENTION: hard reset selected!")
    endif

    call gitTools#tools#SystemCmd(l:command, l:callback, 1)

    redraw
    echo l:command
    echo "In progress..."
endfunction


function! gitTools#reset#GitResetEnd(resfile)
    redraw
    call confirm("Show reference log?")
    redraw
    call gitTools#log#GetRefLog("")
endfunction


function! s:ChooseOption(list)
    if len(a:list) == 0
        call gitTools#tools#Error("ASSERT: chooseOption empty list")
        return ""
    endif

    let l:i = 1

    for l:option in a:list
        echo " ".l:i.") ".l:option
        let l:i += 1
    endfor

    let l:str = input("Choose option: ")

    if l:str == ""
        return ""
    endif

    let l:n = str2nr(l:str)

    if l:n > 0 && l:n <= len(a:list)
        let l:return = a:list[l:n-1]
        return l:return
    endif

    return ""
endfunction

