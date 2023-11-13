" Script Name: gitTools/remote.vim
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


" Edit saved remotes file. Stands for git remote edit.
" Cmd: Gitreme
function! gitTools#remote#Edit()
    call gitTools#tools#WindowSplitType(1)

    silent exec "edit ".g:gitTools_remoteBranchFile

    silent! unlet g:gitTools_remotesList
endfunction


"=================================================================================
" GIT PUSH
"=================================================================================

" Perform git push, open menu to select the branch if no remote branch " provided.
" Arg1: options, use "delete" to remove the branch.
" Arg2: [remote] remote branch to perform push.
" Cmd: Gitpush
function! gitTools#remote#Push(options, ...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let s:options = a:options

    if a:0 >= 1
        let l:remote = a:1
        let s:addRemote = 1
    else
        let l:thisBranch =  gitTools#branch#Current()
        if l:thisBranch == "" | return | endif

        call s:LoadRemotesFromFile()
        let s:addRemote = 0

        if exists("g:gitTools_remotesList") && len(g:gitTools_remotesList) > 0
            let l:branchDflt = ""
            if exists("s:lastGitPushBranch")
                let l:branchDflt = s:lastGitPushBranch
            elseif exists("g:gitTools_lastRemoteBranch")
                let l:branchDflt = g:gitTools_lastRemoteBranch
            elseif exists("g:gitTools_lastBranch")
                let l:branchDflt = g:gitTools_lastBranch
            endif

            let l:branchList = gitTools#info#GetBranches("Remote")
            let l:branchList += [ "#(Use :Gitreme to edit remote branches)" ]

            if s:options == "delete"
                let l:header = [ "[gitTools] Git push delete. Select remote branch: (local branch: ".l:thisBranch.")" ]
                call gitTools#menu#SetHeaderColor("o@")
            else
                let l:header = [ "[gitTools] Git push. Select remote branch: (local branch: ".l:thisBranch.")" ]
            endif
            let l:callback = "gitTools#remote#PushToBranch"

            call gitTools#menu#AddCommentLineColor("#", "b*")
            call gitTools#menu#OpenMenu(l:header, l:branchList, l:callback, l:branchDflt)
            return
        else
            let l:remote = input("[gitTools.vim] Git push enter remote branch: ")
            echo " "
            let s:addRemote = 1
        endif
    endif

    call gitTools#remote#PushToBranch(l:remote)
endfunction


" Perform git push on selected remote branch.
" Arg1: remote branch.
function! gitTools#remote#PushToBranch(remote)
    redraw

    if a:remote == ""
        call gitTools#tools#Error("[gitTools.vim] Git push failed. No remote branch.")
        return
    endif

    let s:lastBranch = a:remote
    let s:lastGitPushBranch = a:remote
    let g:gitTools_lastRemoteBranch = a:remote
    let g:gitTools_lastBranch = a:remote

    "let l:branch = gitTools#info#GetCurrentBranch()
    let l:branch = gitTools#branch#Current()
    if l:branch == "" | return | endif

    if s:options == "delete"
        let l:cmd = g:gitTools_gitCmd." push --delete ".g:gitTools_origin." ".a:remote
    else
        let l:cmd = g:gitTools_gitCmd." push ".g:gitTools_origin." ".l:branch.":".a:remote
    endif

    if s:options == "delete"
        echo a:remote
        call confirm("ATTENTION: Remote branch will be DELETED!")

        let l:text = "DELETE remote: ".a:remote
    else
        let l:text = "Push changes to remote: ".a:remote
    endif

    echo l:cmd
    if confirm(l:text, "&yes\n&no", 2) != 1
        return
    endif

    if exists('g:VimJobsLoaded')
        " Lauch command on background with Jobs.vim plugin.
        let l:callback = [ "gitTools#remote#PushCallback", l:cmd, a:remote, s:addRemote, s:options ]
        call gitTools#tools#SystemCmd(l:cmd, l:callback, 1)
        redraw
        echo l:cmd." ... in progress on background (Check state with :Jobsl)"
    else
        " Lauch command in foreground.
        redraw
        echo l:cmd
        echo "In progress..."

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
                call gitTools#tools#Error("[gitTools.vim] Git push failed")
                return
            endif

            echo "Done"
            call confirm("")
        endif

        if l:addRemote == 1
            if s:AddRemoteToList(a:remote)
                call s:AddRemoteToFile(a:remote)
            endif
        endif

        if s:options == "delete"
            echo " "
            echo a:remote

            if confirm("Delete remote from list?", "&yes\n&no", 2) == 1
                call s:RemoveRemoteFromList(a:remote)
                call s:RemoveRemoteFromFile(a:remote)
            endif
        endif
    endif
endfunction


" Recover result of git push command launched on background with Jobs.vim plugin.
function! gitTools#remote#PushCallback(cmd, remote, addRemote, options, output)
    if !exists('a:output')
        call gitTools#tools#Warn("Git result not found. ".a:cmd)
    endif

    if empty(glob(a:output)) 
        call gitTools#tools#Warn("Git result empty. ".a:cmd)
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
    let l:date = strftime("%y%m%d_%H%M")
    "let l:local = gitTools#info#GetCurrentBranch()
    let l:local = gitTools#branch#Current()
    let l:local = substitute(l:local, '/', '-', 'g')
    let l:remote = substitute(a:remote, '/', '-', 'g')
    let l:filename = "_".l:date."_gitPush___".l:local."_to_".a:remote

    silent exec("0file")
    silent! exec("file ".l:filename)

    " Resize window
    let l:lastRow = line("$")
    if l:lastRow < winheight(0)
        silent exec("resize ".l:lastRow)
    endif

    if a:addRemote == 1
        if s:AddRemoteToList(a:remote)
            call s:AddRemoteToFile(a:remote)
        endif
    endif

    if a:options == "delete"
        echo " "
        echo a:remote

        if confirm("Delete remote from list?", "&yes\n&no", 2) == 1
            call s:RemoveRemoteFromList(a:remote)
            call s:RemoveRemoteFromFile(a:remote)
        endif
    endif
endfunction


"=================================================================================
" GIT PULL
"=================================================================================


" Perform git pull, if no remote branch provided, use menu to select the " branch.
" Arg1: [remote] remote branch to perform push.
" Cmd: Gitpull
function! gitTools#remote#Pull(...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let s:addRemote = 0

    if a:0 >= 1
        let l:remote = a:1
        let s:addRemote = 1
    else
        call s:LoadRemotesFromFile()

        if exists("g:gitTools_remotesList") && len(g:gitTools_remotesList) > 0
            let l:thisBranch =  gitTools#branch#Current()
            if l:thisBranch == "" | return | endif

            let l:branchDflt = ""
            if exists("s:lastGitPullBranch")
                let l:branchDflt = s:lastGitPullBranch
            elseif exists("g:gitTools_lastRemoteBranch")
                let l:branchDflt = g:gitTools_lastRemoteBranch
            elseif exists("g:gitTools_lastBranch")
                let l:branchDflt = g:gitTools_lastBranch
            endif

            let l:branchList = gitTools#info#GetBranches("Remote")
            let l:branchList += [ "#(Use :Gitreme to edit remote branches)" ]

            let l:header = [ "[gitTools] Git pull. Select remote branch: (local branch: ".l:thisBranch.")" ]
            let l:callback = "gitTools#remote#PullFromBranch"

            call gitTools#menu#AddCommentLineColor("#", "b*")
            call gitTools#menu#OpenMenu(l:header, l:branchList, l:callback, l:branchDflt)
            return
        else
            let l:remote = input("[gitTools.vim] Git pull enter remote branch: ")
            echo " "
            let s:addRemote = 1
        endif
    endif

    call gitTools#remote#PullFromBranch(l:remote)
endfunction

" Perform git pull from selected remote branch.
" Arg1: remote branch.
function! gitTools#remote#PullFromBranch(branch)
    redraw

    if a:branch == ""
        call gitTools#tools#Error("[gitTools.vim] No remote branch selected")
        return
    endif

    let s:lastGitPullBranch = a:branch
    let g:gitTools_lastRemoteBranch = a:branch
    let g:gitTools_lastBranch = a:branch

    "let l:thisBranch = gitTools#info#GetCurrentBranch()
    let l:thisBranch = gitTools#branch#Current()
    let l:thisBranch = gitTools#branch#Current()
    if l:thisBranch == "" | return | endif

    if a:branch == l:thisBranch
        call gitTools#tools#Error("[gitTools.vim] incorrect Git pull from ".a:branch)
        return
    endif

    "let l:cmd = g:gitTools_gitCmd." pull ".a:branch." ".l:thisBranch
    let l:cmd = g:gitTools_gitCmd." pull ".g:gitTools_origin." ".a:branch
    echo l:cmd

    if confirm("Perform git pull from branch: ".a:branch." to ".l:thisBranch, "&yes\n&no", 2) != 1
        return
    endif

    if exists('g:VimJobsLoaded')
        " Lauch command on background with Jobs.vim plugin.
        let l:callback = [ "gitTools#remote#PullCallback", l:cmd, a:branch ]
        call gitTools#tools#SystemCmd(l:cmd, l:callback, 1)
        redraw
        echo l:cmd." ... in progress on background (Check state with :Jobsl)"
    else
        " Lauch command in foreground.
        redraw
        echo l:cmd
        echo "In progress..."

        let l:output = system(l:cmd)

        let l:outputList = split(l:output, '\^@')

        if len(l:outputList) > 5
            redraw
            "new
            tabnew
            put=l:output
        else
            echo l:cmd
            echo " "

            for l:line in l:outputList
                echo l:line
            endfor

            if l:output =~ "error" 
                call gitTools#tools#Error("[gitTools.vim] Git pull failed")
                return
            endif

            echo "Done"
            call confirm("")
            call s:GitPullColorHighlighting()
            call s:PullSearchPatterns()
        endif
    endif
endfunction


" Recover result of command launched on background with Jobs.vim plugin.
function! gitTools#remote#PullCallback(cmd, branch, output)
    if empty(glob(a:output)) 
        call gitTools#tools#Warn("Git result empty. ".a:cmd)
    endif

    " Open result file
    silent exec "tabnew ".a:output

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
    let l:date = strftime("%y%m%d_%H%M")
    "let l:local = gitTools#info#GetCurrentBranch()
    let l:local = gitTools#branch#Current()
    let l:local = substitute(l:local, '/', '-', 'g')
    let l:remote = substitute(a:branch, '/', '-', 'g')
    let l:filename = "_".l:date."_gitPull__".l:remote."_to_".l:local

    silent exec("0file")
    silent! exec("file ".l:filename)

    " Apply text color highlighting
    call s:GitPullColorHighlighting()
    call s:PullSearchPatterns()

    " Check number of conflicts
    normal gg
    let l:n = 0
    " search(pattern, W:do not wrap to the start, 0:end line not set, 2000:2sec timeout).
    while search("CONFLICT", 'W', 0, 2000) != 0
        let l:n += 1
    endwhile
    normal gg

    if l:n != 0
        call gitTools#tools#Warn("ATTENTTION: ".l:n." merge conflict found! Use :Gitm to solve the conflicts.")
    endif
endfunction


function! s:GitPullColorHighlighting()
    if exists('g:HiLoaded')
        let g:HiCheckPatternAvailable = 0

        silent! call hi#config#PatternColorize("^Adding", "g3")
        silent! call hi#config#PatternColorize("^Removing", "r3")
        silent! call hi#config#PatternColorize("^Auto-merging", "b3")
        silent! call hi#config#PatternColorize("CONFLICT" , "m@*")
        silent! call hi#config#PatternColorize("fatal:" , "r@*")

        silent! call hi#config#PatternColorize(" +", "g")
        silent! call hi#config#PatternColorize("+$", "g")
        silent! call hi#config#PatternColorize("++", "g")
        silent! call hi#config#PatternColorize("--", "r")
        silent! call hi#config#PatternColorize(" -", "r")
        silent! call hi#config#PatternColorize("-$", "r")
        silent! call hi#config#PatternColorize("files changed", "w*")

        silent! call hi#config#PatternColorize("Automatic merge failed" , "r@*")

        let g:HiCheckPatternAvailable = 1
    endif
endfunction


function! s:PullSearchPatterns()
    let l:patterns = "\cmerge\\|\cconflict"
    silent execute "normal! gg"
    silent! call search(l:patterns, 'W', 0, 500)
    let @/ = l:patterns

    redraw
    call gitTools#tools#Attention("INFO: use forward/backward search to move between blocks")
endfunction


"=================================================================================
" ORIGIN
"=================================================================================

" Change remote origin.
" Arg1: options, use "-v" to show URLs.
" Arg2: [remote] choose the remote name.
" Cmd: Gitro
function! gitTools#remote#Origin(options, ...)
    let l:remote = ""

    let remotesStr = system("git remote ".a:options) 
    let remotesList = split(l:remotesStr, "\n")

    if a:0 >= 1
        let l:remote = a:1
    endif

    if l:remote != ""
        if l:remotesStr !~ l:remote
            call gitTools#tools#Error("[gitTools.vim] Unknown remote: ".l:remote)
            return
        endif
        call gitTools#remote#OriginName(l:remote)
    else
        let l:header = [ "[gitTools] Change remote to: (current: ".g:gitTools_origin.")" ]
        let l:callback ="gitTools#remote#OriginName"
        call gitTools#menu#OpenMenu(l:header, l:remotesList, l:callback, g:gitTools_origin)
    endif
endfunction


function! gitTools#remote#OriginName(name)
    let l:nameLine = split(a:name)
    let l:name = l:nameLine[0]

    if g:gitTools_origin != l:name
        let g:gitTools_origin = l:name
        echo "[gitTools] Change default remote to: ".g:gitTools_origin
    else
        echo "[gitTools] Default remote: ".g:gitTools_origin
    endif
endfunction



"=================================================================================
" COMMON
"=================================================================================

" Get saved remote branches
function! gitTools#remote#GetRemoteBranchList()
    if !exists("g:gitTools_remotesList")
        call s:LoadRemotesFromFile()
    endif
    if !exists("g:gitTools_remotesList")
        return []
    endif
    return g:gitTools_remotesList
endfunction


function! s:LoadRemotesFromFile()
    if empty(glob(g:gitTools_remoteBranchFile))
        return 0
    endif

    redir! > readfile.out

    " Parse the remotes file
    let l:file = readfile(g:gitTools_remoteBranchFile)

    for l:line in l:file
        if l:line != ""
            call s:AddRemoteToList(l:line)
        endif
    endfor

    redir END
    return 1
endfunction


function! s:AddRemoteToFile(remote)
    silent new
    setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
    put=a:remote
    silent execute 'w! >>' g:gitTools_remoteBranchFile
    silent quit
endfunction


function! s:RemoveRemoteFromFile(remote)
    if empty(glob(g:gitTools_remoteBranchFile))
        return
    endif
    silent exec "new ".g:gitTools_remoteBranchFile
    silent exec "normal :g/".a:remote."/d"
    silent quit
endfunction


function! s:ChooseRemoteFromMenu()
    if !exists("g:gitTools_remotesList") || len(g:gitTools_remotesList) == 0
        call gitTools#tools#Error("[gitTools.vim] Remote list empty.")
        return ""
    endif

    if  len(g:gitTools_remotesList) == 1
        return g:gitTools_remotesList[0]
    endif

    while 1
        echo "[gitTools.vim] Saved remote branches: "

        let l:i = 1
        for l:branch in g:gitTools_remotesList
            echo " ".l:i.")  ".l:branch
            let l:i += 1
        endfor

        let l:str = input("Choose remote: ")

        if l:str == ""
            redraw
            return ""
        endif

        let l:n = str2nr(l:str)
        "echo " "
        "echom l:n

        if l:n > 0 && l:n <= len(g:gitTools_remotesList)
            "echom g:gitTools_remotesList[l:n-1]
            redraw
            return g:gitTools_remotesList[l:n-1]
        endif

        echo " "
    endwhile
endfunction


function! s:AddRemoteToList(remote)
    if exists("g:gitTools_remotesList")
        if index(g:gitTools_remotesList, a:remote) < 0
            let g:gitTools_remotesList += [ a:remote ]
        else
            "call gitTools#tools#Error("[gitTools.vim] Remote was saved from previous use.")
            return 0
        endif
    else
        let g:gitTools_remotesList = [ a:remote ]
    endif
    return 1
endfunction


function! s:RemoveRemoteFromList(remote)
    let l:i = index(g:gitTools_remotesList, a:remote)
    if l:i != 0
        call remove(g:gitTools_remotesList, l:i, l:i)
    endif
endfunction


" Show origin on remote branches
" Cmd: Gitrso
" Arg1: [filter1 filter2], space separated patterns to match with grep.
function! gitTools#remote#ShowOrigin(filters)
    if a:filters == ""
        let l:filters = input("Filter by pattern: ")
    else
        let l:filters = a:filters
    endif

    if l:filters == ""
        let l:cmd = g:gitTools_gitCmd." remote show origin"
    else
        "let l:cmd = g:gitTools_gitCmd." branch -r \| grep "
        let l:cmd = g:gitTools_gitCmd." remote show origin \| grep "
        for l:filt in split(l:filters)
            let l:cmd .= " -e '".l:filt."'"
        endfor
    endif

    if l:filters == ""
        call confirm("Show all remote origin branches?")
    endif

    echo l:cmd
    call gitTools#tools#WindowSplitMenu(1)

    " Lauch command on background with Jobs.vim plugin.
    let l:callback = [ "gitTools#remote#ShowRemoteOriginCallback", l:cmd, l:filters ]
    call gitTools#tools#SystemCmd(l:cmd, l:callback, 1)
endfunction


function! gitTools#remote#ShowRemoteOriginCallback(cmd, filters, output)
    if !exists('a:output')
        call gitTools#tools#Warn("Git result not found. ".a:cmd)
    endif

    if empty(glob(a:output)) 
        call gitTools#tools#Warn("Git result empty. ".a:cmd)
    endif

    let fileList = readfile(a:output)

    if l:fileList[0]  =~ "fatal: not a git repository"
        redraw
        call gitTools#tools#Error("ERROR: not a git repository")
        return
    endif

    redraw
    call gitTools#tools#WindowSplit()

    " Open result file
    silent exec "edit ".a:output

    "echom "Lines1: '".getline(".")."' Lines:".line("$")
    if getline(".") == "" && line("$") == 1
        quit
        redraw
        call gitTools#tools#Warn("Not found")
        return
    endif

    redraw
    echo "[gitTools.vim] Found ".line("$")." remotes branches"

    " Rename buffer
    let l:date = strftime("%y%m%d_%H%M")
    if a:filters == ""
        let l:name = "_".l:date."_gitRemoteOrigin"
    else
        let l:filters = substitute(a:filters, " ", "-", "g")
        let l:name = "_".l:date."_gitBranchR___matches_".l:filters
    endif

    silent! exec("0file")
    silent! exec("bd! ".l:name)
    silent! exec("file! ".l:name)

    " Add header
    let l:list = [ " [gitTools.vim] ".a:cmd." " ]
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

    if exists('g:HiLoaded')
        let g:HiCheckPatternAvailable = 0

        silent! call hi#config#PatternColorize(" tracked", "b*")
        silent! call hi#config#PatternColorize(" new", "g*")
        silent! call hi#config#PatternColorize(" stale", "r*")

        let g:HiCheckPatternAvailable = 1
    endif

    if a:filters != ""
        let l:filters = substitute(a:filters, " ", '\\\|', "g")
        " Search filter
        silent! call search(l:filters, 'W', 0, 500)
        " Set search history
        let @/ = l:filters
    endif

    call gitTools#tools#WindowSplitEnd()
endfunction


" Show remote branches
" Cmd: Gitrb
" Arg1: [filter1 filter2], space separated patterns to match with grep.
function! gitTools#remote#GetBranches(filters)
    if a:filters == ""
        let l:filters = input("Filter by patterns: ")
    else
        let l:filters = a:filters
    endif

    if l:filters == ""
        let l:cmd = g:gitTools_gitCmd." branch -r"
    else
        let l:cmd = g:gitTools_gitCmd." branch -r \| grep "
        for l:filt in split(l:filters)
            let l:cmd .= " -e '".l:filt."'"
        endfor
    endif

    redraw
    echo l:cmd

    if l:filters == ""
        call confirm("Show all remote branches?")
    endif

    call gitTools#tools#WindowSplitMenu(1)

    " Lauch command on background with Jobs.vim plugin.
    let l:callback = [ "gitTools#remote#GetBranchCallback", l:cmd, l:filters ]
    call gitTools#tools#SystemCmd(l:cmd, l:callback, 1)
endfunction


function! gitTools#remote#GetBranchCallback(cmd, filters, output)
    if !exists('a:output')
        redraw
        call gitTools#tools#Warn("[gitTools.vim] Git result not found. ".a:cmd)
    endif

    if empty(glob(a:output)) 
        redraw
        call gitTools#tools#Warn("[gitTools.vim] Git result empty. ".a:cmd)
    endif

    let fileList = readfile(a:output)

    if len(l:fileList) >= 1
        if l:fileList[0]  =~ "fatal: not a git repository"
            redraw
            call gitTools#tools#Error("[gitTools.vim] ERROR: not a git repository")
            return
        endif
    endif

    redraw
    call gitTools#tools#WindowSplit()
    call gitTools#tools#WindowSplitEnd()

    " Open result file
    silent exec "edit ".a:output

    "echom "Lines1: '".getline(".")."' Lines:".line("$")
    if getline(".") == "" && line("$") == 1
        quit
        redraw
        call gitTools#tools#Warn("[gitTools.vim] No result found (".a:cmd.")")
        return
    endif

    redraw
    echo "[gitTools.vim] Found ".line("$")." remotes branches"

    " Rename buffer
    let l:date = strftime("%y%m%d_%H%M")
    if a:filters == ""
        let l:name = "_".l:date."_gitBranchR"
    else
        let l:filters = substitute(a:filters, " ", "-", "g")
        let l:name = "_".l:date."_gitBranchR___matches_".l:filters
    endif

    silent! exec("0file")
    silent! exec("bd! ".l:name)
    silent! exec("file! ".l:name)

    " Add header
    let l:list = [ " [gitTools.vim] ".a:cmd." " ]
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

    if a:filters != ""
        let l:filters = substitute(a:filters, " ", '\\\|', "g")
        " Search filter
        silent! call search(l:filters, 'W', 0, 500)
        " Set search history
        let @/ = l:filters
    endif
endfunction



" Perform git ls-remote 
" Arg1: [remote], remote name, if empty open a menu to select the remote.
" Cmd: Gitrls
function! gitTools#remote#LsBranches(remote)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    if a:remote == ""
        let remotesStr = system("git remote") 
        let remotesList = split(l:remotesStr, "\n")

        if len(l:remotesList) > 1
            " Open menu window to choose the remote.
            let l:callback = "gitTools#remote#LsBranchesWithRemote"
            let l:header = [ "[gitTools] Git remote ls. Select remote branch: (press enter to skip) " ]

            call gitTools#menu#AddCommentLineColor("#", "b*")
            call gitTools#menu#OpenMenu(l:header, l:remotesList, l:callback, "")
            return
        else
            " Only one remote found. Show remote branches.
            call gitTools#remote#LsBranchesWithRemote(l:remotesList[0])
        endif
    else
        " Show remote branches.
        call gitTools#remote#LsBranchesWithRemote(a:remote)
    endif
endfunction


function! gitTools#remote#LsBranchesWithRemote(remote)
    let l:cmd = g:gitTools_gitCmd." ls-remote ".a:remote
    echo l:cmd
    call gitTools#tools#WindowSplitMenu(1)

    " Lauch command on background with Jobs.vim plugin.
    let l:callback = [ "gitTools#remote#LsBranchesResult", l:cmd, a:remote ]
    call gitTools#tools#SystemCmd(l:cmd, l:callback, 1)
endfunction


function! gitTools#remote#LsBranchesResult(cmd, remote, output)
    if !exists('a:output')
        redraw
        call gitTools#tools#Warn("[gitTools.vim] Git result not found. ".a:cmd)
    endif

    if empty(glob(a:output)) 
        redraw
        call gitTools#tools#Warn("[gitTools.vim] Git result empty. ".a:cmd)
    endif

    let fileList = readfile(a:output)

    if len(l:fileList) >= 1
        if l:fileList[0]  =~ "fatal: not a git repository"
            redraw
            call gitTools#tools#Error("[gitTools.vim] ERROR: not a git repository")
            return
        endif
    endif

    redraw
    call gitTools#tools#WindowSplit()
    call gitTools#tools#WindowSplitEnd()

    " Open result file
    silent exec "edit ".a:output

    "echom "Lines1: '".getline(".")."' Lines:".line("$")
    if getline(".") == "" && line("$") == 1
        quit
        redraw
        call gitTools#tools#Warn("[gitTools.vim] No result found (".a:cmd.")")
        return
    endif

    redraw
    echo "[gitTools.vim] Found ".line("$")." remotes branches"

    " Rename buffer
    let l:date = strftime("%y%m%d_%H%M")
    let l:name = "_".l:date."_gitBranchLsRemote_".a:remote

    silent! exec("0file")
    silent! exec("bd! ".l:name)
    silent! exec("file! ".l:name)

    " Add header
    let l:list = [ " [gitTools.vim] ".a:cmd." " ]
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

