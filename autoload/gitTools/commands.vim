" Script Name: commands.vim
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
" NOTES:
"

"- functions -------------------------------------------------------------------


" Add file to stage.
" Arg1: [filepath], get Word under cursor if empty.
" Commands: Gita
function! gitTools#commands#Add(filepath) range
    " Save window position
    let l:winview = winsaveview()

    let l:linesList = []

    if a:filepath != ""
        "let l:linesList += [ a:filepath ]
        if a:filepath == "%"
            let l:filepath = expand('%')
        else
            let l:filepath = a:filepath
        endif

        if !filereadable(l:filepath) && !isdirectory(l:filepath)
            call gitTools#tools#Error("ERROR: '".l:filepath."' path not found on disk.")
            return 0
        endif

        let l:linesList += [ l:filepath ]
    else
        let l:linesNum = a:lastline - a:firstline

        if l:linesNum != 0
            let l:n = str2nr(a:firstline)
            while l:n <= str2nr(a:lastline)
                let l:linesList += [ gitTools#tools#TrimString(getline(l:n)) ]
                let l:n += 1
            endwhile
        else
            let l:linesList += [ gitTools#tools#TrimString(getline(".")) ]
        endif
    endif

    "echom "linesList: "l:linesList

    if len(l:linesList) > 1
        let l:header = ""
    else
        let l:header = "[gitTools.vim] "
    endif

    let l:n = 0
    for l:line in l:linesList

        for l:filepath in split(l:line, " ")
            if l:filepath == "" | continue | endif
            if s:isGitStatusReservedWord(l:filepath) == 1 | continue | endif

            if filereadable(l:filepath)
                call system("git add ".l:filepath)
                echo l:header."git add ".l:filepath."... done"
                let l:n += 1
            elseif isdirectory(l:filepath)
                call confirm("Confirm to add directory: ".l:filepath)
                call system("git add ".l:filepath)
                echo l:header."git add ".l:filepath."... done"
                let l:n += 1
            else
                call gitTools#tools#Error("ERROR: '".l:filepath."' path not found.")
            endif
        endfor
    endfor

    if len(l:linesList) > 1
        echo "[gitTools.vim] ".l:n." paths added."
    endif

    if len(l:linesList) > 0 && l:n > 0
        if confirm("Update git status?", "&yes\n&no", 2) != 2
            call gitTools#status#GetStatus(getcwd(), "")
            " Restore window position
            call winrestview(l:winview)
        endif
    endif
endfunction


" Remove file from stage.
" Arg1: [filepath], get Word under cursor if empty.
" Commands: Gitu
function! gitTools#commands#Unstage(filepath) range
    " Save window position
    let l:winview = winsaveview()

    let l:linesList = []

    if a:filepath != ""
        "let l:linesList += [ a:filepath ]
        if a:filepath == "%"
            let l:filepath = expand('%')
        else
            let l:filepath = a:filepath
        endif

        if !filereadable(l:filepath) && !isdirectory(l:filepath)
            call gitTools#tools#Error("ERROR: '".l:filepath."' path not found on disk.")
            return 0
        endif

        let l:linesList += [ l:filepath ]
    else
        let l:linesNum = a:lastline - a:firstline

        if l:linesNum != 0
            let l:n = str2nr(a:firstline)
            while l:n <= str2nr(a:lastline)
                let l:linesList += [ gitTools#tools#TrimString(getline(l:n)) ]
                let l:n += 1
            endwhile
        else
            let l:linesList += [ gitTools#tools#TrimString(getline(".")) ]
        endif
    endif

    "echo "linesList: "l:linesList

    if len(l:linesList) > 1
        let l:header = ""
    else
        let l:header = "[gitTools.vim] "
    endif

    let l:n = 0
    for l:line in l:linesList
        if a:filepath == "" && s:isGitFileStatusLine(l:line) == 0
            let l:mssg = "WARNING: not a status line: '".l:line."'. Status tags expected (new file/modified/deleted/unmerged...)"
            call gitTools#tools#Warn(l:mssg)
            continue
        endif

        for l:filepath in split(l:line, " ")
            if l:filepath == "" | continue | endif
            if s:isGitStatusReservedWord(l:filepath) == 1 | continue | endif

            if filereadable(l:filepath)
                call system("git restore --staged  ".l:filepath)
                echo l:header."git restore --staged ".l:filepath."... done"
                let l:n += 1
            elseif isdirectory(l:filepath)
                call confirm("Confirm to unstage directory: ".l:filepath)
                call system("git restore --staged  ".l:filepath)
                echo l:header."git restore --staged ".l:filepath."... done"
                let l:n += 1
            else
                call gitTools#tools#Warn("WARNING: '".l:filepath."' path not found.")
                call system("git restore --staged  ".l:filepath)
                echo l:header."git restore --staged ".l:filepath."... "
                let l:n += 1
            endif
        endfor
    endfor

    if len(l:linesList) > 1
        echo "[gitTools.vim] ".l:n." paths unstaged."
    endif

    if len(l:linesList) > 0 && l:n > 0
        if confirm("Update git status?", "&yes\n&no", 2) != 2
            call gitTools#status#GetStatus(getcwd(), "")
            " Restore window position
            call winrestview(l:winview)
        endif
    endif
endfunction


" Restore file changes.
" Arg1: [filepath], get Word under cursor if empty.
" Commands: GitR
function! gitTools#commands#Restore(filepath) range
    " Save window position
    let l:winview = winsaveview()

    let l:linesList = []

    if a:filepath != ""
        "let l:linesList += [ a:filepath ]
        if a:filepath == "%"
            let l:filepath = expand('%')
        else
            let l:filepath = a:filepath
        endif

        if !filereadable(l:filepath) && !isdirectory(l:filepath)
            "call gitTools#tools#Error("ERROR: '".l:filepath."' path not found on disk.")
            "return 0
            call gitTools#tools#Warn("'".l:filepath."' path not found on disk.")
        endif

        let l:linesList += [ l:filepath ]
    else
        let l:linesNum = a:lastline - a:firstline

        if l:linesNum != 0
            let l:n = str2nr(a:firstline)
            while l:n <= str2nr(a:lastline)
                let l:linesList += [ gitTools#tools#TrimString(getline(l:n)) ]
                let l:n += 1
            endwhile
        else
            let l:linesList += [ gitTools#tools#TrimString(getline(".")) ]
        endif
    endif

    "echo "linesList: "l:linesList

    if len(l:linesList) > 1
        let l:header = ""
    else
        let l:header = "[gitTools.vim] "
    endif

    let l:restoreAll = "no"
    let l:n = 0
    for l:line in l:linesList
        if a:filepath == "" && s:isGitFileStatusLine(l:line) == 0
            let l:mssg = "WARNING: not a status line: '".l:line."'. Status tags expected (new file/modified/deleted/unmerged...)"
            call gitTools#tools#Warn(l:mssg)
            continue
        endif

        for l:filepath in split(l:line, " ")
            if l:filepath == "" | continue | endif
            if s:isGitStatusReservedWord(l:filepath) == 1 | continue | endif

            redraw
            if filereadable(l:filepath) || isdirectory(l:filepath)
                call gitTools#tools#Warn("'".l:filepath."' path not found.")
            endif
                "if confirm("Restore (".l:filepath.") discarding changes?", "&yes\n&no", 2) != 2
                let l:restore = 0

                if l:restoreAll != "yes"
                    let l:options = "&yes\n&no"
                    if len(l:linesList) > 1
                        let l:options .= "\n&All"
                    endif
                    "let l:resp = confirm("Restore (".l:filepath.") discarding changes?", "&yes\n&no\n&All", 2)
                    let l:resp = confirm("Restore (".l:filepath.") discarding changes?", l:options, 2)

                    if l:resp == 3
                        call confirm("Attetion! Changes on all selected files will be reverted.")
                        let l:restoreAll = "yes"
                    endif
                    if l:resp != 2
                        let l:restore = 1
                    endif
                else
                    let l:restore = 1
                endif

                if l:restore == 1
                    call system("git restore ".l:filepath)
                    let res = system("git restore ".l:filepath)
                    echo l:res
                    redraw
                    echo l:header."git restore ".l:filepath."... done"
                    let l:n += 1
                endif
            "else
                "call gitTools#tools#Error("ERROR: '".l:filepath."' path not found.")
            "endif
        endfor
    endfor

    if len(l:linesList) > 1
        redraw
        echo "[gitTools.vim] ".l:n." paths restored."
    endif

    if len(l:linesList) > 0 && l:n > 0
        if confirm("Update git status?", "&yes\n&no", 2) != 2
            call gitTools#status#GetStatus(getcwd(), "")
            " Restore window position
            call winrestview(l:winview)
        endif
    endif
endfunction


" Remove files from disk.
" Arg1: [filepath], get Word under cursor if empty.
" Commands: Gitrm
function! gitTools#commands#Remove(filepath) range
    " Save window position
    let l:winview = winsaveview()

    let l:linesList = []

    if a:filepath != ""
        if a:filepath == "%"
            let l:filepath = expand('%')
        else
            let l:filepath = a:filepath
        endif

        if !filereadable(l:filepath) && !isdirectory(l:filepath)
            call gitTools#tools#Error("ERROR: '".l:filepath."' path not found on disk.")
            return 0
        endif

        let l:linesList += [ l:filepath ]
    else
        let l:linesNum = a:lastline - a:firstline

        if l:linesNum != 0
            let l:n = str2nr(a:firstline)
            while l:n <= str2nr(a:lastline)
                let l:linesList += [ gitTools#tools#TrimString(getline(l:n)) ]
                let l:n += 1
            endwhile
        else
            let l:linesList += [ gitTools#tools#TrimString(getline(".")) ]
        endif
    endif

    "echo "linesList: "l:linesList

    if len(l:linesList) > 1
        let l:header = ""
    else
        let l:header = "[gitTools.vim] "
    endif

    let l:n = 0
    for l:line in l:linesList
        if a:filepath == "" && s:isGitFileStatusLine(l:line) == 0
            let l:mssg = "WARNING: not a status line: '".l:line."'. Status tags expected (new file/modified/deleted/unmerged...)"
            call gitTools#tools#Warn(l:mssg)
            continue
        endif

        for l:filepath in split(l:line, " ")
            if l:filepath == "" | continue | endif
            if s:isGitStatusReservedWord(l:filepath) == 1 | continue | endif

            let l:cmd = "git rm ".l:filepath
            echo "Remove from repository: ".l:filepath

            if !filereadable(l:filepath) && !isdirectory(l:filepath)
                call gitTools#tools#Warn("WARNING: '".l:filepath."' path not found on disk.")
            else
                let l:options = ""
                if confirm("Remove from disk too?", "&yes\n&no", 2) == 2
                    let l:options += "--cached "
                endif

                if isdirectory(l:filepath)
                    if confirm("Remove from git?", "&yes\n&no", 2) != 2
                        let l:cmd = "git rm ".l:options.l:filepath."/*"
                    endif
                else
                    let l:cmd = "git rm ".l:options.l:filepath
                endif
            endif

            if l:cmd != ""
                call system(l:cmd)
                "redraw
                echo l:header.l:cmd." ... done"
                let l:n += 1
            endif
        endfor
    endfor

    if len(l:linesList) > 1
        "redraw
        echo "[gitTools.vim] ".l:n." paths removed."
    endif

    if len(l:linesList) > 0 && l:n > 0
        if confirm("Update git status?", "&yes\n&no", 2) != 2
            call gitTools#status#GetStatus(getcwd(), "")
            " Restore window position
            call winrestview(l:winview)
        endif
    endif
endfunction


" Remove files from disk.
" Arg1: [filepath], get Word under cursor if empty.
" Commands: GitRM
function! gitTools#commands#DiskRemove(filepath) range
    " Save window position
    let l:winview = winsaveview()

    let l:linesList = []

    if a:filepath != ""
        "let l:linesList += [ a:filepath ]
        if a:filepath == "%"
            let l:filepath = expand('%')
        else
            let l:filepath = a:filepath
        endif

        if !filereadable(l:filepath) && !isdirectory(l:filepath)
            call gitTools#tools#Error("ERROR: '".l:filepath."' path not found on disk.")
            return 0
        endif

        let l:linesList += [ l:filepath ]
    else
        let l:linesNum = a:lastline - a:firstline

        if l:linesNum != 0
            let l:n = str2nr(a:firstline)
            while l:n <= str2nr(a:lastline)
                let l:linesList += [ gitTools#tools#TrimString(getline(l:n)) ]
                let l:n += 1
            endwhile
        else
            let l:linesList += [ gitTools#tools#TrimString(getline(".")) ]
        endif
    endif

    "echo "linesList: "l:linesList

    if len(l:linesList) > 1
        let l:header = ""
    else
        let l:header = "[gitTools.vim] "
    endif

    let l:removeList = ""
    let l:removeAll = 0
    let l:n = 0
    for l:line in l:linesList
        for l:filepath in split(l:line, " ")
            if l:filepath == "" | continue | endif
            if s:isGitStatusReservedWord(l:filepath) == 1 | continue | endif

            if !filereadable(l:filepath) && !isdirectory(l:filepath)
                call gitTools#tools#Error("ERROR: '".l:filepath."' path not found.")
                continue
            endif

            if isdirectory(l:filepath)
                let l:remove = 0

                if l:removeAll == 1
                    let l:remove = 1
                else
                    echo "Dir: '".l:filepath."'"
                    let l:answer = confirm("Remove directory from disk?", "&yes\n&no\n&all", 2)

                    if l:answer == 1
                        let l:remove = 1
                    endif

                    if l:answer == 3
                        call confirm("ATTENTION! Are you sure you want to remove all selected files from disk?")
                        let l:removeAll = 1
                        let l:remove = 1
                    endif
                endif

                if l:remove
                    let l:removeList .= l:filepath." "
                endif
                redraw
            endif

            if filereadable(l:filepath)
                let l:remove = 0

                if l:removeAll == 1
                    let l:remove = 1
                else
                    echo "File: '".l:filepath."'"
                    let l:answer = confirm("Remove file from disk?", "&yes\n&no\n&all", 2)

                    if l:answer == 1
                        let l:remove = 1
                    endif

                    if l:answer == 3
                        call confirm("ATTENTION! Are you sure you want to remove all selected files from disk?")
                        let l:removeAll = 1
                        let l:remove = 1
                    endif
                endif

                if l:remove
                    echo "Removing: '".l:filepath."'"
                    let l:removeList .= l:filepath." "
                endif
                redraw
            endif
        endfor
    endfor

    if len(l:removeList) > 1
        let l:n = 1
        for l:file in split(l:removeList)
            echo l:n.". ".l:file
            let l:n += 1
        endfor

        call confirm("ATTENTION! Are you sure you want to remove all the avove files from disk?")

        call system("rm -r ".l:removeList)

        redraw
        echo "[gitTools.vim] ".l:n." paths removed."

        if confirm("Update git status?", "&yes\n&no", 2) != 2
            call gitTools#status#GetStatus(getcwd(), "")
            " Restore window position
            call winrestview(l:winview)
        endif
    endif
endfunction


" Git rename files.
" Arg1: [file/path], get Word under cursor if empty.
" Arg2: file/path, get Word under cursor if empty.
" Commands: Gitmv
function! gitTools#commands#Move(...)
    " Save window position
    let l:winview = winsaveview()

    let l:path0 = ""
    let l:path1 = ""

    if a:0 == 0
        let l:path0 = gitTools#tools#TrimString(getline("."))
        echo "Move ".l:path0
        let l:path1 = input("Enter new file name: ")
    elseif a:0 == 1
        if filereadable(l:path) || isdirectory(l:path)
            let l:path0 = gitTools#tools#TrimString(getline("."))
            echo "Move ".l:path0
            let l:path1 = input("Enter new file name: ")
        else
            echo "New name ".l:path1
            let l:path0 = input("Enter current file name: ")
        endif
    elseif a:0 >= 1
        let l:path0 = a:1
        let l:path1 = a:2
        echo "Move ".l:path0." to ".l:path1
    endif

    if l:path0 == ""
        call gitTools#tools#Error("ERROR: current file/path name missing.")
        return
    endif

    if l:path1 == ""
        call gitTools#tools#Error("ERROR: new file/path name missing.")
        return
    endif

    let l:n = 0
    for l:path in split(l:path0, " ")
        if l:path == "" | continue | endif
        if s:isGitStatusReservedWord(l:path) == 1 | continue | endif


        if filereadable(l:path) || isdirectory(l:path)
            if confirm("Git move ".l:path." to ".l:path1, "&yes\n&no", 2) != 2
                call system("git mv ".l:path." ".l:path1)
                redraw
                echo "[gitTools.vim] git mv ".l:path." ".l:path1."... done"
                let l:n += 1
            else
                call gitTools#tools#Error("ERROR: '".l:path."' path not found.")
                return
            endif
        endif
    endfor

    if l:n > 0
        if confirm("Update git status?", "&yes\n&no", 2) != 2
            call gitTools#status#GetStatus(getcwd(), "")
            " Restore window position
            call winrestview(l:winview)
        endif
    else
        call gitTools#tools#Error("ERROR: move error.")
    endif
endfunction

function! s:isGitStatusReservedWord(word)
    if a:word == "new"       | return 1 | endif
    if a:word == "file:"     | return 1 | endif
    if a:word == "modified:" | return 1 | endif
    if a:word == "both"      | return 1 | endif
    if a:word == "added:"    | return 1 | endif
    if a:word == "unmerged:" | return 1 | endif
    if a:word == "deleted:"  | return 1 | endif
    if a:word == "renamed:"  | return 1 | endif
    if a:word == "typechange:" | return 1 | endif
    if a:word == " " | return 1 | endif
    if a:word == "" | return 1 | endif
    return 0
endfunction

function! s:isGitFileStatusLine(line)
    if a:line =~ "new file:" | return 1 | endif
    if a:line =~ "modified:" | return 1 | endif
    if a:line =~ "both modified:" | return 1 | endif
    if a:line =~ "both added:" | return 1 | endif
    if a:line =~ "unmerged:" | return 1 | endif
    if a:line =~ "deleted:"  | return 1 | endif
    if a:line =~ "renamed:"  | return 1 | endif
    if a:line =~ "typechange:" | return 1 | endif
    return 0
endfunction
