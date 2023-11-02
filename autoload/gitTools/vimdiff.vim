" Script Name: gitTools/vimdiff.vim
 "Description: 
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: jobs.vim, git, diff
"
"

"- functions -------------------------------------------------------------------


" Vimdiff single file. 
" Arg1: file to check, if empty use current file.
" Commands: Gitvdf
function! gitTools#vimdiff#File(file)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let s:file = a:file

    if !exists("s:lastVimdiffBranch")
        let s:lastVimdiffBranch = ""
        let l:defaultBranch = gitTools#branch#Current()
    else
        let l:defaultBranch = s:lastVimdiffBranch
    endif

    let l:branchList = gitTools#info#GetBranches("Local,OriginRemote")
    let l:branchList += [ "#(Use :Gitreme to edit remote branches)" ]

    let l:header = [ "[gitTools] Git (vim) diff. Select branch:" ]
    let l:callback = "gitTools#vimdiff#FileBranch"

    call gitTools#menu#AddCommentLineColor("#", "b*")
    call gitTools#menu#OpenMenu(l:header, l:branchList, l:callback, l:defaultBranch)
endfunction


function! gitTools#vimdiff#FileBranch(branch)
    if a:branch == ""
        call gitTools#tools#Error("[gitTools.vim] No branch selected")
        return
    endif

    let s:lastVimdiffBranch = a:branch

    let l:filesList = gitTools#diff#GetModifiedFilesList(s:file, "", a:branch)
    if l:filesList == []
        redraw
        call gitTools#tools#Error("[gitTools.vim] No modifications found.")
        return
    endif
    "echom "Git status list: "l:list

    if len(l:filesList) == 0
        redraw
        call gitTools#tools#Error("[gitTools.vim] No modifications found.")
        return
    endif

    if l:filesList[0] == ""
        redraw
        call gitTools#tools#Error("[gitTools.vim] No modifications found.")
        return
    endif

    let name = fnamemodify(s:file,":t:r")
    if !index(l:filesList, s:file)
        redraw
        call gitTools#tools#Warn("[gitTools.vim] No modifications found on file ".s:file)
    endif
    echo "This may take a while ..."

    if expand("%") != s:file || winnr('$') > 1
        " Open new tab to open both vimdiff files.
        call gitTools#diffTools#VimDiffFileBranch(s:file, a:branch)
    else
        " Use current buffer as left split for vertical vimddiff.
        call gitTools#diffTools#VimDiffThisFileBranch(s:file, a:branch)
    endif
    redraw
endfunction


" Simple Vimdiff on path 
" Arg1: file to check, if empty use current file.
" Commands: Gitvd, Gitvda, Gitvdd, GitvdA.
function! gitTools#vimdiff#Path(path)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let s:path = a:path

    if !exists("s:lastVimdiffBranch")
        let s:lastVimdiffBranch = ""
        let l:defaultBranch = gitTools#branch#Current()
    else
        let l:defaultBranch = s:lastVimdiffBranch
    endif

    let l:branchList =  gitTools#info#GetBranches("Local,OriginRemote")
    let l:branchList += [ "#(Use :Gitreme to add more remote branches)" ]

    let l:header = [ "[gitTools] Git (vim) diff. Select branch:" ]
    let l:callback = "gitTools#vimdiff#PathBranch"

    call gitTools#menu#AddCommentLineColor("#", "b*")
    call gitTools#menu#OpenMenu(l:header, l:branchList, l:callback, l:defaultBranch)
endfunction


function! gitTools#vimdiff#PathBranch(branch)
    if a:branch == ""
        call gitTools#tools#Error("[gitTools.vim] No branch selected")
        return
    endif

    let s:lastVimdiffBranch = a:branch

    echo "Getting modified files on ".s:path." branch ".a:branch." ..."
    let l:list = gitTools#diff#GetModifiedFilesList(s:path, "", a:branch)

    if l:list == []
        redraw
        call gitTools#tools#Error("[gitTools.vim] No modifications found.")
        return
    endif

    let l:n = len(l:list)

    if l:n == 0
        redraw
        call gitTools#tools#Warn("[gitTools.vim] No modifications found")
        return 1
    endif

    if l:list[0] == ""
        " Error getting modified files.
        redraw
        call gitTools#tools#Warn("[gitTools.vim] No modifications found")
        return 1
    endif

    if l:n == 1
        " Open vimdiff without asking user
        echo "This may take a while ..."
        call gitTools#diffTools#VimDiffFileBranch(l:list[0],a:branch)
        redraw
        return
    else
        " Show the final list with the files to open with vimdiff.
        redraw
        echo "Modified Files:"
        for file in l:list 
            echo "- ".l:file
        endfor
        echo ""

        if l:n > 10
            if confirm("Found ".l:n." modifications. Show all with vimdiff?", "&yes\n&no", 2) != 1
                return
            endif
        endif

        echo " "
        echo "This may take a while ..."
        echo ""

        " Perform git diff on each selected file.
        " Open each file with vimdiff on new tab
        let l:n = 0
        for l:file in l:list 
            echo "- ".l:file
            call gitTools#diffTools#VimDiffFileBranch(l:file, a:branch)
            let l:n += 1
        endfor

        redraw
        echo " "
        echo "[gitTools.vim] Show git changes on ".s:path." using vimdiff. ".l:n." files."
    endif
endfunction


" Vimdiff path with advanced options 
" Arg: PATH. Path to check for changed files.
" Arg: [FLAGS]: 
"  ALL:show all files modified.
"  BO: show binaries only.
"  SB: skip binaries (default). 
"  EO: show equal files only.
"  SE: skip equal files (default). 
"  +KeepPattern: keep files matching pattern.
"  -SkipPattern: skip files matching pattern.
" Commands: GitVD, GitVDA, GitVDD.
function! gitTools#vimdiff#PathAdv(...)
    if gitTools#tools#isGitAvailable() == 0
        call gitTools#tools#Error("No git repository found on path ".getcwd())
        return
    endif

    if a:0 == 0 || join(a:000) =~# "help"
        echo "Get vimdiff changes on the selected path."
        echo "Arguments: PATH [FLAGS]"
        echo "- FLAGS: "
        echo "   B  (show binaries)."
        echo "   +keepFilePattern"
        echo "   -skipFilePattern" 
        if join(a:000) !~# "help"
            call gitTools#tools#Error("Missing arguments: PATH")
        endif
        return
    endif

    let l:path = ""
    let l:equals = "skip"

    for l:arg in a:000
        if l:arg ==? "BO" || l:arg ==? "SB" || l:arg[0] == '+' || l:arg[0] == '-'
            " Arguments meant for: gitTools#misc#FilterFilesListWithArgsList
        elseif l:arg ==? "ALL"
            let l:equals = ""
        elseif l:arg ==? "EO"
            let l:equals = "only"
        elseif l:arg ==? "SE"
            let l:equals = "skip"
        elseif !empty(glob(l:arg))
            let l:path .= l:arg." "
            let l:path = substitute(l:path,'^\s\+','','g')
            let l:path = substitute(l:path,'\s\+$','','g')
        else
            call gitTools#tools#Warn("Unknown argument: ".l:arg)
            call confirm("Continue?")
        endif
    endfor

    if empty(glob(l:path) )
        call gitTools#tools#Error("Path not found ".l:path)
        return
    endif

    "----------------------------------------
    " Get files modified:
    "----------------------------------------
    let l:branch = ""
    while l:branch == ""
        echo " "
        echo "[gitTools.vim] Compare with branch: "
        let l:branch = gitTools#info#ChooseBranchMenu("Remote")
        if l:branch == "" | return | endif
    endwhile
    redraw

    echo "Getting modified files on ".l:path."..."
    let l:filesList = gitTools#diff#GetModifiedFilesList(l:path, "", l:branch)
    if l:filesList == [] | return | endif

    if len(l:filesList) == 0
        redraw
        call gitTools#tools#Warn("[gitTools.vim] No modifications found")
        return []
    endif

    if l:filesList[0] == ""
        " Error getting modified files.
        return []
    endif

    echo "Modified Files:"
    for l:file in l:filesList 
        echo "- ".l:file
    endfor
    echo " "
    if len(l:filesList) == 0
        call gitTools#tools#Warn("No files found.")
        return
    endif
    echo "Found ".len(l:filesList)." modified files"
    call confirm("continue?")

    "----------------------------------------
    " Filter files:
    " Filter acording to flags on arguments list, keep/skip binaries/equal-files/match-patterns.
    " Flags:
    "  ALL:show all files modified.
    "  BO: show binaries only.
    "  SB: skip binaries (default). 
    "  EO: show equal files only.
    "  SE: skip equal files (default). 
    "  +KeepPattern: keep files matching pattern.
    "  -SkipPattern: skip files matching pattern.
    "----------------------------------------
    "redraw
    echo "[gitTools.vim] Filter files on: '".l:path
    let l:filesList = gitTools#misc#FilterFilesListWithArgsList(a:000, l:filesList, l:path, "")

    echo "Files to open compare with head revision: ".len(l:filesList)
    call confirm("Perform vimdiff on this ".len(l:filesList)." files?")


    "----------------------------------------
    " Get the subversion file and perform vimdiff with current one.
    "----------------------------------------
    echo " "
    echo "Getting every file vimdiff..."
    let l:n = 0
    for l:file in l:filesList 
        echo "- ".l:file." vimdiff"
        call gitTools#diffTools#VimDiffFileBranch(l:file,l:branch)
        let l:n += 1
    endfor

    "redraw
    echo " "
    echom "[gitTools.vim] Show git changes on ".l:path." using vimdiff. ".l:n." files found."
endfunction



