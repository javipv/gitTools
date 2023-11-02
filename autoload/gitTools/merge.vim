" Script Name: gitTools/merge.vim
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


"=================================================================================
" GIT MERGE local branch
"=================================================================================

" Merge branch
" Cmd: Gitmb, GitmbS
function! gitTools#merge#LocalBranch(options)
    "let s:thisBranch =  gitTools#info#GetCurrentBranch()
    let s:thisBranch =  gitTools#branch#Current()
    if s:thisBranch == "" | return | endif

    let l:branchList =  gitTools#branch#GetBranchList("Local,NoOrigin,NoDefault")
    if l:branchList == [] | return | endif
    let l:branchList += [ "#(Use :Gitreme to edit remote branches)" ]

    let s:options = a:options

    let l:branchDflt = ""
    if exists("s:lastLocalMergeBranch")
        let l:branchDflt = s:lastLocalMergeBranch
    elseif exists("g:gitTools_lastLocalBranch")
        let l:branchDflt = g:gitTools_lastLocalBranch
    elseif exists("g:gitTools_lastBranch")
        let l:branchDflt = g:gitTools_lastBranch
    endif

    let l:header = [ "[gitTools] Git merge. Select branch: (current: ".s:thisBranch.")" ]
    let l:callback = "gitTools#merge#LocalBranchName"

    call gitTools#menu#AddCommentLineColor("#", "b*")
    call gitTools#menu#OpenMenu(l:header, l:branchList, l:callback, l:branchDflt)
endfunction


function! gitTools#merge#LocalBranchName(branch)
    if a:branch == ""
        call gitTools#tools#Error("[gitTools.vim] No branch selected")
        return
    endif

    let s:lastLocalMergeBranch = a:branch
    let g:gitTools_lastLocalBranch = a:branch
    let g:gitTools_lastBranch = a:branch

    let l:gitCmd  = g:gitTools_gitCmd
    let l:cmd = g:gitTools_gitCmd." merge ".s:options." ".a:branch
    redraw
    echo l:cmd
    call confirm("Merge branch: ".a:branch." to branch: ".s:thisBranch)

    redraw
    echo l:cmd
    echo " "

    let l:result = system(l:cmd)
    redraw
    "echo l:result
    new

    " Rename buffer
    let l:date = strftime("%y%m%d_%H%M")
    let l:name = "_".l:date."_gitMerge___".s:thisBranch."__merge__".a:branch

    silent! exec("0file")
    silent! exec("bd! ".l:name)
    silent! exec("file! ".l:name)

    " Add header
    let l:list = [ " [gitTools.vim] ".l:cmd ]
    let l:header = gitTools#tools#EncloseOnRectangle(l:list, "bold", "")
    silent put=l:header

    " Add git merge result content
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
        silent! call hi#config#PatternColorize("conflict:", "r*")
        silent! call hi#config#PatternColorize("Aborting", "m@*")

        let g:HiCheckPatternAvailable = 1
    endif
endfunction



"=================================================================================
" GIT MERGE remote branch
"=================================================================================

" Perform git merge, if no remote branch provided, use menu to select the " branch.
" Arg1: [remote] remote branch to merge.
" Cmd: Gitmr Gitmrs
function! gitTools#merge#RemoteBranch(options, ...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let s:options = a:options
    let s:addRemote = 0

    if a:0 >= 1
        let l:branch = a:1
        let s:addRemote = 1
        call gitTools#remote#PullFromBranch(l:branch)
    else
        call gitTools#remote#GetRemoteBranchList()

        if exists("g:gitTools_remotesList") && len(g:gitTools_remotesList) > 0
            let l:thisBranch =  gitTools#branch#Current()
            if l:thisBranch == "" | return | endif

            let l:branchDflt = ""
            if exists("s:lastRemoteMergeBranch")
                let l:branchDflt = s:lastRemoteMergeBranch
            elseif exists("g:gitTools_lastRemoteBranch")
                let l:branchDflt = g:gitTools_lastRemoteBranch
            elseif exists("g:gitTools_lastBranch")
                let l:branchDflt = g:gitTools_lastBranch
            endif

            let l:branchList = gitTools#info#GetBranches("OriginRemote")

            let l:header = [ "[gitTools] Git merge. Select remote branch: (local branch: ".l:thisBranch.")" ]
            let l:callback = "gitTools#merge#RemoteBranchName"
            call gitTools#menu#OpenMenu(l:header, l:branchList, l:callback, l:branchDflt)
            return
        else
            let l:remote = input("[gitTools.vim] Git merge. Enter remote branch: ")
            echo " "
            let s:addRemote = 1
        endif
    endif

    call gitTools#remote#MergeFromBranch(l:branch)
endfunction


" Perform git merge from selected remote branch.
" Arg1: remote branch.
function! gitTools#merge#RemoteBranchName(remote)
    redraw

    if a:remote == ""
        call gitTools#tools#Error("[gitTools.vim] No remote branch selected")
        return
    endif

    let s:lastRemoteMergeBranch = a:remote
    let g:gitTools_lastRemoteBranch = a:remote
    let g:gitTools_lastBranch = a:remote

    if matchstr(a:remote, "^".g:gitTools_origin."/*") == ""
        let l:remote = g:gitTools_origin."/".a:remote
    endif

    if s:options == "squash"
        "let l:cmd = g:gitTools_gitCmd." merge --squash origin/".a:remote
        let l:cmd = g:gitTools_gitCmd." merge --squash ".l:remote
    else
        "let l:cmd = g:gitTools_gitCmd." merge origin/".a:remote
        let l:cmd = g:gitTools_gitCmd." merge ".l:remote
    endif

    redraw
    echo l:cmd
    if confirm("Continue with the merge", "&yes\n&no", 2) != 1
        return
    endif

    redraw
    echo l:cmd
    echo "In progress..."

    " Lauch command in foreground.
    let l:output = system(l:cmd)

    let l:outputList = split(l:output, '\^@')

    if len(l:outputList) > 5
        redraw
        new
        put=l:output
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

    if s:addRemote == 1
        if s:AddRemoteToList(a:remote)
            call s:AddRemoteToFile(a:remote)
        endif
    endif

endfunction




