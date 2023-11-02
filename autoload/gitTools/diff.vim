" Script Name: gitTools/diff.vim
 "Description: 
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: jobs.vim, git.
"
"

"- functions -------------------------------------------------------------------


" Git diff file/path 
" Command: Gitd, Gitdf, Gitda, Gitdd
function! gitTools#diff#Diff(options, path)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let s:options = a:options
    let s:path = a:path

    let l:branchList =  gitTools#info#GetBranches("Local,OriginRemote")
    let l:branchList += [ "#(Use :Gitreme to edit remote branches)" ]

    "let l:branch = gitTools#info#GetCurrentBranch()
    let l:branch = gitTools#branch#Current()

    let l:header = [ "[gitTools] Git diff. Select branch: (current:".l:branch.")" ]
    let l:callback = "gitTools#diff#DiffFromBranch"

    call gitTools#menu#AddCommentLineColor("#", "b*")
    call gitTools#menu#OpenMenu(l:header, l:branchList, l:callback, l:branch)
endfunction


function! gitTools#diff#DiffFromBranch(branch)
    redraw

    if a:branch == ""
        call gitTools#tools#Error("[gitTools.vim] No remote branch selected")
        return
    endif

    let l:branchName = a:branch
    let l:branchName = substitute(l:branchName,'/','-','g')
    let l:branchName = substitute(l:branchName,'\','-','g')

    "let l:currentBranch = gitTools#info#GetCurrentBranch()
    let l:currentBranch = gitTools#branch#Current()
    if l:currentBranch == ""
        call gitTools#tools#Error("[gitTools.vim] Local branch not found")
        return
    endif

    let l:path = gitTools#tools#GetPathAsFilename(s:path)

    if l:path != ""
        let l:pathName = "_".l:path
    else
        let l:pathName = ""
    endif

    let l:date = strftime("%y%m%d_%H%M")

    if a:branch != l:currentBranch
        let l:name = "_".l:date."_"."gitDiff___".l:currentBranch."__and__".l:branchName.l:pathName.".diff"
    else
        let l:name = "_".l:date."_"."gitDiff___".l:branchName.l:pathName.".diff"
    endif

    "let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()

    "let command = g:gitTools_gitCmd." diff --unified=4 --no-prefix ".a:branch." ".s:options." ".s:path
    let command = g:gitTools_gitCmd." diff ".s:options." ".a:branch." ".s:path
    let callback = ["gitTools#diff#GitDiffCallback", l:name]

    echo l:command
    call gitTools#tools#WindowSplitMenu(4)
    call gitTools#tools#SystemCmd(command,callback,1)
    redraw
endfunction


function! gitTools#diff#GitDiffCallback(name, resfile)
    if !exists('a:resfile') || empty(glob(a:resfile)) 
        call gitTools#tools#Warn("Git diff empty")
    endif

    call gitTools#tools#WindowSplit()

    put = readfile(a:resfile)

    silent  exec("set syntax=diff")

    " Rename buffer
    silent! exec("0file")
    silent! exec("bd! ".a:name)
    silent! exec("file! ".a:name)

    normal gg
    let @/ = '^+ \|^- '

    call gitTools#tools#WindowSplitEnd()
    redraw
endfunction


" Git diff file/path with advanced options
" Arg: PATH. Path to check for changed files.
" Arg: [FLAGS]: 
"  ALL:show all files modified.
"  BO: show binaries only.
"  SB: skip binaries (default). 
"  EO: show equal files only.
"  SE: skip equal files (default). 
"  +KeepPattern: keep files matching pattern.
"  -SkipPattern: skip files matching pattern.
" Command: GitD, GitDA, GitDD.
function! gitTools#diff#DiffAdv(...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    if a:0 == 0 || join(a:000) =~# "help"
        echo "Get diff changes on the selected path."
        echo "Arguments: PATH [FLAGS]"
        echo "- FLAGS: "
        echo "   B (show binaries)."
        echo "   +keepFilePattern"
        echo "   -skipFilePattern" 
        if join(a:000) !~# "help"
            call gitTools#tools#Error("Missing arguments: PATH")
        endif
        return
    endif

    let l:equals = "skip"
    let l:path = ""

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

    if empty(glob(l:path)) 
        call gitTools#tools#Error("Path not found ".l:path)
        return
    endif

    let name = "_gitDiff___".l:path.".diff"
    echo ""

    "----------------------------------------
    " Get files modified on subversion:
    "----------------------------------------
    let l:branch = ""
    while l:branch == ""
        echo " "
        echo "[gitTools.vim] Compare with branch: "
        let l:branch = gitTools#info#ChooseBranchMenu("Remote")
    endwhile
    redraw

    echo "Getting modified files on ".l:path."..."
    let l:filesList = gitTools#diff#GetModifiedFilesList(l:path, "", l:branch)

    if len(l:filesList) == 0
        call gitTools#tools#Warn("[gitTools.vim] No modifications found")
        return
    endif

    if l:filesList[0] == ""
        return
    endif

    redraw
    echo "Modified Files:"
    for l:file in l:filesList 
        echo "- ".l:file
    endfor
    echo " "
    echo "Found ".len(l:filesList)." modified files"

    "call confirm("Perform diff on this ".len(l:filesList)." files?")
    call confirm("continue?")
    redraw


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
    redraw
    echo "[gitTools.vim] Filter files on: '".l:path
    let l:filesList = gitTools#misc#FilterFilesListWithArgsList(a:000, l:filesList, l:path, "")

    echo "Files to open compare with head revision: ".len(l:filesList)
    call confirm("Perform diff on this ".len(l:filesList)." files?")


    "----------------------------------------
    " Get the git diff for all files.
    "----------------------------------------
    echo "Getting every file diff..."

    let l:gitCmd  = g:gitTools_gitCmd
    "let command  = l:gitCmd." diff --diff-cmd=diff ".join(l:filesList)
    let command  = l:gitCmd." diff ".join(l:filesList)
    let callback = ["gitTools#diff#GitDiffEnd", l:name]

    echo l:command
    call gitTools#tools#WindowSplitMenu(4)
    call gitTools#tools#SystemCmd(command,callback,1)
    redraw
    echo "[gitTools.vim] Show git changes on ".l:path." using diff. ".len(l:filesList)." files found."
endfunction


function! gitTools#diff#GetModifiedFilesList(path, branch1, branch2)
    let l:branches = ""
    if a:branch2 != ""
        if a:branch1 == ""
            "let l:branch1 = gitTools#info#GetCurrentBranch()
            let l:branch1 = gitTools#branch#Current()
            if l:branch1 == "" | return | endif
        else
            let l:branch1 = a:branch1
        endif

        if l:branch1 == ""
            call gitTools#tools#Error("[gitTools.vim] Current branch not found")
            return [""]
        endif

        if a:branch2 != l:branch1
            let l:branches = l:branch1."..".a:branch2." "
        else
            let l:branches = a:branch2." "
        endif
    endif

    let l:cmd = "git diff --name-only ".l:branches.a:path
    "echom l:cmd | call confirm("")

    let l:result = system(l:cmd)
    if l:result =~ "fatal: not a git repository"
        let l:desc   = substitute(l:result,'','','g')
        let l:desc   = substitute(l:result,'\n','','g')
        call gitTools#tools#Error("ERROR: ".l:desc)
        return []
    endif

    let l:tmp = split(l:result, "\n")
    let l:list = deepcopy(l:tmp)
    return l:tmp
endfunction


" Perform git apply of diff file.
" Arg1: git apply options.
" Arg2: [OPTIONAL] diff files paths.
" Command: Gitdapp
function! gitTools#diff#Apply(options, ...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    if a:options =~ "reverse"
        let l:msg = "Reverse patch from branch: "
    else
        let l:msg = "Apply patch to branch: "
    endif

    if a:0 >= 1
        " Use hash values passed as parameters.
        let l:files = join(a:000)

        if l:files == ""
            call gitTools#tools#Error("No patch file path provided.")
            return
        endif

        for l:file in a:000
            if !filereadable(l:file)
                call gitTools#tools#Error("File not found: ".l:file)
                return
            endif

            let l:size = getfsize(l:file)

            if l:size < 1
                call gitTools#tools#Error("File ".l:file." size error: ".l:size)
                return
            endif
        endfor

        if a:0 == 1
            let l:filename = "__".expand("%:t:r")
        else
            let l:filename = ""
        endif
    else
        let l:files = expand("%")
        let l:ext = expand("%:e")
        let l:filename = "__".expand("%:t:r")

        if l:files == ""
            call gitTools#tools#Error("Empty patch file name!")
            return
        endif

        if line("$") == 1
            call gitTools#tools#Error("Empty patch file!")
            return
        endif

        if l:ext != "diff" && l:ext != "patch"
            call gitTools#tools#Warn("ATTENTION, current file extension (".l:ext.") is not diff neither patch!")
            call confirm("Continue?")
        endif
    endif


    let l:files = substitute(l:files, '', "", "g")
    let l:files = substitute(l:files, '\n', "", "g")

    let l:optionNames = substitute(a:options, "--", "_", "g")
    let name = "_gitApply__".l:optionNames."__".l:filename.".diff"

    let command  = g:gitTools_gitCmd." apply ".a:options." ".l:files

    let l:branch = gitTools#branch#Current()
    echo l:command
    if confirm(l:msg.l:branch."?", "&yes\n&no", 2) != 1 | return | endif

    let callback = ["gitTools#diff#ApplyCallback", l:name, l:command]
    call gitTools#tools#SystemCmd(l:command, l:callback, 1)
    redraw
    echo l:command." ... in progress on background (Check state with :Jobsl)"
endfunction


function! gitTools#diff#ApplyCallback(name, command, resfile)
    if !exists('a:resfile') || empty(glob(a:resfile)) 
        call gitTools#tools#Warn("Git apply empty")
        return
    endif

    silent exec "new ".a:resfile

    " Add header
    let l:textList = [ " [gitTools.vim] ".a:command ]
    let l:header = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
    silent put=l:header

    " Rename buffer
    silent! exec("0file")
    silent! exec("bd! ".a:name)
    silent! exec("file! ".a:name)

    put =  readfile(a:resfile)
    silent exec("normal ggdd")
    silent exec("normal %s///g")
    call   delete(a:resfile)

    let w:split = 1
    call gitTools#tools#WindowSplitEnd()

    " Set buffer parameters
    setl noswapfile
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    setl nonu

    redraw
endfunction


