" Script Name: gitTools/show.vim
 "Description: 
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: jobs.vim
"


"- functions -------------------------------------------------------------------



" Get the current file's selected git revision.
" Arg1: revision number to search.
" Commands: Gitsh
" PENDING: make use of jobs.vim to launch the command on background.
function! gitTools#show#Revision(rev)
    let l:file = expand("%")
    let l:filePathToName = substitute(l:file,"/","_","g")
    let l:ext = expand("%:e")
    let l:name = expand("%:t")

    if a:rev == ""
        let l:rev = substitute(expand("<cword>"), 'r', '', '')
    else
        let l:rev = substitute(a:rev, 'r', '', '')
    endif

    if l:rev == ""
        call gitTools#tools#Warn("Argument 1: revision number not found.")
        return
    endif

    " CHeck revision number lenght:
    if len(l:rev) < 12
        call gitTools#tools#Error("Wrong revision number lenght ".l:rev." (expected lenght >= 12)")
        return
    endif

    " Check contains both numbers and letters:
    let l:numbers = substitute(l:rev, '[^0-9]*', '', 'g')
    let l:letters = substitute(l:rev, '[^a-zA-Z]*', '', 'g')

    if l:numbers == "" || l:letters == ""
        call gitTools#tools#Warn("Found a weird revision number ".l:rev)
        call confirm("Proceed?")
    endif

    let filepath = expand("%")
    let filename = expand("%:t:r")

    echo "Get file: ".l:filename." revision: ".l:rev
    echo " "
    let l:branch = ""
    while l:branch == ""
        echo " "
        echo "[gitTools.vim] Choose branch: "
        let l:branch = gitTools#info#ChooseBranchMenu("")
        if l:branch == "" | return | endif
    endwhile

    call gitTools#tools#WindowSplitMenu(3)
    call gitTools#tools#WindowSplit()

    let l:gitCmd  = g:gitTools_gitCmd
    echo l:gitCmd." show ".l:branch.":".l:file
    echo "This may take a while ..."

    let l:gitCmd  = g:gitTools_gitCmd
    let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()

    silent exec("r !".l:gitCmd." show ".l:branch.":".l:file)

    if line('$') == 1
        call gitTools#tools#WindowSplitEnd()
        call gitTools#tools#Warn("Not found")
        return
    endif

    call gitTools#tools#SetSyntax(l:ext)

    silent exec("0file")
    silent! exec("file _gitShow___rev_".l:rev."__".l:filePathToName)
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile

    call gitTools#tools#WindowSplitEnd()
    redraw
endfunction


