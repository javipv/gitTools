" Script Name: gitTools/descrive.vim
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


" Perform git describe
" Arg1: options.
" Arg2: [optional] hash number
" Cmd: Gitdesca
function! gitTools#describe#Describe(options, ...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    if a:0 >= 1
        let l:hash = a:1
    else
        let l:line = gitTools#tools#TrimString(getline("."))
        if l:line =~ "commit"
            " Get hash from current line
            let l:lineList = split(l:line)
            "echom "Add hash: ".l:hash
            let l:hash = l:lineList[1]
        else
            let l:hash = expand("<cword>")
        endif
    endif

    if l:hash == ""
        call gitTools#tools#Error("[gitTools.vim] Git describe. No hash found.")
        return
    endif

    if gitTools#utils#CheckHash(l:hash)
        return
    endif

    let l:optionsName = substitute(a:options, "--", "_", "g")
    let l:name = "_gitDescribe_".l:optionsName."__".l:hash.".diff"

    let l:cmd = g:gitTools_gitCmd." describe ".a:options." ".l:hash
    let l:callback = [ "gitTools#describe#DescribeCallback", l:name, l:cmd ]

    call gitTools#tools#SystemCmd(l:cmd, l:callback, 1)

    redraw
    echo l:cmd." ... in progress on background (Check state with :Jobsl)"
endfunction


function! gitTools#describe#DescribeCallback(name, cmd, output)
    if !exists('a:output')
        call gitTools#tools#Warn("Git result not found. ".a:cmd)
    endif

    if empty(glob(a:output)) 
        eall gitTools#tools#Warn("Git result empty. ".a:cmd)
    endif

    " Open result file
    silent exec "new ".a:output

    " Add header on top
    let l:textList = [ " [gitTools.vim] ".a:cmd." " ]
    let l:text = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
    normal ggO
    put=l:text
    normal ggdd

    " Set buffer parameters
    setl noswapfile
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    setl nonu

    " Change name
    silent exec("0file")
    silent! exec("file ".a:name)

    " Resize window
    silent resize 5
endfunction


