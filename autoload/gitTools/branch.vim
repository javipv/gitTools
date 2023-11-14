" Script Name: gitTools/branch.vim
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


" Get the git branch configured.
" Return: string with git branch name.
function! gitTools#branch#Current()
    let l:list = []

    let cmd = g:gitTools_gitCmd." branch"
    let text = system(l:cmd)

    if l:text =~ "fatal: not a git repository"
        let l:desc   = substitute(l:text,'','','g')
        let l:desc   = substitute(l:text,'\n','','g')
        call gitTools#tools#Error("ERROR: git branch. ".l:desc)
        return ""
    endif

    if l:text == "" 
        call gitTools#tools#Error("ERROR: git branch. Empty result")
        return ""
    endif

    for l:line in split(l:text, "\n")
        "echom l:line
        let l:fieldsList = split(l:line, " ")
        "echom "'".l:fieldsList[0]."' len:".len(l:fieldsList)
        if l:fieldsList[0] == "*" && len(l:fieldsList) > 1
            "echom "found: '".l:fieldsList[1]."' "
            return l:fieldsList[1]
        endif
    endfor

    return ""
endfunction


" Get git config
" Cmd: Gitbc
function! gitTools#branch#Config()
    let l:branch = gitTools#branch#Current()
    let l:cmd = g:gitTools_gitCmd. " config --list --show-origin | grep ".l:branch

    let l:configStr = system(l:cmd)
    let l:configList = split(l:configStr, "\n")

    "echo "[gitTools] Config: ".l:cmd
    let l:textList = [ "[gitTools] Branch config: ".l:cmd ]
    let l:header = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
    echo l:header

    for l:configLine in l:configList
        let l:config = split(l:configLine)
        echo l:config[1]
    endfor
    "echo l:config
endfunction


"=================================================================================
" GIT BRANCH RENAME
"=================================================================================

" Rename branch
" Cmd: Gitbmv, GitBmv
function! gitTools#branch#Rename()
    "echo "[gitTools.vim] Rename branch: "

    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let l:branchList =  gitTools#branch#GetBranchList("NoOrigin")
    if l:branchList == [] | return | endif

    let l:branchDflt = ""
    if exists("s:lastBranch")
        let l:branchDflt = s:lastBranch
    elseif exists("g:gitTools_lastLocalBranch")
        let l:branchDflt = g:gitTools_lastLocalBranch
    elseif exists("g:gitTools_lastBranch")
        let l:branchDflt = g:gitTools_lastBranch
    endif

    if l:branchDflt == ""
        let l:branchDflt =  gitTools#branch#Current()
    endif

    let l:header = [ "[gitTools] Move branch. Select branch:" ]
    let l:callback = "gitTools#branch#RenameBranch"
    call gitTools#menu#OpenMenu(l:header, l:branchList, l:callback, l:branchDflt)
endfunction


function! gitTools#branch#RenameBranch(branch)
    let @" = a:branch
    echo "Current branch name: ".a:branch." copied to default buffer, paste with Ctr+r+\""
    let l:branchRename = input("Rename branch ".a:branch." to: ")

    if l:branchRename == "" || l:branchRename == a:branch
        redraw
        return
    endif

    let s:lastBranch = l:branchRename
    let g:gitTools_lastLocalBranch = l:branchRename
    let g:gitTools_lastBranch = l:branchRename

    let l:gitCmd  = g:gitTools_gitCmd
    let l:cmd = g:gitTools_gitCmd." branch -m ".a:branch." ".l:branchRename
    redraw
    echo l:cmd
    call confirm("Rename branch: ".a:branch." to ".l:branchRename)

    redraw
    echo l:cmd
    echo " "

    let l:result = system(l:cmd)
    redraw
    echo l:cmd." done ".l:result

    call gitTools#branch#Rename()
endfunction


"=================================================================================
" GIT SWITCH
"=================================================================================

" Switch to another branch.
" Cmd: Gitsw
function! gitTools#branch#Switch()
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let l:thisBranch =  gitTools#branch#Current()
    if l:thisBranch == "" | return | endif

    let l:branchList =  gitTools#branch#GetBranchList("NoOrigin,NoDefault")
    if l:branchList == [] | return | endif

    let l:branchDflt = ""
    if exists("s:lastSwitchBranch")
        let l:branchDflt = s:lastSwitchBranch
    elseif exists("g:gitTools_lastBranch")
        let l:branchDflt = g:gitTools_lastBranch
    endif


    let l:header = [ "[gitTools] Git switch. Select branch: (current: ".l:thisBranch.")" ]
    let l:callback = "gitTools#branch#SwitchToBranch"
    call gitTools#menu#OpenMenu(l:header, l:branchList, l:callback, l:branchDflt)
endfunction


" Switch to another branch.
" Arg1: branch name.
function! gitTools#branch#SwitchToBranch(branch)
    if a:branch == ""
        call gitTools#tools#Error("[gitTools.vim] No branch selected")
        return
    endif

    let s:lastSwitchBranch = a:branch
    let g:gitTools_lastBranch = a:branch

    "let l:thisBranch =  gitTools#info#GetCurrentBranch()
    let l:thisBranch =  gitTools#branch#Current()
    if l:thisBranch == "" | return | endif

    let l:cmd = g:gitTools_gitCmd." switch ".a:branch

    redraw
    echo l:cmd
    call confirm("Switch from branch ".l:thisBranch." to: ".a:branch)

    redraw
    echo l:cmd
    echo " "

    let l:result = system(l:cmd)
    redraw
    new

    " Rename buffer
    let l:date = strftime("%y%m%d_%H%M")
    let l:name = "_".l:date."_gitSwitch___".l:thisBranch."__to__".a:branch

    silent! exec("0file")
    silent! exec("bd! ".l:name)
    silent! exec("file! ".l:name)

    " Add header
    let l:list = [ " [gitTools.vim] ".l:cmd ]
    let l:header = gitTools#tools#EncloseOnRectangle(l:list, "bold", "")
    silent put=l:header

    " Add git switch result content
    silent put=l:result
    normal ggdd
    normal G

    " Set buffer parameters
    setl noswapfile
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    setl nonu

    if exists('g:HiLoaded')
        let g:HiCheckPatternAvailable = 0

        silent! call hi#config#PatternColorize("error:", "r*")
        silent! call hi#config#PatternColorize("Aborting", "m@*")

        let g:HiCheckPatternAvailable = 1
    endif
endfunction


"=================================================================================
" GIT BRANCH
"=================================================================================

" Show all available branches:
" Cmd: Gitb
function! gitTools#branch#Branch(options)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let cmd = g:gitTools_gitCmd." branch ".a:options
    echo l:cmd
    let text = system(l:cmd)

    if l:text =~ "fatal: not a git repository"
        let l:desc   = substitute(l:text,'','','g')
        let l:desc   = substitute(l:text,'\n','','g')
        call gitTools#tools#Error("ERROR: ".l:desc)
        return
    endif

    if l:text == "" 
        call gitTools#tools#Error("No branch found")
        return
    endif

    let l:branchList = []
    let l:branchDflt = ""

    for branch in split(l:text, "\n")
        if l:branch[0] == "*"
            let l:branchDflt = substitute(l:branch, "* ", "", "g")
            let l:branchList += [ l:branchDflt ]
        else
            let l:tmp = substitute(l:branch, "  ", "", "g")
            let l:branchList += [ l:tmp ]
        endif
    endfor

    if a:options =~ "-vv"
        call gitTools#menu#AddPatternColor("\\[.*]", "b1")
        call gitTools#menu#AddPatternColor("'.*'", "y1")
    endif
    let l:header = [ "[gitTools] Git branch:" ]
    let l:callback = "gitTools#branch#SelectBranchName"
    call gitTools#menu#OpenMenu(l:header, l:branchList, l:callback, l:branchDflt)

    redraw
    echo "[gitTools.vim] Current branch: ".l:branchDflt
endfunction

function! gitTools#branch#SelectBranchName(branch)
    let l:list = split(a:branch)
    let @" = l:list[0]
    echo "[gitTools.vim] Branch name copied to default buffer (".l:list[0].")."
endfunction


"=================================================================================
" GIT BRANCH DELETE
"=================================================================================

" Delete branch:
" Cmd: Gitbd
function! gitTools#branch#Delete()
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let l:branchList =  gitTools#branch#GetBranchList("NoOrigin,NoDefault")
    if l:branchList == [] | return | endif

    let l:branchDflt = ""
    if exists("s:lastBranch")
        let l:branchDflt = s:lastBranch
    elseif exists("g:gitTools_lastLocalBranch")
        let l:branchDflt = g:gitTools_lastLocalBranch
    elseif exists("g:gitTools_lastBranch")
        let l:branchDflt = g:gitTools_lastBranch
    endif


    let l:header = [ "[gitTools] Delete local branch. Select branch:" ]
    let l:callback = "gitTools#branch#DeleteBranchName"
    call gitTools#menu#SetHeaderColor("o@")
    call gitTools#menu#OpenMenu(l:header, l:branchList, l:callback, l:branchDflt)
endfunction


function! gitTools#branch#DeleteBranchName(branch)
    call confirm("ATTENTION: local branch ".a:branch." will be DELETED!")
    redraw

    let l:cmd = g:gitTools_gitCmd." branch -D ".a:branch
    echo l:cmd
    let l:text = "DELETE local branch: ".a:branch

    if confirm(l:text, "&Yes\n&no", 2) != 1
        continue
    endif

    redraw
    echo l:cmd
    echo "In progress..."

    let l:output = system(l:cmd)
    redraw
    echo l:cmd
    echo " "

    for l:line in split(l:output, '\^@')
        echo l:line
    endfor

    if l:output =~ "error" 
        call gitTools#tools#Error("[gitTools.vim] ".l:cmd." failed")
    else
        call confirm("Done")
    endif

    call gitTools#branch#Delete()
endfunction


"=================================================================================
" COMMON
"=================================================================================

" Get all available branches:
" Return: list with all branches.
function! gitTools#branch#GetLocalBranchList()
    let l:list = []
    let l:gitCmd  = g:gitTools_gitCmd

    let text = system(l:gitCmd." branch ")

    if l:text == "" 
        return l:list
    endif

    silent new
    normal ggO
    silent put=l:text
    normal ggdd

    silent exec "g/^$/d"

    if line('$') == 1 && getline(".") == ""
        " Empty file
    else
        " Get last column. File paths.
        silent normal gg0wG$"zy
        let files = @z
        "echom "Files: ".l:files
        let list = split(l:files, "\n")

        if len(l:list) == 0
            " Only one file.
            let list = [ l:files ]
        endif
        "echom "Git status list: "l:list
    endif

    silent quit!
    return l:list
endfunction


" Get sandbox branches
" Arg1: options
"   NoOrigin  : to hide origin branch.
"   NoDefault : to hide current branch.
"   Remote    : to add saved remote branches.
" Return: branches list.
function! gitTools#branch#GetBranchList(options)
    redraw
    "let l:default = gitTools#info#GetCurrentBranch()
    let l:default = gitTools#branch#Current()
    if l:default == "" | return | endif

    if a:options =~ "NoOrigin"
        let l:branchList = []
    else
        let l:branchList = ["origin"]
    endif

    let l:branchList += gitTools#branch#GetLocalBranchList()

    if a:options =~ "NoDefault"
        " Remove current branch
        let l:i = index(l:branchList, l:default)
        if l:i != 0
            call remove(l:branchList, l:i, l:i)
        endif
    endif

    if len(l:branchList) == 0
        call gitTools#tools#Warn("[gitTools.vim] No branch found")
        return []
    endif

    return l:branchList
endfunction

