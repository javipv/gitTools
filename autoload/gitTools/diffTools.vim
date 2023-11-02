
" Perform diff between same files on different directories/sandboxes
" Arg1: file to check on both paths
" Arg2: sandbox 1 path
" Arg3: sandbox 2 path
function! gitTools#diffTools#DiffFiles(file,path1,path2)
    let l:file1 = a:path1."/".a:file
    let l:file2 = a:path2."/".a:file
    return system("diff -ua ".l:file1." ".l:file2)
endfunction


" Perform vimdiff between same files on different directories/sandboxes
" Arg: list with all files to compare
function! gitTools#diffTools#VimDiffFilePathsList(pathsList, filesList, setNoModifiable)
    let l:ext = fnamemodify(a:filesList[0], ":e")

    for fileName in a:filesList
        "echo "fileName: ".l:fileName
        tabnew
        let l:n = 0

        for path in a:pathsList
            "echo "Path: ".l:path
            let l:file = l:path."/".l:fileName
            "echo "File: ".l:file
            if l:n == 0
                " Open first file
                if !filereadable(l:file)
                    call gitTools#tools#Warn("File not found:".l:file)
                    "silent exec("new ".l:file)
                else
                    silent exec("e ".l:file)
                endif
            else
                if !filereadable(l:file)
                    call gitTools#tools#Warn("File not found:".l:file)
                    silent exec("vert new".l:file) 
                else
                    silent exec("vert new") 
                    silent exec("e ".l:file)
                endif
            endif

            call gitTools#tools#SetSyntax(l:ext)

            " Visually show tabs and spaces
            silent exec("set invlist")
            silent exec("set listchars=tab:>.,trail:_,extends:\#,nbsp:_")
            let l:n += 1

            if a:setNoModifiable == 1
                setl nomodifiable
                setl buflisted
                setl bufhidden=delete
                setl buftype=nofile
            endif
        endfor

        silent exec("windo diffthis")

        highlight DiffText   cterm=BOLD ctermfg=Red ctermbg=DarkGrey  
    endfor
endfunction


" Perform vimdiff between same files on different directories/sandboxes
" Arg1: sandbox 1 path
" Arg2: sandbox 2 path
function! gitTools#diffTools#VimDiffFilePaths(file1,file2)
    let l:isModifiable = 1
    call gitTools#diffTools#VimDiffFilePaths_setModifiable(a:file1, a:file2, l:isModifiable, l:isModifiable)
endfunction


" Perform vimdiff between same files on different directories/sandboxes
" Arg1: sandbox 1 path
" Arg2: sandbox 2 path
function! gitTools#diffTools#VimDiffFilePaths_setModifiable(file1,file2,isModifiable1,isModifiable2)
    let l:ext   = fnamemodify(a:file1, ":e")

    let l:file1 = a:file1
    let l:file2 = a:file2

    "Open new tab
    tabnew

    " Open file1
    if !filereadable(l:file1)
        call gitTools#tools#Warn("File not found:".l:file1)
        silent exec("new ".l:file1)
    else
        silent exec("e ".l:file1)
    endif
    call gitTools#tools#SetSyntax(l:ext)
    if a:isModifiable1 == 1
        silent exec("set modifiable")
    else
        silent exec("set nomodifiable")
    endif
    silent exec("diffthis") 

    " Visually show tabs and spaces
    silent exec("set invlist")
    silent exec("set listchars=tab:>.,trail:_,extends:\#,nbsp:_")

    " Open file2
    " New vertical split
    if !filereadable(l:file2)
        call gitTools#tools#Warn("File not found:".l:file2)
        silent exec("vert new".l:file2) 
    else
        silent exec("vert new") 
        silent exec("e ".l:file2)
    endif
    silent exec("diffthis")
    call gitTools#tools#SetSyntax(l:ext)
    if a:isModifiable2 == 1
        silent exec("set modifiable")
    else
        silent exec("set nomodifiable")
    endif

    " Visually show tabs and spaces
    silent exec("set invlist")
    silent exec("set listchars=tab:>.,trail:_,extends:\#,nbsp:_")

    highlight DiffText   cterm=BOLD ctermfg=Red ctermbg=DarkGrey  
endfunction


" Perform vimdiff between same files on different directories/sandboxes
" Arg1: file to check on both paths
" Arg2: sandbox 1 path
" Arg3: sandbox 2 path
function! gitTools#diffTools#VimDiffFiles(file,path1,path2)
    let l:ext   = fnamemodify(a:file, ":e")

    let l:file1 = a:path1."/".a:file
    let l:file2 = a:path2."/".a:file

    "call s:VimDiffFilePaths(file1,file2)
    call gitTools#diffTools#VimDiffFilePaths(file1,file2)
    return

    "Open new tab
    tabnew

    " Open file1
    if !filereadable(l:file1)
        call gitTools#tools#Warn("File not found:".l:file1)
        silent exec("new ".l:file1)
    else
        silent exec("e ".l:file1)
    endif
    call gitTools#tools#SetSyntax(l:ext)
    silent exec("diffthis") 

    " Visually show tabs and spaces
    silent exec("set invlist")
    silent exec("set listchars=tab:>.,trail:_,extends:\#,nbsp:_")

    " Open file2
    " New vertical split
    if !filereadable(l:file2)
        call gitTools#tools#Warn("File not found:".l:file2)
        silent exec("vert new".l:file2) 
    else
        silent exec("vert new") 
        silent exec("e ".l:file2)
    endif
    silent exec("diffthis")
    call gitTools#tools#SetSyntax(l:ext)

    " Visually show tabs and spaces
    silent exec("set invlist")
    silent exec("set listchars=tab:>.,trail:_,extends:\#,nbsp:_")

    highlight DiffText   cterm=BOLD ctermfg=Red ctermbg=DarkGrey  
endfunction


" Perform vimdiff between two revisions or last git revision and current one.
" Arg1: rev0 to download from git and compare, if empty use last revision.
" Arg2: rev1 to download from git and compare, if empty use current file on disk
" Arg3: directory to save git file into.
function! gitTools#diffTools#VimDiffFileRev(file,branch,rev0,rev1,saveDir)
    "Open new tab
    tabnew

    let path = fnamemodify(a:file,":p:h")
    let name = fnamemodify(a:file,":t:r")
    let ext  = fnamemodify(a:file,":e")
    let nameExt = fnamemodify(a:file,":t")
    let file = a:file

    " Remove working directory from path
    let path1 = substitute(l:path, getcwd(), '', 'g')
    " Replace each / with _
    let path1 = substitute(l:path1, '/', '_', 'g')
    " Replace duplicated _
    let path1 = substitute(l:path1, "__", "_", "")

    let l:rev0 = ""
    let l:rev1 = ""

    if a:rev0 != ""
        let l:rev0 = "-r ".a:rev0." "
    endif

    if a:rev1 != ""
        let l:rev1 = "-r ".a:rev1." "
    endif

    " Get original file
    echo "This may take a while ..."
    if a:saveDir != ""
        let l:tmp = a:saveDir."/".l:path1."_".l:name."_r".a:rev0.".".l:ext
    else
        let l:tmp = l:path1."_".l:name."_r".a:rev0.".".l:ext
    endif

    if !filereadable(l:tmp)
        let l:gitCmd  = g:gitTools_gitCmd
        let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()

        echo "git cat ".l:rev0.a:file
        silent exec("r !".l:gitCmd." show ".a:branch.":".a:file)

        silent exec("0file")
        silent! exec("file ".l:tmp)
        setl nomodifiable
        setl buflisted
        setl bufhidden=delete
        setl buftype=nofile

        if a:saveDir != ""
            echo "Save ".l:tmp
            silent! exec("w! ".l:tmp)
        endif
    else
        echo "File1 found:".l:tmp
        silent exec("e ".l:tmp)
    endif
    call gitTools#tools#SetSyntax(l:ext)


    " Visually show tabs and spaces
    silent exec("set invlist")
    silent exec("set listchars=tab:>.,trail:_,extends:\#,nbsp:_")

    if a:rev1 != ""
        if a:saveDir != ""
            let l:tmp = a:saveDir."/".l:path1."_".l:name."_r".a:rev1.".".l:ext
        else
            let l:tmp = l:path1."_".l:name."_r".a:rev1.".".l:ext
        endif

        " Perform vertical vimdiff on two selected revisions of the file
        " Make this window part of the diff
        silent exec("diffthis") 

        " New vertical split
        silent exec("vert new") 

        " Resize
        "silent exec("resize ".l:neWidth)

        if !filereadable(l:tmp)
            let l:gitCmd  = g:gitTools_gitCmd
            let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()

            echo "git cat ".l:rev1.a:file
            silent exec "edit ".a:file

            silent exec("0file")
            silent! exec("file ".l:tmp)

            if a:saveDir != ""
                silent! exec("w! ".l:tmp)
            endif
        else
            echo "File2 found:".l:tmp
            silent exec("e ".l:tmp)
        endif

        silent exec("diffthis")
        call gitTools#tools#SetSyntax(l:ext)
    else
        " Perform vertical vimdiff between selected revision and current one.
        " WindowSplitMenu tab in a vimdiff manner
        silent exec("vert diffsplit ".l:file)
    endif

    call gitTools#tools#SetSyntax(l:ext)

    highlight DiffText   cterm=BOLD ctermfg=Red ctermbg=DarkGrey  
endfunction


" Perform vimdiff of file between two git branches.
" Arg1: file, file on curren tbranch to compare.
" Arg2: branch, branch to compare thie files with current one.
function! gitTools#diffTools#VimDiffFileBranch(file,branch)
    tabnew

    let path = fnamemodify(a:file,":p:h")
    let name = fnamemodify(a:file,":t:r")
    let ext  = fnamemodify(a:file,":e")
    let nameExt = fnamemodify(a:file,":t")
    let file = a:file

    " Remove working directory from path
    let path1 = substitute(l:path, getcwd(), '', 'g')
    " Replace each / with _
    let path1 = substitute(l:path1, '/', '_', 'g')
    " Replace duplicated _
    let path1 = substitute(l:path1, "__", "_", "")

    " Get the branch file:
    let l:gitCmd  = g:gitTools_gitCmd
    let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()

    echo "git show "a:branch.":".a:file
    silent exec("r !".l:gitCmd." show ".a:branch.":".a:file)
    silent normal ggdd

    let l:tmpFileName = "_branch:".a:branch."_".l:path1."_".l:name.".".l:ext
    silent exec("0file")
    silent! exec("file ".l:tmpFileName)
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    call gitTools#tools#SetSyntax(l:ext)

    " Perform vertical vimdiff between selected revision and current one.
    silent exec("vert diffsplit ".l:file)
    call gitTools#tools#SetSyntax(l:ext)
    highlight DiffText   cterm=BOLD ctermfg=Red ctermbg=DarkGrey  

    " Resize the right window:
    if g:gitTools_vimdiffWinWidthMultiplyValue <= 0 || g:gitTools_vimdiffWinWidthMultiplyValue >= 2
        call gitTools#tools#Error("Wrong variable g:gitTools_vimdiffWinWidthMultiplyValue must be lower than 2 and greater than 0.")
    else
        let l:newwidth = winwidth(0) * g:gitTools_vimdiffWinWidthMultiplyValue
        let l:newwidth = round(l:newwidth)
        let l:newwidth = string(l:newwidth)
        silent exec("vertical resize ".l:newwidth)
    endif
endfunction



" Perform vimdiff of file between current filea and
" Arg1: file, file on current branch to compare.
" Arg2: branch, branch to compare thie files with current one.
function! gitTools#diffTools#VimDiffThisFileBranch(file,branch)
    vertical new
    wincmd H

    let path = fnamemodify(a:file,":p:h")
    let name = fnamemodify(a:file,":t:r")
    let ext  = fnamemodify(a:file,":e")
    let nameExt = fnamemodify(a:file,":t")
    let file = a:file

    " Remove working directory from path
    let path1 = substitute(l:path, getcwd(), '', 'g')
    " Replace each / with _
    let path1 = substitute(l:path1, '/', '_', 'g')
    " Replace duplicated _
    let path1 = substitute(l:path1, "__", "_", "")

    " Get the branch file:
    let l:gitCmd  = g:gitTools_gitCmd
    let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()

    echo "git show "a:branch.":".a:file
    silent exec("r !".l:gitCmd." show ".a:branch.":".a:file)
    silent normal ggdd

    let l:tmpFileName = "_branch:".a:branch."_".l:path1."_".l:name.".".l:ext
    silent exec("0file")
    silent! exec("file ".l:tmpFileName)
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    call gitTools#tools#SetSyntax(l:ext)

    " Perform vertical vimdiff between selected revision and current one.
    diffthis
    wincmd l
    diffthis
    call gitTools#tools#SetSyntax(l:ext)
    highlight DiffText   cterm=BOLD ctermfg=Red ctermbg=DarkGrey  

    " Resize the right window:
    if g:gitTools_vimdiffWinWidthMultiplyValue <= 0 || g:gitTools_vimdiffWinWidthMultiplyValue >= 2
        call gitTools#tools#Error("Wrong variable g:gitTools_vimdiffWinWidthMultiplyValue must be lower than 2 and greater than 0.")
    else
        let l:newwidth = winwidth(0) * g:gitTools_vimdiffWinWidthMultiplyValue
        let l:newwidth = round(l:newwidth)
        let l:newwidth = string(l:newwidth)
        silent exec("vertical resize ".l:newwidth)
    endif
endfunction
