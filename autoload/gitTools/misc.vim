" Script Name: gitTools/misc.vim
 "Description: 
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: diff, wc.
"
"

"- functions -------------------------------------------------------------------


" Filter a files list acording to the arguments list.
" Remove binary files if required.
" Remove files not matching patterns if required.
" Keep only files matching patterns if required.
" Arg1: arsList. List of arguments containing the filter options.
" Arg2: filesList. List of filepaths.
" Arg3: [path1]. Primary path. Use "" to skip. Used to remove unwanted path form files on the filesList.
" Arg4: [path2]. Secondary path. Use "" to skip. Used to get same files on filesList on different directory.
" Return: filtered files' list.
" Used by: GitD, GitDA, GitDD, GitVD, GitVDA, GitVDD, Gitdc, Gitvdc, Vdd.
function! gitTools#misc#FilterFilesListWithArgsList(argsList, filesList, path1, path2)
    "echom "gitTools#misc#FilterFilesListWithArgsList("a:argsList.", "a:filesList.", ".a:path1.", ".a:path2.")"

    let l:equals = "skip"
    let l:binaries = "skip"
    let l:keepStr = ""
    let l:filterStr = ""

    for l:arg in a:argsList
        if l:arg ==? "ALL"
            let l:equals = ""
            let l:binaries = ""
        elseif l:arg ==? "EO"
            let l:equals = "only"
        elseif l:arg ==? "SE"
            let l:equals = "skip"
        elseif l:arg ==? "BO"
            let l:binaries = "only"
        elseif l:arg ==? "SB"
            let l:binaries = "skip"
        elseif l:arg[0] == '+'
            let l:keepStr .= l:arg[1:]." "
        elseif l:arg[0] == '-'
            let l:filterStr .= l:arg[1:]." "
        endif
    endfor

    if l:equals.l:binaries.l:filterStr.l:keepStr != ""
        echon " Flags: "

        if l:equals == "skip"
            echon "skip_equal_files "
        elseif l:equals == "only"
            echon "show_equal_files_only "
        endif

        if l:binaries == "skip"
            echon "skip_binaries "
        elseif l:binaries == "only"
            echon "show_binaries_only "
        endif

        if l:keepStr != ""
            echon "KeepOnly: ".l:keepStr." "
        endif
        if l:filterStr != ""
            echon "Skip: ".l:filterStr." "
        endif
    endif
    echo " "

    return gitTools#misc#FilterFilesListWithOptions(a:filesList, l:equals, l:binaries, l:keepStr, l:filterStr, a:path1, a:path2)
endfunction


" Filter a files list acording to the options selected.
" Remove binary files if required.
" Remove files not matching patterns if required.
" Keep only files matching patterns if required.
" Arg1: filesList. List of filepaths.
" Arg2: binSkip. Skip binary files if not empty.
" Arg3: keepStr. Pattern to match with filename to keep it.
" Arg4: filterStr. Pattern to match with filename to skip it.
" Arg5: [path1]. Primary path. Use "" to skip. Used to remove unwanted path form files on the filesList.
" Arg6: [path2]. Secondary path. Use "" to skip. Used to get same files on filesList on different directory.
" Return: filtered files' list.
" Used by: GitD, GitDA, GitDD, GitVD, GitVDA, GitVDD, Gitdc, Gitvdc, Vdd.
function! gitTools#misc#FilterFilesListWithOptions(filesList, equals, binaries, keepStr, filterStr, path1, path2)
    "----------------------------------------
    " Check all files:
    "----------------------------------------
    let l:filesList = []
    let l:n = 0
    let l:openNum = 0
    let l:equalNum = 0
    let l:binNum = 0
    let l:skipNum = 0
    let l:changesNum = 0
    let l:file2 = ""

    if a:equals != "" && !executable('diff')
        call gitTools#tools#Warn("Warning. diff executable not found. Can't check if files differ!")
    endif

    for l:file1 in a:filesList
        "echom "File1:".l:file1
        "echom "File2:".l:file2
        "
        " Check if file is binary:
        let l:isBinary = 0
        let l:skipFile = 0
        let res = system("file ".l:file1)
        "echom l:file1." ".l:res

        if l:res =~ " cannot open"
            echohl Title
            echo " - File ".l:n.": ".l:file1." (error: cannot open)"
            echohl None
            continue
        elseif l:res =~ " directory"
            continue
        elseif l:res !~ " text" && l:res !~ " link"
            let l:isBinary = 1
        endif

        if !filereadable(l:file1)
            echohl Error
            echo " - File ".l:n.": ".l:file1." (error: not found)"
            echohl None
            continue
        endif

        let l:n += 1

        if a:binaries == "skip" && l:isBinary == 1
            let l:skipFile = 1
            let l:text = ""
        elseif a:binaries == "only" && l:isBinary == 0
            let l:skipFile = 1
            let l:text = "not "
        endif

        if l:skipFile == 1
            echohl DiffText
            echo " - File ".l:n.": ".l:file1." (skip, file is ".l:text."binary)"
            echohl None
            let l:binNum += 1
            continue
        endif

        if a:path2 != ""
            let l:file2  = a:path2
            let l:file2 .= substitute(l:file1, a:path1, "", "")

            if !filereadable(l:file2)
                echohl Error
                echo " - File ".l:n.": ".l:file2." (error: not found)"
                echohl None
                continue
            endif
        endif

        " Check if file must be skipped
        if a:filterStr != ""
            let skip = 0
            for l:filter in split(a:filterStr, '')
                "echom "Check ".l:file1." with filter:-".l:filter
                if l:file1 =~? l:filter
                    echohl Conceal
                    echo " - File ".l:n.": ".l:file1." (skip, matching ".l:filter.")"
                    echohl None
                    let l:skipNum += 1
                    let skip = 1
                    break
                endif
            endfor
            if l:skip == 1 | continue | endif
        endif

        " Check if file must be keeped
        if a:keepStr != ""
            let keep = 0
            for l:filter in split(a:keepStr, ' ')
                "echom "Check ".l:file1." with filter:+".l:filter
                if l:file1 =~? l:filter
                    let l:keep = 1
                    break
                endif
            endfor
            if l:keep == 0
                echohl Conceal
                echo " - File ".l:n.": ".l:file1." (skip, not matching ".l:filter.")"
                echohl None
                let l:skipNum += 1
                continue
            endif
        endif

        if l:file2 != "" && executable('diff')
            " Check if files are equal:
            let l:areEqual = 0
            let l:skipFile = 0
            let l:diffNumTxt = ""

            if system("diff -qa ".l:file1." ".l:file2) == ""
                let l:areEqual = 1
            else
                if executable('wc')
                    let l:diffNum = system("diff --suppress-common-lines --speed-large-files -y ".l:file1." ".l:file2." | wc -l")
                    let l:diffNum = substitute(l:diffNum, '\n', '', 'g')
                    let l:changesNum += str2nr(l:diffNum)
                    let l:diffNumTxt = " ".l:diffNum
                endif
            endif

            if a:equals == "skip" && l:areEqual == 1
                let l:skipFile = 1
                let l:text = ""
            elseif a:equals == "only" && l:areEqual == 0
                let l:skipFile = 1
                let l:text = "not "
            endif

            if l:skipFile == 1
                "echohl Conceal
                "echohl SpecialKey
                echohl DiffChange
                echo " - File ".l:n.": ".l:file1." and ".l:file2." (skip, files are ".l:text."equal)"
                echohl None
                let l:equalNum += 1
                continue
            endif
        endif

        " Found file to be opened.
        let l:filesList += [ l:file1 ]
        let l:openNum += 1
        if l:file2 != ""
            echohl DiffAdd
            echo " - File ".l:n.": ".l:file1." and ".l:file2." (differ".l:diffNumTxt.")"
            echohl None
        else
            echo " - File ".l:n.": ".l:file1
        endif
    endfor

    " Show results:
    echo " "
    echo "Checked: ".l:n." files"
    if a:equals == "skip"
        echon ", ".l:equalNum." are equal"
    endif
    if a:binaries == "skip"
        echon ", ".l:binNum." are binaries"
    endif
    if a:equals == "only"
        echon ", ".l:equalNum." are not equal"
    endif
    if a:binaries == "only"
        echon ", ".l:binNum." are not binaries"
    endif
    if a:keepStr.a:filterStr != ""
        echon ", ".l:skipNum." skipped"
    endif
    echo ""

    echon "Changes: ".l:openNum." files"
    if l:changesNum != ""
        echon ", ".l:changesNum." lines"
    endif
    if l:openNum == 0
        return []
    endif

    call confirm("Continue?")

    let l:handPick = 0
    if a:keepStr.a:filterStr == ""
        if confirm("Pick files manually?", "&yes\n&no", 2) == 1
            let l:handPick = 1
        endif
    endif

    " SHow all files:
    let l:tmpList = []
    let l:n = 1
    for l:file1 in l:filesList
        if l:file2 != ""
            let l:file2 = substitute(l:file1, a:path1, a:path2, "")
            echo " - File ".l:n.": ".l:file1." and ".l:file2
        else
            echo " - File ".l:n.": ".l:file1
        endif

        if l:handPick == 1
            if confirm("Open file?", "&yes\n&no", 2) == 1
                let l:tmpList += [ l:file1 ]
            endif
        endif
        let l:n += 1
    endfor

    if l:handPick == 1
        let l:filesList = l:tmpList
    endif
    return l:filesList
endfunction


