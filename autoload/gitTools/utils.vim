" Script Name: gitTools/utils.vim
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
"

"- functions -------------------------------------------------------------------



" Compare with vimdiff file on current buffer with same one on a different 
" working directory.
" Handy to open and compare quickly, same files on different sandboxes.
" Arg1: CMD, new/vnew.
" Arg2: [PATH1], pattern to be replaced on current files's path.
" Arg3: path2, string to replace the found pattern.
 "Cmd:  Vdf and Vdfv
func! gitTools#utils#DiffSameFileOnPath(...)
    if a:0 == 2
        let l:filepath1 = expand("%:p")
        let l:file0 = substitute(l:filepath1, getcwd(), "", "")
        let l:path2 = a:2
        let l:filepath2 = l:path2."/".l:file0
    elseif a:0 == 3
        let l:filepath1 = a:1
        let l:filepath2 = substitute(expand("%:p"), a:2, a:3, "g")
        echo l:filepath2
    else
        echohl ErrorMsg | echo "Arguments: [PATH1] PATH2" | echohl None
        return
    endif

    if l:filepath1 == l:filepath2
        echohl ErrorMsg | echo "Same path not allowed: ".l:filepath1." ".l:filepath2 | echohl None
        return
    endif

    if !filereadable(l:filepath2)
        echohl ErrorMsg | echo "File not found ".l:filepath2 | echohl None
        return
    endif

    redraw
    echo "[GitTools.vim] Vimdiff: ".l:filepath1." and ".l:filepath2

    silent exec(l:filepath1)
    silent exec("edit ".l:filepath2)
    windo diffthis
endfunc


" Compare all files between two directories: 
" Arg: [PATH1]. primary file/path.
" Arg: PATH2. secondary sandbox path to compare files. 
" Arg: [FLAGS]:
"  ALL:show all files modified.
"  BO:  show binaries only.
"  SB: skip binaries (default). 
"  EO: show equal files only.
"  SE: skip equal files (default). 
"  +KeepPattern: keep files matching pattern.
"  -SkipPattern: skip files matching pattern.
" Cmd:  Vdd1.
func! gitTools#utils#VimdiffAll(...)
    if a:0 < 1
        call gitTools#tools#Error("Arguments error. Missing paths. Arguments: [PATH1] PATH2 [FLAGS]")
        return
    endif

    let l:mode  = "diff"
    let l:path1 = ""
    let l:path2 = ""
    let l:equals = "skip"
    let l:binaries = "skip"
    let l:keepStr = ""
    let l:filterStr = ""

    for l:arg in a:000
        if l:arg ==? "ALL" || l:arg ==? "BO" || l:arg ==? "SB" || l:arg ==? "EO" || l:arg ==? "SE" || l:arg[0] == '+' || l:arg[0] == '-'
        elseif l:arg[0] == '-'
            let l:filterStr .= l:arg[1:]." "
        elseif !empty(glob(l:arg))
            if l:path1 == ""
                let l:path1 = l:arg
                let l:path1 = substitute(l:path1,'^\s\+','','g')
                let l:path1 = substitute(l:path1,'\s\+$','','g')
            else
                if l:path2 == ""
                    let l:path2 = l:arg
                    let l:path2 = substitute(l:path2,'^\s\+','','g')
                    let l:path2 = substitute(l:path2,'\s\+$','','g')
                else
                    call gitTools#tools#Warn("Path1 and Path2 already set. Skipping path: ".l:arg)
                    call confirm("Continue?")
                endif
            endif
        else
            call gitTools#tools#Warn("Unknown argument: ".l:arg)
            call confirm("Continue?")
        endif
    endfor

    if l:path2 == ""
        let l:dirs = substitute(expand("%:h"), getcwd(), "", "")
        let l:path2 = l:path1."/".l:dirs
        let l:path1 = expand("%:h")
    endif

    if empty(glob(l:path2))
        call gitTools#tools#Error("Path2 not found ".l:path2)
        return
    endif
    if empty(glob(l:path1))
        call gitTools#tools#Error("Path1 not found ".l:path1)
        return
    endif
    if l:path1 == l:path2
        call gitTools#tools#Error("Paths must be different ".l:path1." ".l:path2)
        return
    endif

    "----------------------------------------
    " Get all files on the directory (recursive):
    "----------------------------------------
    "echom "Path1:".l:path1
    let l:filesStr = globpath(l:path1, "**")
    let l:filesList = split(l:filesStr, "\n")
    "echom "FilesStr:".l:filesStr
    "echom "FilesList:"l:filesList

    "----------------------------------------
    " Filter Files:
    " Filter acording to flags on arguments list, keep/skip binaries/equal-files/match-patterns.
    " Flags:
    "  ALL:show all files modified.
    "  BO:  show binaries only.
    "  SB: skip binaries (default). 
    "  EO: show equal files only.
    "  SE: skip equal files (default). 
    "----------------------------------------
    redraw
    echo "[gitTools.vim] Diff files between: ".l:path1." and ".l:path2
    let l:filesList = gitTools#misc#FilterFilesListWithArgsList(a:000, l:filesList, l:path1, l:path2)

    if len(l:filesList) == 0
        echo ""
        call gitTools#tools#Warn("No modifications found")
        call input("")
        return
    endif

    echo "Files to open: ".len(l:filesList)
    call confirm("Perform ".l:mode." on this ".len(l:filesList)." files?")


    "----------------------------------------
    " Open vimdiff for all files:
    "----------------------------------------
    let l:n = 1
    for l:file1 in l:filesList
        let l:file2 = substitute(l:file1, l:path1, l:path2, "")
        echo " - Opening vimdiff ".l:n.": ".l:file1." and ".l:file2

        silent exec("tabedit ".l:file1)

        " Visually show tabs and spaces
        silent exec("set invlist")
        silent exec("set listchars=tab:>.,trail:_,extends:\#,nbsp:_")

        silent diffthis

        silent vnew
        silent exec("edit ".l:file2) 

        " Visually show tabs and spaces
        silent exec("set invlist")
        silent exec("set listchars=tab:>.,trail:_,extends:\#,nbsp:_")

        silent diffthis
        let l:n += 1
    endfor

    redraw
    echo " "
    echo " "
    echo "[gitTools.vim] Compare files on: ".l:path1." and ".l:path2." Differing files:".l:n
endfunc

" Check hash number.
" Return: 0 if ok. 1, 2 otherwise.
func! gitTools#utils#CheckHash(hash)
    " CHeck hash number lenght:
    if len(a:hash) < 11
        call gitTools#tools#Error("Error. Wrong hash number: '".a:hash."' lenght (expected lenght >= 12)")
        return 1
    endif

    " Check hash contains both numbers and letters:
    let l:numbers = substitute(a:hash, '[^0-9]*', '', 'g')
    let l:letters = substitute(a:hash, '[^a-zA-Z]*', '', 'g')

    if l:numbers == "" || l:letters == ""
        call gitTools#tools#Warn("Error. Weird hash number '".a:hash."'")
        return 2
    endif

    return 0
endfunc

