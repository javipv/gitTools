" Script Name: gitTools/diffFile.vim
 "Description: 
"
" Copyright:   (C) 2017-2021 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: 
"


"- functions -------------------------------------------------------------------


" When placed on a diff file, for each modified file, get its name and filepath.
" Return: list containing all modified file paths.
function! gitTools#diffFile#GetModifiedFilesList()
    let list = []

    let @z=""
    silent g/^Index: /y Z
    silent new
    silent put=@Z
    silent! %s/^$//g
    silent %s/Index: //g

    if line('$') == 1 && getline(".") == ""
        " Empty file
    else
        let @z=""
        silent normal ggVG"zy
        let files = @z
        let list = split(l:files, "\n")
    endif

    quit
    return l:list
endfunction




" When placed on a diff file. Extract all modified file names and path.
" Perform vimdiff on this files for revision2 with the same files on revision1
" When no revision number provided as argument, try get word under cursor as the
" revision number.
" When REV2 not provided set REV2=REV1, and dreacrese REV1.
" Arg1: [optional] revision1
" Arg2: [optional] revision2
" Cmd: GitDiffVdr
function! gitTools#diffFile#OpenVimDiffGetFilesAndRevisionsEveryIndexLine(...)
    if &filetype !=# 'diff'
      call gitTools#tools#Warn("Attention, file type is not diff!")
      call input("")
    endif

    let rev1 = ""
    let rev2 = ""

    if a:0 >= 2
        let rev1 = a:1
        let rev2 = a:2
    elseif a:0 == 1
        let rev2 = a:1
    else
        let rev2 = expand("<cword>")
    endif

    if l:rev2 == ""
        call gitTools#tools#Error("Missing revision number")
        return
    endif

    let rev2 = substitute(l:rev2, '[^0-9]*', '', 'g')
    if l:rev2 == ""
        call gitTools#tools#Error("Wrong revision number ". l:rev2)
        return
    endif

    if l:rev1 == ""
        let l:rev1 = l:rev2 -1
    else
        let rev1 = substitute(l:rev1, '[^0-9]*', '', 'g')
        if l:rev1 == ""
            call gitTools#tools#Error("Wrong revision number ". l:rev1)
            return
        endif
    endif

    " Save window position
    let l:winview = winsaveview()

    " Extract from diff file, the list of modified files.
    let l:list = gitTools#diffFile#GetModifiedFilesList()

    " Restore window position
    call winrestview(l:winview)
  
    redraw
    for file in l:list
        echo l:file
    endfor
    call confirm(len(l:list) ." modified files found. Continue?")

    " Perform vimdiff for each file and revision.
    redraw
    echo "Opening ". l:rev1 .":". l:rev2 ."modifications with vimdiff:"
    for file in l:list
        echo "- ". l:file
        silent call gitTools#diffTools#VimDiffFileRev(l:file, l:rev1, l:rev2, 0)
        setl nomodifiable
    endfor
endfunction




" When placed on a log diff file (exmple: _r29456.diff)
" Extract all files modified and perform vimdiff from the revision
" Cmd: Gitdvdr
function! gitTools#diffFile#OpenVimDiffOnEachFileAndRevision()
    if expand("%") !~ "_r[1-9].*\.diff"
        echo "First launch commands: Gitr, to get the revision diff."
        call gitTools#tools#Warn("Current file is not an git diff file!")
        call confirm("Go ahead with current file?")
        "return
    endif

    " Extract from log file, the revision number.
    let l:list = gitTools#log#GitLogFileGetCommitNumberList()
    if len(l:list) != 1
        call gitTools#tools#Error("Could't find the revision number!")
        return
    endif
    let l:rev = substitute(l:list[0], '[^0-9]*', '', 'g')
    let rev2 = str2nr(l:rev)
    let rev1 = l:rev2 - 1

    " Extract from diff file, the list of modified files.
    let l:list = gitTools#diffFile#GetModifiedFilesList()
  
    redraw
    echo "Files modified: "
    for file in l:list
        echo "  ".l:file
    endfor
    echo "Number of files modified: ".len(l:list)
    call confirm("Perform vimdiff on each file for between revision: ".l:rev1." and".l:rev2.". Continue?")

    " Perform vimdiff for each file and revision.
    redraw
    echo "Opening ". l:rev1 .":". l:rev2 ." modifications with vimdiff:"
    for file in l:list
        echo "- ". l:file
        silent call gitTools#diffTools#VimDiffFileRev(l:file, l:rev1, l:rev2, 0)
    endfor
endfunction


" When placed on a diff file. Extract all lines staring with words:'+++ ' and
" retrieve the file path an revision number.
" Perform vimdiff on this files for the selected revision.
" Cmd: GitDiffVdr
function! gitTools#diffFile#OpenVimDiffOnAllFiles(...)
    let l:file = expand("%")
    let fileDelete = ""

    if empty(glob(l:file))
        " Buffer not saved on file, dump content to a new tmp file
        let file = tempname()
        let fileDelete = l:file
        silent exec(":w! ".l:file)
    endif

    " Parse the config file
    redir! > readfile.out
    let l:file = readfile(l:file)
    let l:all = 0
    for l:line in l:file
        if l:line[0:3] == "+++ "
            let l:list = split(l:line)
            let l:fileList += [ l:list[1] ]
            let l:fileRevList += [ l:list[1]." ".l:list[2] ]
            let l:linesList += [ l:lline ]
        endif
    endfor
    redir END

    " Clean tmp file used for searching on buffers not saved
    if l:fileDelete != "" | call delete(l:fileDelete) | endif

    for l:file in l:fileRevList
        echo l:file
    endfor

    echo ""
    if confirm("Perform vimdiff all files? ", "&yes\n&no") == 2
        let l:n = 0
        for l:file in l:fileRevList
            echo l:file
            if confirm("Vimdiff file: ".l:file, "&yes\n&no") == 2
                let l:linesList[l:n] = ""
            endif
            let l:n += 1
        endfor
    endif

    for l:line in l:linesList
        if l:line[0:3] == "+++ "
            if l:line =~ "(working copy)"
                let l:list = split(l:line)
                let l:file = l:list[1]
                call gitTools#vimdiff#File(l:file)
            else
                call gitTools#diffFile#OpenVimDiffGetFileAndRevisionFromCurrentLine()
            endif
        endif
    endfor
endfunction


" When placed on a diff file. Extract current line modified file name and path.
" Perform vimdiff on this files for revision2 with the same files on revision1
" When no revision number provided as argument, try get the revision from (revision xxxxxx) at line end.
" revision number.
" When REV2 not provided set REV2=REV1, and dreacrese REV1.
" Arg1: [optional] revision1
" Arg2: [optional] revision2
" Cmd: GitDiffVdrf
function! gitTools#diffFile#OpenVimDiffGetFileAndRevisionFromCurrentLine(...)
    if &filetype !=# 'diff'
      call gitTools#tools#Warn("Attention, file type is not diff! (Press key to continue)")
    endif

    let rev1 = ""
    let rev2 = ""
    let file = ""

    if a:0 >= 3
        let file = a:3
    endif
    if a:0 >= 2
        let rev1 = a:1
        let rev2 = a:2
    elseif a:0 == 1
        let rev2 = a:1
    else
        " Verify current line type.
        normal $bbviW"zy
        let l:check = @z
        if l:check != "(revision"
            call gitTools#tools#Error("Verify cursor line position. Place on line ending with: '(revision xxxx)'.")
            return
        endif
        " Extract revision number
        normal $bviw"zy
        let l:rev2 = @z
    endif

    if l:rev2 == ""
        call gitTools#tools#Error("Missing revision number")
        return
    endif

    let rev2 = substitute(l:rev2, '[^0-9]*', '', 'g')
    if l:rev2 == ""
        call gitTools#tools#Error("Wrong revision number ". l:rev2)
        return
    endif

    if l:rev1 == ""
        let l:rev1 = l:rev2 -1
    else
        let rev1 = substitute(l:rev1, '[^0-9]*', '', 'g')
        if l:rev1 == ""
            call gitTools#tools#Error("Wrong revision number ". l:rev1)
            return
        endif
    endif

    if file == ""
        " Get file path from current line.
        " Save window position
        let l:winview = winsaveview()

        " Verify current line type.
        normal 0lllvl"zy
        let l:tag0 = @z

        normal 0viW"zy
        let l:tag1 = @z

        if l:tag0 =~ "[A-Z] "
            " Log line with path
            normal 0wwviW"zy
            let l:file = @z
        elseif l:tag1 == "Index:" || l:tag1 == "---" || l:tag1 == "+++"
            " Diff line with path
            normal 0wviW"zy
            let l:file = @z
        else
            echo "Place cursor on diff line starting with: 'Index: PATH', '--- PATH', '+++ PATH'."
            echo "Place cursor on log changed path line starting with: '   [A-Z] PATH'."
            call gitTools#tools#Error("Line format error. Verify cursor line position.")
            return
        endif

        " Restore window position
        call winrestview(l:winview)
    endif

    " Extract from diff file, the file name and path.
    if l:file == ""
        call gitTools#tools#Error("File path not found on current file. Check cursor line position")
        return
    endif

    "call confirm("Vimdiff file: ". l:file ." rev: ". l:rev1 .":". l:rev2)
    if confirm("Vimdiff file: ". l:file ." rev: ". l:rev1 .":". l:rev2, "&yes\n&no") != 1
        return
    endif
  
    " Perform vimdiff for file and revision.
     redraw
    echo "Opening ". l:file ." ". l:rev1 .":". l:rev2 ." with vimdiff..."
    silent call gitTools#diffTools#VimDiffFileRev(l:file, l:rev1, l:rev2, 0)
    setl nomodifiable
endfunction


