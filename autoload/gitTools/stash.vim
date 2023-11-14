" Script Name: gitTools.vim
 "Description: git stash helper functions.
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: git, hi.vim
"
" NOTES:
"

"- functions -------------------------------------------------------------------


"=================================================================================
" GIT STASH
"=================================================================================

" git stash show.
" Cmd: Gitsth
" Arg1: arg [optional]
"  Use stash number (0, 1, 2, 3...) to show stash diff.
"  Empty to show the stash list.
function! gitTools#stash#Show(arg)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let l:argNum = str2nr(a:arg)

    if a:arg == "" || a:arg == "l" || a:arg == "list"
        call s:StashList()
    elseif a:arg == "0" || l:argNum != 0
        call s:StashShow(a:arg)
    endif
endfunction


" git stash list.
function! s:StashList()
    call gitTools#tools#WindowSplitMenu(3)
    call gitTools#tools#WindowSplit()

    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let l:textList = []
    let l:textList += [ " [gitTools.vim]" ]
    let l:textList += [ "  git stash list                                                     " ]
    let l:header1 = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")

    let l:textList = []
    let l:textList += [ " [gitTools.vim]" ]
    let l:textList += [ "  git stash list --stat                                              " ]
    let l:header2 = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")

    silent put=l:header1
    silent exec("r! git stash list")

    let tmp="" | put=l:tmp

    silent put=l:header2
    silent exec("r! git stash list --stat")

    call gitTools#tools#WindowSplitEnd()

    " Rename buffer
    let name = "_gitStashList.txt"
    silent! exec("0file")
    silent! exec("bd! ".l:name)
    silent! exec("file! ".l:name)

    normal ggdd

    if exists('g:HiLoaded')
        let g:HiCheckPatternAvailable = 0
        silent! call hi#config#PatternColorize("stash@", "w*")
        silent! call hi#config#PatternColorize("+", "g")
        silent! call hi#config#PatternColorize("-", "r")
        let g:HiCheckPatternAvailable = 1
    endif
endfunction


"=================================================================================
" GIT STASH (with menu)
"=================================================================================

" git stash list.
" Cmd: Gitsthl
function! gitTools#stash#List()
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let l:stash = system("git stash list")
    let l:stashList = split(l:stash, "\n")

    if len(l:stashList) == 0
        call gitTools#tools#Warn("[gitTools.vim] Empty stash.")
        return
    endif

    " Open menu window to choose the stash number.
    let l:callback = "gitTools#stash#ListShowNum"
    let l:header = [ "[gitTools] Git stash. Select to show stash changes: " ]

    call gitTools#menu#ShowLineNumbers("no")
    call gitTools#menu#AddCommentLineColor("#", "b*")
    call gitTools#menu#OpenMenu(l:header, l:stashList, l:callback, "")
endfunction

function! gitTools#stash#ListShowNum(text)
    if a:text == "" | return | endif

    let l:stash = substitute(split(a:text)[0], "stash@{", "", "")
    let l:num = substitute(l:stash, "}:", "", "")

    if l:num == "" | return | endif

    call s:StashShow(l:num)
endfunction


"=================================================================================
" GIT STASH SAVE
"=================================================================================

" git stash save.
" Cmd: Gitsthmv, gitsthcp
" Arg1: option to add on git save command.
" Arg2: comment [optional], stash message
function! gitTools#stash#Save(option, comment)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    if a:option !~ "-k" && a:option !~ "--keep"
        if confirm("Move current changes to the stash?", "&yes\n&no", 2) != 1
            return
        endif
        redraw
    endif

    let l:date = strftime("%y%m%d_%H%M")

    if a:comment == ""
        let l:comment = l:date." ".input("Enter stash comment: ".l:date." ")
    else
        let l:comment = a:comment
    endif

    if l:comment != ""
        let l:comment = "\"".l:comment."\""
    endif

    let l:cmd = "git stash save ".a:option.l:comment
    echo " "
    echo l:cmd

    let l:result = system(l:cmd)
    echo l:result
    echo " "
    call s:printStashList()
    call confirm("")
endfunction


"=================================================================================
" GIT STASH APPLY
"=================================================================================

" git stash apply.
" Cmd: Gitstha
" Arg1: stash number
function! gitTools#stash#Apply(...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    if a:0 == 0
        let l:stash = system("git stash list")
        let l:stashList = split(l:stash, "\n")

        if len(l:stashList) == 0
            call gitTools#tools#Warn("[gitTools.vim] Empty stash.")
            return
        endif

        " Open menu window to choose the stash number.
        let l:callback = "gitTools#stash#ApplyStashLine"
        let l:header = [ "[gitTools] Git stash apply. Select stash number: " ]

        call gitTools#menu#ShowLineNumbers("no")
        call gitTools#menu#AddCommentLineColor("#", "b*")
        call gitTools#menu#OpenMenu(l:header, l:stashList, l:callback, "")
    else
        let l:num = str2nr(a:1)
        if s:isStashNumAvailable(l:num) <= 0
            call gitTools#tools#Error("ERROR: unknown stash ".l:num)
            return
        endif
        call gitTools#stash#ApplyNumber(l:num)
    endif
endfunction

function! gitTools#stash#ApplyStashLine(text)
    if a:text == "" | return | endif

    let l:stash = substitute(split(a:text)[0], "stash@{", "", "")
    let l:num = substitute(l:stash, "}:", "", "")

    if l:num == "" | return | endif

    call gitTools#stash#ApplyNumber(l:num)
endfunction

function! gitTools#stash#ApplyNumber(num)
    if confirm("Apply changes on stash #".a:num."?", "&Yes\n&no", 2) != 1
        return
    endif

    let l:cmd = "git stash apply ".a:num
    echo l:cmd

    let l:result = system(l:cmd)
    echo l:result
    echo " "
    call s:printStashList()
    call confirm("")
endfunction


"=================================================================================
" GIT STASH DELAY
"=================================================================================

" git stash delete.
" Cmd: Gitsthd
" Arg1: stash number
function! gitTools#stash#Delete(...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    if a:0 == 0
        let l:stash = system("git stash list")
        let l:stashList = split(l:stash, "\n")

        if len(l:stashList) == 0
            call gitTools#tools#Warn("[gitTools.vim] Empty stash.")
            return
        endif

        " Open menu window to choose the stash number.
        let l:callback = "gitTools#stash#DeleteStashLine"
        let l:header = [ "[gitTools] Git stash delete. Select stash number: " ]

        call gitTools#menu#ShowLineNumbers("no")
        call gitTools#menu#SetHeaderColor("r*")
        call gitTools#menu#AddCommentLineColor("#", "b*")
        call gitTools#menu#OpenMenu(l:header, l:stashList, l:callback, "")
    else
        let l:num = str2nr(a:1)
        if s:isStashNumAvailable(l:num) <= 0
            call gitTools#tools#Error("ERROR: unknown stash ".l:num)
            return
        endif
        call gitTools#stash#DeleteNumber(l:num)
    endif

endfunction

function! gitTools#stash#DeleteStashLine(text)
    if a:text == "" | return | endif

    let l:stash = substitute(split(a:text)[0], "stash@{", "", "")
    let l:num = substitute(l:stash, "}:", "", "")

    if l:num == "" | return | endif

    call gitTools#stash#DeleteNumber(l:num)
endfunction

function! gitTools#stash#DeleteNumber(num)
    if confirm("ATTENTION! Delete stash #".a:num."?", "&Yes\n&no", 2) != 1
        return
    endif

    let l:cmd = "git stash drop stash@{".a:num."}"
    echo l:cmd

    let l:result = system(l:cmd)
    echom l:result
    echo " "
    call s:printStashList()
    call confirm("")
endfunction


"=================================================================================
" COMMON/LOCAL
"=================================================================================

function! s:isStashNumAvailable(num)
    let l:stashList = system("git stash list")
    let l:stashList = split(l:stashList, "\n")
    let l:stashNum = len(l:stashList)

    if a:num < 0 || a:num > l:stashNum-1
        let n = l:stashNum -1
        call gitTools#tools#Error("ERROR: stash ".a:num." not found. Only ".l:n." stashes available.")
        return l:stashNum
    endif
    return 0
endfunction


function! s:printStashList()
    echo " "
    echo "Stash: "
    let l:stash = system("git stash list")
    echo l:stash

    let l:stashList = split(l:stash, "\n")
    return len(l:stashList)
endfunction


function! s:chooseStashNumber()
    let l:stash = system("git stash list")

    let l:stashList = split(l:stash, "\n")
    let l:len = len(l:stashList)
    
    while 1
        echo "Stash list:"
        for l:line in l:stashList | echo "  ".l:line | endfor
        let l:input = input("Choose stash number: ")
        echo " "

        if l:input != "" && "0123456789" =~ l:input[0]
            let l:n = str2nr(l:input)
            if l:n >= 0 && l:n < l:len
                return l:n
            endif
        endif
        call gitTools#tools#Warn("Invalid stash number ".l:input)
        echo " "
    endwhile
endfunction


function! s:StashShow(arg)
    call gitTools#tools#WindowSplitMenu(3)
    call gitTools#tools#WindowSplit()

    silent exec("r! git stash show ".a:arg)

    let tmp = "" | silent put=l:tmp
    silent %s/^/# /g

    let l:tmp = [ "#====================================================================================== " ]
    silent! put=l:tmp

    silent exec("r! git stash show --src-prefix='' --dst-prefix='' -p ".a:arg)

    " Add header
    let l:textList = []
    let l:textList += [ "#====================================================================================== " ]
    let l:textList += [ "# [gitTools.vim]" ]
    let l:textList += [ "#  git stash show ".a:arg." " ]
    let l:textList += [ "#  git stash show -p ".a:arg." " ]
    let l:textList += [ "#====================================================================================== " ]
    normal ggO
    silent! put=l:textList

    call gitTools#tools#WindowSplitEnd()

    " Rename buffer
    let name = "_gitStash".a:arg.".diff"
    silent! exec("0file")
    silent! exec("bd! ".l:name)
    silent! exec("file! ".l:name)

    normal ggdd
    set ft=diff
endfunction
