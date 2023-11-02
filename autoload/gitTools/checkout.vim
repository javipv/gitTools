" Script Name: gitTools/checkout.vim
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


" Perform git checkout
" Arg1: options, use "new" to checkout to a new branch.
" Arg2: [new branch] new branch name.
" Cmd: Gitco, Gitcob
function! gitTools#checkout#CheckOut(options, ...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    if a:0 >= 1
        let s:newBranch = a:1
    else
        let s:newBranch = ""
    endif

    let s:options = a:options
    let l:branchList =  gitTools#info#GetBranches("Local,NoOrigin,OriginRemote,Separator")
    let l:branchList += [ "#(Use :Gitreme to edit remote branches)" ]

    let l:branchDflt = ""
    if exists("s:lastCheckOutBranch")
        let l:branchDflt = s:lastCheckOutBranch
    elseif exists("g:gitTools_lastBranch")
        let l:branchDflt = g:gitTools_lastBranch
    endif

    let l:header = [ "[gitTools] Git checkout. Select branch:" ]
    let l:callback = "gitTools#checkout#CheckOutBranch"

    call gitTools#menu#AddCommentLineColor("!", "w4*")
    call gitTools#menu#AddCommentLineColor("#", "b*")
    call gitTools#menu#ShowLineNumbers("no")
    call gitTools#menu#OpenMenu(l:header, l:branchList, l:callback, l:branchDflt)
endfunction


" Perform git checkout
" Arg1: options, use "new" to checkout to a new branch.
function! gitTools#checkout#CheckOutBranch(branch)
    redraw

    if a:branch == ""
        call gitTools#tools#Error("[gitTools.vim] No branch selected")
        return
    endif

    let s:lastCheckOutBranch = a:branch
    let g:gitTools_lastBranch = a:branch

    let l:branch = a:branch

    if matchstr(a:branch, "^".g:gitTools_origin."/*") == ""
        let l:remote = g:gitTools_origin."/".a:branch
    endif

    echo "Checkout new branch from origin branch: ".l:branch

    if s:options =~ "-b"
        if s:newBranch == ""
            let s:newBranch = input("New branch name: ")
        endif

        if s:newBranch == ""
            return
        endif

        let l:cmd = g:gitTools_gitCmd." checkout ".l:branch." -b ".s:newBranch
    else
        let l:cmd = g:gitTools_gitCmd." checkout ".l:branch
    endif

    redraw
    echo l:cmd
    if confirm("Continue with the checkout", "&yes\n&no", 2) != 1
        return
    endif

    redraw
    echo l:cmd
    "return
    echo "In progress..."

    " Lauch command in foreground.
    let l:output = system(l:cmd)

    let l:outputList = split(l:output, '\^@')

    if len(l:outputList) > 5
        redraw
        new
        put=l:output

        " Set buffer parameters
        setl noswapfile
        setl nomodifiable
        setl buflisted
        setl bufhidden=delete
        setl buftype=nofile
        setl nonu
    else
        redraw
        echo l:cmd
        echo " "

        for l:line in l:outputList
            echo l:line
        endfor

        if l:output =~ "error" 
            call gitTools#tools#Error("[gitTools.vim] Git checkout failed")
            return
        endif

        echo "Done"
        call confirm("")
    endif
endfunction

