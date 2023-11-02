" gitipt Name: gitTools/conflict.vim
 "Description: 
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"


" Merge files with conflicts on given path. 
" Open every file in conflict on a new tab and split vertical showing BASE,
" LOCAL, REMOTE  and MERGED files acording to the selected layout.
" Arg1: file or path.
" Arg2: [optional] window layout configuration.
" Commands: Gitmc, Gitmcf, Gitmcd, GitmcS.
function! gitTools#conflict#Merge(...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    if a:0 < 1
        call gitTools#tools#Error("ERROR: arg 1, path not provided.")
        return
    endif

    let l:path = a:1

    if l:path == "%"
        let l:path = expand("%:d")
    endif

    if l:path == ""
        call gitTools#tools#Error("ERROR: arg 1, path not provided.")
        return
    endif

    if !isdirectory(l:path) && !filereadable(l:path)
        call gitTools#tools#Error("ERROR: path not found ".l:path)
        return
    endif

    if a:0 >= 2
        let l:mergeLayout = toupper(a:2)
    else
        let l:mergeLayout = g:gitTools_dfltMergeLayout
    endif

    if g:gitTools_mergeLayouts !~ l:mergeLayout
        call gitTools#tools#Error("Selected layout ". l:mergeLayout ." not found on layout list: [".g:gitTools_mergeLayouts."]")
        return
    endif


    if isdirectory(l:path)
        echo "Unmerged files' search in progress..."
        let l:list = s:GetUnmergedFilesList(l:path, "", "")

        let len = len(l:list)
        if len(l:list) == 0
            call gitTools#tools#Warn("No conflicts found")
            call confirm("")
            return
        endif

        redraw
        echo "Files in conflict:"
        for l:file in l:list 
            echo "- ".l:file
        endfor
        echo " "
        echo "ATTENTION! Launch :Gitmcrm to remove merge files when all conflicts solved."
        call input("Open all with merge tool?")

        redraw
        echo "This may take a while ..."
        echo ""
    else
        let l:list = [ l:path ]
    endif

    call s:OpenGitMerge(list, l:mergeLayout)
endfunction


function! s:OpenGitMerge(list, mergeLayout)
    " Save window position
    let l:winNr = win_getid()

    " Perform git diff on each selected file.
    " Open each file with vimdiff on new tab
    let l:n = 0
    for l:file in a:list 
        if !filereadable(l:file)
            call gitTools#tools#Warn("File not found: ".l:file)
        else
            echom l:file

            " Launch git mergetool
            let l:name = fnamemodify(l:file, ":r")
            let l:ext  = fnamemodify(l:file, ":e")
            let l:filesList = glob(l:name."_REMOTE*.".l:ext, 0, 1)
            let l:cmd = "git mergetool mergetool.prompt false --tool=vimdiff ".l:file

            if len(l:filesList) != 0
                echo "Previous merge files (_LOCAL, _REMOTE, _BACKUP) found."
                if confirm("Generate merge files again with git mergetool?", "&yes\n&no", 2) == 1
                    call system(l:cmd) 
                endif
            else
                call system(l:cmd) 
            endif

            let l:lastWinNr = win_getid()

            echo "Openning ".l:file." on merge tool (layout ".a:mergeLayout.")." 

            "exec "let l:res = s:MergeLayout".l:mergeLayout."(\"".l:file."\")"
            let l:res = s:MergeLayout(l:file, a:mergeLayout)

            if l:res != 0
                call win_gotoid(l:lastWinNr)

                if len(a:list) > 1
                    call confirm("Continue with next conflict?")
                endif
            else
                if l:n == 0
                    " Save first diff window position
                    let l:winNr = win_getid()
                endif
                let l:n += 1
            endif
        endif
    endfor

    " Restore window position
    call win_gotoid(l:winNr)

    echo " "
    echo "[gitTools.vim] Show git merge conflicts using vimdiff. ".l:n." files."

    " Search merge tags
    silent call gitTools#conflict#SearchMergeTags()
endfunction


" Search merge conflict search tags:
" Commands: Gitmcs
function! gitTools#conflict#SearchMergeTags()
    let l:patterns = "<<<<<<<\\|=======\\|>>>>>>>"
    echo "Search: ".l:patterns

    let line = search(l:patterns, 'W', 0, 500)
    silent! let @/ = l:patterns

    if l:line == 0
        call gitTools#tools#Error("ERROR: no merge tags found.")
    endif
endfunction


" Merge  
" Arg1: file or path.
" Commands: Gitml
"function! gitTools#conflict#MergeList(mergeNumb)
    "if !exists("s:GitTools_mergeFilesList") || len(s:GitTools_mergeFilesList) <= 0
        "call gitTools#tools#Error("ERROR: no list of merged files available.")
        "return
    "endif

    "for l:file in s:GitTools_mergeFilesList
        "let l:res = s:MergeLayout(l:file, l:mergeLayout, a:mergeNumb)
    "endfor
"endfunction


" Launch selected layout
function! s:MergeLayout(file, layout)
    if (a:layout == "1")
        "----------
        "| MERGED |
        "----------
        return MergeLayout1(a:file, "")

    elseif (a:layout == "2" || a:layout == "2A")
        "------------------
        "| LOCAL | MERGED |
        "------------------
        return MergeLayoutV2(a:file,  "_LOCAL*", "_MERGED*")

    elseif (a:layout == "2B")
        "-------------------
        "| MERGED | REMOTE |
        "-------------------
        return MergeLayoutV2(a:file,  "_MERGED*", "_REMOTE*")

    elseif (a:layout == "3" || a:layout == "3A")
        "----------------------------
        "| LOCAL | MERGED  | REMOTE |
        "----------------------------
        call s:MergeLayoutV3(file, tag1, tag2, tag3)

    elseif (a:layout == "3B")
        "------------------
        "| LOCAL | REMOTE |
        "------------------
        "|     MERGED     |
        "------------------
        return s:MergeLayoutV2H1(a:file, "_LOCAL*", "_REMOTE*", "")

    elseif (a:layout == "4")
        "-------------------------
        "| BASE | LOCAL | REMOTE |
        "-------------------------
        "|        MERGED         |
        "-------------------------
        return s:MergeLayoutV3H1(a:file, "_BASE*", "_LOCAL*", "_REMOTE*", "")
    endif
    return 0
endfunction


" Merge window layout 1.
"   ----------
"   |        |
"   | FILE1  |
"   |        |
"   ----------
function! s:MergeLayout1(file)
    silent tabnew
    let n = 0

    let l:tag1 = ""

    let l:name = fnamemodify(a:file, ":r")
    let l:ext  = fnamemodify(a:file, ":e")

    let l:file1 = l:name.l:tag1.l:ext

    let l:match = l:name.l:tag1.".".l:ext
    let l:filesList = glob(l:match, 0, 1)
    if len(l:filesList) > 0
        let l:file1 = l:filesList[len(l:filesList)-1]
    endif

    if !filereadable(l:file1)
        call gitTools#tools#Warn("Missing file: ". l:file1)
    else
        silent exec("edit ". l:file1)
        let n += 1
    endif

    if l:n == 0
        silent! tabclose
        return 1
    else
        return 0
    endif
endfunction


" Merge window layout 2.
"   -----------------
"   |       |       |
"   | FILE1 | FILE2 |
"   |       |       |
"   -----------------
function! s:MergeLayoutV2(file, tag1, tag2)
    tabnew
    let n = 0

    let l:tag1 = a:tag1
    let l:tag2 = a:tag2

    let l:name = fnamemodify(a:file, ":r")
    let l:ext  = fnamemodify(a:file, ":e")

    " Search all files matching wildcard ont tag variable, open the last one.
    let l:file1 = l:name.l:tag1.l:ext
    let l:file2 = l:name.l:tag2.l:ext

    let l:match = l:name.l:tag1.".".l:ext
    let l:filesList = glob(l:match, 0, 1)
    if len(l:filesList) > 0
        let l:file1 = l:filesList[len(l:filesList)-1]
    endif

    let l:match = l:name.l:tag2.".".l:ext
    let l:filesList = glob(l:match, 0, 1)
    if len(l:filesList) > 0
        let l:file2 = l:filesList[len(l:filesList)-1]
    endif

    if !filereadable(l:file1)
        call gitTools#tools#Warn("Missing file: ". l:file1)
    else
        silent exec("edit ". l:file1)
        let n += 1
    endif

    if !filereadable(l:file2)
        call gitTools#tools#Warn("Missing file: ". l:file2)
    else
        if l:n != 0
            silent exec("vert new") 
        endif
        silent exec("edit ". l:file2)
        let n += 1
    endif

    if l:n == 0
        silent! tabclose
        return 1
    elseif l:n > 1
        silent exec("windo diffthis")
    endif

    return 0
endfunction


" Merge layout 3 vertical windows.
"   -------------------------
"   |       |       |       |
"   | FILE1 | FILE2 | FILE3 |
"   |       |       |       |
"   -------------------------
function! s:MergeLayoutV3(file, tag1, tag2, tag3)
    tabnew
    let n = 0

    let l:tag1 = a:tag1
    let l:tag2 = a:tag2
    let l:tag3 = a:tag3

    " Search all files matching wildcard ont tag variable, open the last one.
    let l:name = fnamemodify(a:file, ":r")
    let l:ext  = fnamemodify(a:file, ":e")

    let l:file1 = l:name.l:tag1.l:ext
    let l:file2 = l:name.l:tag2.l:ext
    let l:file3 = l:name.l:tag3.l:ext

    let l:match = l:name.l:tag1.".".l:ext
    let l:filesList = glob(l:match, 0, 1)
    if len(l:filesList) > 0
        let l:file1 = l:filesList[len(l:filesList)-1]
    endif

    let l:match = l:name.l:tag2.".".l:ext
    let l:filesList = glob(l:match, 0, 1)
    if len(l:filesList) > 0
        let l:file2 = l:filesList[len(l:filesList)-1]
    endif

    let l:match = l:name.l:tag3.".".l:ext
    let l:filesList = glob(l:match, 0, 1)
    if len(l:filesList) > 0
        let l:file3 = l:filesList[len(l:filesList)-1]
    endif

    if !filereadable(l:file1)
        call gitTools#tools#Warn("Missing file: ". l:file1)
    else
        silent exec("edit ". l:file1)
        let n += 1
    endif

    if !filereadable(l:file2)
        call gitTools#tools#Warn("Missing file: ". l:file2)
    else
        if l:n != 0
            silent exec("vert new") 
        endif
        silent exec("edit ". l:file2)
        let n += 1
    endif

    if !filereadable(l:file3)
        call gitTools#tools#Warn("Missing file: ". l:file3)
    else
        if l:n != 0
            silent exec("vert new") 
        endif
        silent exec("edit ". l:file3)
        let n += 1
    endif

    if l:n == 0
        silent! tabclose
        return 1
    elseif l:n > 1
        silent exec("windo diffthis")
    endif

    return 0
endfunction


" Merge window layout 3 vertical windows, one horizontal window.
"    -----------------
"    |       |       |
"    | FILE1 | FILE2 |
"    |       |       |
"    -----------------
"    |     FILE3     |
"    -----------------
function! s:MergeLayoutV2H1(file, tag1, tag2, tag3)
    tabnew
    let n = 0

    let l:tag1 = a:tag1
    let l:tag2 = a:tag2
    let l:tag3 = a:tag3

    let l:name = fnamemodify(a:file, ":r")
    let l:ext  = fnamemodify(a:file, ":e")

    let l:file1 = l:name.l:tag1.l:ext
    let l:file2 = l:name.l:tag2.l:ext
    let l:file3 = l:name.l:tag3.l:ext

    let l:match = l:name.l:tag1.".".l:ext
    let l:filesList = glob(l:match, 0, 1)
    if len(l:filesList) > 0
        let l:file1 = l:filesList[len(l:filesList)-1]
    endif

    let l:match = l:name.l:tag2.".".l:ext
    let l:filesList = glob(l:match, 0, 1)
    if len(l:filesList) > 0
        let l:file2 = l:filesList[len(l:filesList)-1]
    endif

    let l:match = l:name.l:tag3.".".l:ext
    let l:filesList = glob(l:match, 0, 1)
    if len(l:filesList) > 0
        let l:file3 = l:filesList[len(l:filesList)-1]
    endif

    if !filereadable(l:file1)
        call gitTools#tools#Warn("Missing file: ". l:file1)
    else
        silent exec("edit ". l:file1)
        let n += 1
    endif

    if !filereadable(l:file2)
        call gitTools#tools#Warn("Missing file: ". l:file2)
    else
        if l:n != 0
            silent exec("vert new") 
        endif
        silent exec("edit ". l:file2)
        let n += 1
    endif

    if !filereadable(l:file3)
        call gitTools#tools#Warn("Missing file: ". l:file3)
    else
        if l:n != 0
            let l:winh = winheight(0)
            silent exec("new") 
            silent wincmd J
            "silent exe "resize ".l:winh/4
        endif
        silent exec("edit ". l:file3)
        let n += 1
    endif

    if l:n == 0
        silent! tabclose
        return 1
    elseif l:n > 1
        silent exec("windo diffthis")
    endif

    return 0
endfunction



" Merge window layout 4.
"    -------------------------
"    |       |       |       |
"    | FILE1 | FILE2 | FILE3 |
"    |       |       |       |
"    -------------------------
"    |        FILE4          |
"    -------------------------
function! s:MergeLayoutV3H1(file, tag1, tag2, tag3, tag4)
    tabnew
    let n = 0

    let l:tag1 = a:tag1
    let l:tag2 = a:tag2
    let l:tag3 = a:tag3
    let l:tag4 = a:tag4

    let l:name = fnamemodify(a:file, ":r")
    let l:ext  = fnamemodify(a:file, ":e")

    let l:file1 = l:name.l:tag1.l:ext
    let l:file2 = l:name.l:tag2.l:ext
    let l:file3 = l:name.l:tag3.l:ext
    let l:file4 = l:name.l:tag4.l:ext

    let l:match = l:name.l:tag1.".".l:ext
    let l:filesList = glob(l:match, 0, 1)
    if len(l:filesList) > 0
        let l:file1 = l:filesList[len(l:filesList)-1]
    endif

    let l:match = l:name.l:tag2.".".l:ext
    let l:filesList = glob(l:match, 0, 1)
    if len(l:filesList) > 0
        let l:file2 = l:filesList[len(l:filesList)-1]
    endif

    let l:match = l:name.l:tag3.".".l:ext
    let l:filesList = glob(l:match, 0, 1)
    if len(l:filesList) > 0
        let l:file3 = l:filesList[len(l:filesList)-1]
    endif

    let l:match = l:name.l:tag4.".".l:ext
    let l:filesList = glob(l:match, 0, 1)
    if len(l:filesList) > 0
        let l:file4 = l:filesList[len(l:filesList)-1]
    endif


    if !filereadable(l:file1)
        call gitTools#tools#Warn("Missing file: ". l:file1)
    else
        silent exec("edit ". l:file1)
        let n += 1
    endif

    if !filereadable(l:file2)
        call gitTools#tools#Warn("Missing file: ". l:file2)
    else
        if l:n != 0
            silent exec("vert new") 
        endif
        silent exec("edit ". l:file2)
        let n += 1
    endif

    if !filereadable(l:file3)
        call gitTools#tools#Warn("Missing file: ". l:file3)
    else
        if l:n != 0
            silent exec("vert new") 
        endif
        silent exec("edit ". l:file3)
        let n += 1
    endif

    if !filereadable(l:file4)
        call gitTools#tools#Warn("Missing file: ". l:file4)
    else
        if l:n != 0
            let l:winh = winheight(0)
            silent exec("new") 
            silent wincmd J
            "silent exe "resize ".l:winh/4
        endif
        silent exec("edit ". l:file4)
        let n += 1
    endif

    if l:n == 0
        silent! tabclose
        return 1
    elseif l:n > 1
        silent exec("windo diffthis")
    endif

    return 0
endfunction


" Return: list with all files in conflict.
function! s:GetUnmergedFilesList(path, branch1, branch2)
    let l:branches = ""
    if a:branch2 != ""
        if a:branch1 == ""
            "let l:branch1 = gitTools#info#GetCurrentBranch()
            let l:branch1 = gitTools#branch#Current()
        else
            let l:branch1 = a:branch1
        endif
        if a:branch2 != l:branch1
            let l:branches = l:branch1."..".a:branch2." "
        endif
    endif

    let l:cmd = "git diff --name-status --diff-filter=U ".l:branches.a:path
    echo l:cmd

    let l:result = system(l:cmd)
    "echom l:result | call confirm("continue?")

    "echom l:result | echom " "
    let l:result = substitute(l:result, '	', ' ', "g")
    let l:result = substitute(l:result, "^U ", "", "")
    let l:result = substitute(l:result, "\nU ", "\n", "g")
    "echom l:result | call confirm("continue?")

    let l:tmp = split(l:result, "\n")

    let l:list = deepcopy(l:tmp)
    let s:GitTools_mergeFilesList = deepcopy(l:tmp)
    return l:tmp
endfunction


" When Gitmc already launched previously.
" Search the temporary merge files (REMOTE, LOCAL and BACKUP) and remove them.
" Commands: Gitmcrm
function! gitTools#conflict#CleanTemporaryMergeFiles()
    let l:filesList = []

    if !exists("s:GitTools_mergeFilesList") || len(s:GitTools_mergeFilesList) <= 0
        call gitTools#tools#Error("ERROR: no list of merged files available.")
        return
    endif

    for l:file in s:GitTools_mergeFilesList
        echo " - File: ".l:file
        let l:list = s:GetMergeFilesList(l:file)
        if len(l:list) > 0
            let l:filesList += l:list
        endif
    endfor
    echo " "

    if len(l:filesList) == 0
        "echo "No temporary merge files found."
        return
    endif

    echo "Temporary merge files found:"
    for l:file in l:filesList
        echo " - ".l:file
    endfor

    if confirm("Delete all?", "&Yes\n&no", 2) != 1
        return
    endif

    redraw
    for l:file in l:filesList
        call delete(l:file)
    endfor
    unlet s:GitTools_mergeFilesList
endfunction


" Add current file to merge list.
" Commands: Gitma NOT_USED
function! gitTools#conflict#MergeListAddFile(...)
    if a:0 == 0
        let l:file = expand("%")
        if l:file == ""
            return
        endif
        let l:list = [ l:file ]
    else
        let l:list = a:000
    endif

    for l:file in l:list
        if !filereadable(l:file)
            call gitTools#tools#Error("ERROR: file not found ".l:file)
        else
            if !exists("s:GitTools_mergeFilesList")
                let s:GitTools_mergeFilesList = [ l:file ]
            else
                let s:GitTools_mergeFilesList += [ l:file ]
            endif
            echo "[gitTools.vim] File ".l:file." added to merge list."
        endif
    endfor
endfunction


" Delete merge list.
" Commands: Gitmd NOT_USED
function! gitTools#conflict#MergeListDelete()
    if !exists("s:GitTools_mergeFilesList") || len(s:GitTools_mergeFilesList) <= 0
        call gitTools#tools#Error("ERROR: no list of merged files available.")
        return
    endif

    for l:file in s:GitTools_mergeFilesList
        echo " - File: ".l:file
        let l:list = s:GetMergeFilesList(l:file)
        if len(l:list) > 0
            let l:filesList += l:list
        endif
    endfor

    call confirm("Remove saved temporary merge files names?")
    unlet s:GitTools_mergeFilesList
endfunction


" Arg1: merged file.
" Return: list with the files used for the git merge (BASE, REMOTE, LOCAL, BACKUP).
function! s:GetMergeFilesList(file)
    if !filereadable(a:file)
        call gitTools#tools#Error("ERROR: file not found ".a:file)
        return []
    endif

    let l:name = fnamemodify(a:file, ":r")
    let l:ext  = fnamemodify(a:file, ":e")

    let l:tagsList = [ "_BASE*", "_REMOTE*", "_LOCAL*", "_BACKUP*" ]
    let l:filesList = []

    for l:tag in l:tagsList
        let l:match = l:name.l:tag.".".l:ext
        let l:filesList += glob(l:match, 0, 1)
        "echo "Add file ".l:file
    endfor
    return l:filesList
endfunction

