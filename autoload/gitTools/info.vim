" Script Name: gitTools/info.vim
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


" Get git describe
" Return: current git description
" Cmd: Gitid
function! gitTools#info#Describe()
    let l:cmd = g:gitTools_gitCmd." describe --always --tags --dirty"
    let l:cmd1 = g:gitTools_gitCmd." describe --all"

    silent! let l:desc = system(l:cmd)
    let l:desc = substitute(l:desc, "\n", "", "g")

    silent! let l:desc1 = system(l:cmd1)
    let l:desc1 = substitute(l:desc1, "\n", "", "g")

    echon "[gitTools.vim] ".l:cmd.": "
    echohl DiffAdd | echon l:desc | echohl None
    echon "   ".l:cmd1.": "
    echohl DiffText | echon l:desc1 | echohl None
endfunction


" Get git info
" Return: git information: revision, branch...
" Cmd: Giti
function! gitTools#info#Info()
    "let l:branch = gitTools#info#GetCurrentBranch()
    let l:branch = gitTools#branch#Current()
    if l:branch == "" | return | endif

    let l:header = "[gitTools.vim] Git info:"
    let l:gitCmd = g:gitTools_gitCmd
    let l:rev    = "Revision: ".system(l:gitCmd. " rev-list --count HEAD")
    let l:desc   = "Describe: ".system(l:gitCmd." describe --always --tags --dirty")
    "let l:branch = "Branch:   ".gitTools#info#GetCurrentBranch()
    let l:branch = "Branch:   ".l:branch

    echo l:header
    echo l:rev
    echo l:desc
    echo l:branch
endfunction


" Get git config
" Return: git config information
" Cmd: Gitc
function! gitTools#info#Config()
    let l:cmd = g:gitTools_gitCmd. " config --list --show-origin"

    let l:configStr = system(l:cmd)
    let l:configList = split(l:configStr, "\n")

    "echo "[gitTools] Config: ".l:cmd
    let l:textList = [ "[gitTools] Config: ".l:cmd ]
    let l:header = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
    echo l:header

    for l:configLine in l:configList
        let l:config = split(l:configLine)
        echo l:config[1]
    endfor
    "echo l:config
endfunction


"=================================================================================
" COMMON
"=================================================================================

" Open menu to choose a branch.
" Arg1: options
"   NoOrigin  : to hide origin branch.
"   NoDefault : to hide current branch.
"   Remote    : to add saved remote branches.
" Return: choosen branch.
function! gitTools#info#ChooseBranchMenu(options)
    redraw
    "let l:default = gitTools#info#GetCurrentBranch()
    let l:default = gitTools#branch#Current()
    if l:default == "" | return | endif

    if a:options =~ "NoOrigin"
        let l:branchList = []
    else
        let l:branchList = [ g:gitTools_origin ]
    endif

    "let l:branchList += gitTools#info#Branches()
    let l:branchList += gitTools#branch#GetLocalBranchList()

    if a:options =~ "NoDefault"
        " Remove current branch
        let l:i = index(l:branchList, l:default)
        if l:i != 0
            call remove(l:branchList, l:i, l:i)
        endif
    endif

    if a:options =~ "Remote"
        let l:branchList += gitTools#remote#GetRemoteBranchList()
    endif

    if len(l:branchList) == 0
        call gitTools#tools#Warn("[gitTools.vim] No branch found")
    endif

    while 1
        let l:i = 1
        for l:branch in l:branchList
            if l:branch == l:default
                let l:info = " (*)"
                echohl DiffAdd
            else
                let l:info = ""
            endif

            echo l:i.") ".l:branch.l:info
            echohl None
            let l:i += 1
        endfor

        let l:str = input("Choose branch: ")

        if l:str == ""
            if a:options !~ "NoDefault"
                echo "Use default branch: ".l:default
                return l:default
            else
                return ""
            endif
        endif

        let l:n = str2nr(l:str)
        echo " "

        if l:n > 0 && l:n <= len(l:branchList)
            let l:branch = l:branchList[l:n-1]
            echo "Use branch: ".l:branch
            return l:branch
        endif
    endwhile
endfunction


" Get sandbox branches
" Arg1: options
"   NoOrigin  : to hide origin branch.
"   NoDefault : to hide current branch.
"   Remote    : to add saved remote branches.
" Return: branches list.
function! gitTools#info#GetBranches(options)
    redraw

    let l:default = gitTools#branch#Current()
    if l:default == "" | return | endif

    let l:branchList = []

    if a:options =~ "Local"
        if a:options =~ "Separator"
            let l:branchList += [ "!== Local branches ==" ]
        endif

        if a:options !~ "NoOrigin"
            let l:branchList = [ g:gitTools_origin ]
        endif

        let l:branchList += gitTools#branch#GetLocalBranchList()

        if a:options =~ "NoDefault"
            " Remove current branch
            let l:i = index(l:branchList, l:default)
            if l:i != 0
                call remove(l:branchList, l:i, l:i)
            endif
        endif
    endif

    if a:options =~ "Remote"
        if a:options =~ "Separator"
            let l:branchList += [ "!== Remote branches ==" ]
        endif

        let l:list = gitTools#remote#GetRemoteBranchList()

        if a:options =~ "OriginRemote"
            echom "OriginRemote"
            for l:remote in l:list
                if matchstr(l:remote, "^".g:gitTools_origin."/*") == ""
                    let l:remote = g:gitTools_origin."/".l:remote
                endif
                let l:branchList += [ l:remote ]
            endfor
        else
            let l:branchList += l:list
        endif
    endif

    " Remove duplicates from list:
    let l:branchList = filter(copy(l:branchList), 'index(branchList, v:val, v:key+1)==-1')

    if len(l:branchList) == 0
        call gitTools#tools#Warn("[gitTools.vim] No branch found")
        return []
    endif

    return l:branchList
endfunction

