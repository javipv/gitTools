" Script Name: gitTools.vim
 "Description: git commit helper functions.
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: git
"
" NOTES:
"

"- functions -------------------------------------------------------------------

" git commit.
" Arg1: arg [optional]
"  When arg is empty, open the default commit description file or create if
"  doesn't exist. After editing the file :Gitcm should be launched again
"  (without arguments) to perform the commit.
"  When arg is filepath, use the content on the file as commit description.
"  When arg is not a filepath, use the it as commit argument.
" Cmd: Gitcm, Gitcma, GitcmAm, GitcmAll
function! gitTools#commit#Commit(options, arg)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    if a:arg == "%"
        let l:arg = expand("%")
    else
        let l:arg = a:arg
    endif

    if a:options =~ "--amend"
        call confirm("ATTENTION. Amend previous commit.")
    elseif a:options =~ "-"
        call confirm("ATTENTION. Committing all changes, staging area doesn't apply")
    endif

    if l:arg != ""
        let l:arg = gitTools#tools#TrimString(l:arg)
        if filereadable(l:arg)
            call s:CommitDescriptionFile(l:arg, a:options)
        else
            call s:CommitDescription(l:arg, a:options)
        endif
    else
        if expand("%") == g:gitTools_commitDescriptionDefaultFile
            call s:CommitDescriptionFile(g:gitTools_commitDescriptionDefaultFile, a:options)
        else
            echo "Opening default commit description file: ".g:gitTools_commitDescriptionDefaultFile
            call s:EditDescriptionFile()
        endif
    endif
endfunction


" Edit the default commit description file.
function! s:EditDescriptionFile()
    if filereadable(g:gitTools_commitDescriptionDefaultFile)
        call gitTools#tools#Warn("Attention! Previous commit description file found.")

        if confirm("Remove current description file and generate it again?", "&yes\n&no", 2) == 1
            call delete(g:gitTools_commitDescriptionDefaultFile)
        endif
    endif

    call gitTools#tools#WindowSplitMenu(3)
    let s:split = w:split
    call gitTools#tools#WindowSplit()

    if !filereadable(g:gitTools_commitDescriptionDefaultFile)
        " Create the git commit file.
        " Get the git branch and git status:
        silent exec("edit ".g:gitTools_commitDescriptionDefaultFile)
        silent exec("r! ".g:gitTools_commitDryRunCmd)
        " Comment all lines
        %s/^/# /g
        normal ggO

        " Add header
        let l:textList = []
        let l:textList += [ " [gitTools.vim]" ]
        let l:textList += [ "  Use :Gitcm again to commit with current description.  " ]
        let l:text = gitTools#tools#EncloseOnRectangle(l:textList, "hashtag", "")
        normal ggO
        put=l:text
        normal ggdd
    else
        " Commit file already exist, open it for edit:
        silent exec("edit ".g:gitTools_commitDescriptionDefaultFile)
    endif

    set ft=gitcommit
    call gitTools#tools#WindowSplitEnd()

    normal 4j

    " Ask user whether to show staged changes diff file.
    if confirm("Open git diff staged?", "&yes\n&no", 1) == 1
        "let l:branch = gitTools#info#GetCurrentBranch()
        let l:branch = gitTools#branch#Current()
        call gitTools#commit#StagedChangesDiffBranch(l:branch)
        
        " Select branch:
        "echo "Getting available branches..."
        "let l:branchList =  gitTools#info#GetBranches("")
        "let l:branch = gitTools#info#GetCurrentBranch()

        "let l:header = "[gitTools] Git diff. Select branch: (current:".l:branch.")"
        "let l:callback = "gitTools#commit#StagedChangesDiffBranch"
        "let s:split = l:split
        "call gitTools#menu#OpenMenu(l:header, l:branchList, l:callback, l:branch)
    endif
endfunction


" Perform git diff for staged changes
function! gitTools#commit#StagedChangesDiffBranch(branch)
    if a:branch == "" | return | endif

    let l:branch = substitute(a:branch,'/','-','g')
    let l:branch = substitute(l:branch,'\','-','g')

    let command  = g:gitTools_gitCmd." diff --unified=4 --no-prefix ".l:branch." --staged ".getcwd()

    " Rename buffer
    "let l:branch0 = gitTools#info#GetCurrentBranch()
    let l:branch0 = gitTools#branch#Current()
    let l:branch0 = substitute(l:branch0,'/','-','g')
    let l:branch0 = substitute(l:branch0,'\','-','g')

    let l:date = strftime("%y%m%d_%H%M")

    if l:branch == l:branch0
        let name = "_".l:date."_gitDiff___staged__".l:branch.".diff"
    else
        let name = "_".l:date."_gitDiff___staged__".l:branch0."__and__".l:branch.".diff"
    endif

    "call gitTools#tools#WindowSplitMenu(2)

    " Force new window on either vertical or horizontal split.
    if s:split == 3 " New tab
        let w:split = 2 " Vertical split
    else
        let w:split = 1 " Horizontal split
    endif
    let w:winSize = winheight(0)

    let callback = ["gitTools#commit#StagedChangesDiffBranchCallback", l:name, s:split, l:command]
    echo l:command." in progress on background (Use :Jobsl to check status)"
    silent call gitTools#tools#SystemCmd(l:command, l:callback, 1)
endfunction


" Git diff staged changes callback, process results
function! gitTools#commit#StagedChangesDiffBranchCallback(name, split, command, resfile)
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

    " Add header
    let l:textList = []
    let l:textList += [ " [gitTools.vim] Diff staged " ]
    let l:textList += [ " ".a:command." " ]
    let l:text = gitTools#tools#EncloseOnRectangle(l:textList, "hashtag", "")
    normal ggO
    put=l:text
    normal ggdd

    set ft=diff

    "call gitTools#tools#WindowSplitEnd()

    " Move cursor to commit description window:
    if a:split == 1 " Horizontal split, or same window
        silent! wincmd k
        "silent! wincmd h
        silent! wincmd =
    else " Vertical split, or new tab
        silent! wincmd h
        "silent! wincmd k
    endif
endfunction


" Perform git commit, get description from the provided file path.
" Arg1: descFile, file path containing the commit description to be used.
function! s:CommitDescriptionFile(descFile, options)
    if !filereadable(a:descFile)
        if expand("%") != a:descFile
            call gitTools#tools#Error("ERROR: commit description file not found ".a:descFile)
        else
            call gitTools#tools#Error("ERROR: commit description file not saved (perform :w) ".a:descFile)
        endif
        return
    endif

    if expand("%") != a:descFile
        silent exec("new ".a:descFile)
        let l:closeBuffOnExit = 1
    else
        let l:closeBuffOnExit = 0
    endif

    if &modified == 1
        call gitTools#tools#Error("ERROR: Description file contains changes not saved.")
        if l:closeBuffOnExit == 1 | silent quit! | endif
        return
    endif

    echo "Commit description file: "
    echo "   ".a:descFile

    echo "Commit description : "
    " Show description up to 15 lines.
    let l:descContent = readfile(a:descFile)
    let l:n = 0
    for l:line in l:descContent
        let l:line = gitTools#tools#TrimString(l:line)
        if l:line == "" | continue | endif
        if l:line[0] == "#" | continue | endif
        echo "   ".l:line
        let l:n += 1
        if l:n > 15
            echo "   ..."
            echo "(Commit description truncated at 15 lines)"
            break
        endif
    endfor

    if l:n == 0
        call gitTools#tools#Warn("Attention! Description is empty, commit may be rejected.")
    endif

    if getline(1) == "" && line("$") == 1 
        call gitTools#tools#Error("ERROR: commit description empty on: ".a:descFile)
        if l:closeBuffOnExit == 1 | silent quit! | endif
        return
    endif

    if confirm("ATTENTION! Perform git commit with '".a:descFile."' message file? ",  "&Yes\n&no", 2) != 1
        if l:closeBuffOnExit == 1 | silent quit! | endif
        return
    endif

    echom "Committing..."
    call system(g:gitTools_commitDescFileCmd." ".a:options)

    call delete(a:descFile)
    echom "Commited"

    if l:closeBuffOnExit == 1 | silent quit! | endif

    if confirm("Show git log?", "&yes\n&no", 1) == 1
        call gitTools#log#GetHistory("")
    endif
endfunction


" Perform git commit -m "description"
" Arg1: description, commit description.
function! s:CommitDescription(description, options)
    if a:description == ""
        call gitTools#tools#Error("ERROR: commit description empty ".a:description)
        return
    endif

    echo "Commit description: "
    echo "   ".a:description
    if confirm("ATTENTION! Perform git commit? ", "&Yes\n&no", 2) != 1
        return
    endif

    echom "Committing..."
    call system(g:gitTools_commitMssgCmd." ".a:description." ".a:options)
    echom "Commited"

    if confirm("Show git log?", "&yes\n&no", 1) == 1
        call gitTools#log#GetHistory("")
    endif

    " Clean merge files if needed:
    call gitTools#conflict#CleanTemporaryMergeFiles()
endfunction


