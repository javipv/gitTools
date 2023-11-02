" Script Name: gitTools/generic.vim
" Description: launch any git command and open result on new window/split window or tab.
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: Jobs.vim
"
"

"- functions -------------------------------------------------------------------


" Launch a git command and show the command answer on new window/split/tab.
" Name: Command name to use on the window name as _DATE_gitNAME_ARGS.
" Split: default window split (1:split, 2:vertical split, 3: new tab, 4:curren window).
" Args: space separated git command arguments (--tags ...).
" Return: 0 on success, 1 otherwise.
function! gitTools#generic#Command(name, split, command, args)
    let args = "_".a:args
    silent! let args = substitute(l:args, '-', '', 'g')
    silent! let args = substitute(l:args, ' ', '_', 'g')

    let cmd = g:gitTools_gitCmd." ".a:command ".a:args
    redraw
    echo l:cmd
    call gitTools#tools#WindowSplitMenu(a:split)

    let text = system(l:cmd)

    if l:text =~ "fatal: not a git repository"
        let l:desc   = substitute(l:text,'','','g')
        let l:desc   = substitute(l:text,'\n','','g')
        call gitTools#tools#Error("ERROR: git branch. ".l:desc)
        return 1
    endif

    if l:text == "" 
        call gitTools#tools#Error("ERROR: git ".a:name." Empty result")
        return 1
    endif

    redraw
    call gitTools#tools#WindowSplit()
    call gitTools#tools#WindowSplitEnd()

    " Open result file
    "silent exec "edit ".a:output
    silent put = l:text
    normal ggdd

    "echom "Lines1: '".getline(".")."' Lines:".line("$")
    if getline(".") == "" && line("$") == 1
        quit
        redraw
        call gitTools#tools#Warn("Empty")
        return 1
    endif

    redraw
    echo "[gitTools.vim] Found ".line("$")." rev-list"

    " Rename buffer
    let l:date = strftime("%y%m%d_%H%M")
    let l:name = "_".l:date."_git".a:name.l:args

    silent! exec("0file")
    silent! exec("bd! ".l:name)
    silent! exec("file! ".l:name)

    " Add header
    let l:list = [ " [gitTools.vim] ".l:cmd." " ]
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
    return 0
endfunction


" Launch a git command on background and show the command answer on new window/split/tab.
" Name: Command name to use on the window name as _DATE_gitNAME_ARGS.
" Split: default window split (1:split, 2:vertical split, 3: new tab, 4:curren window).
" Args: space separated git command arguments (--tags ...).
" Return: 0 on success, 1 otherwise.
function! gitTools#generic#CommandBg(name, split, command, args)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return 1
    endif

    let args = "_".a:args
    silent! let args = substitute(l:args, '-', '', 'g')
    silent! let args = substitute(l:args, ' ', '_', 'g')

    let l:date = strftime("%y%m%d_%H%M")
    let l:name = "_".l:date."_git".a:name.l:args

    let command  = g:gitTools_gitCmd." ".a:command." ".a:args
    let callback = ["gitTools#generic#CommandBgEnd", l:name, l:command]

    echo l:command
    call gitTools#tools#WindowSplitMenu(a:split)
    call gitTools#tools#SystemCmd(l:command, l:callback, 1)
endfunction


function! gitTools#generic#CommandBgEnd(name, cmd, resfile)
    if !exists('a:resfile')
        call gitTools#tools#Warn("[gitTools.vim] '".a:cmd."' ERROR result not found")
        return 1
    endif

    if empty(glob(a:resfile)) 
        call gitTools#tools#Warn("[gitTools.vim] '".a:cmd."' ERROR empty result file")
        return 1
    endif

    let fileList = readfile(a:resfile)

    if len(l:fileList) >= 1
        if len(l:fileList) > 0 && l:fileList[0]  =~ "fatal: not a git repository"
            if l:fileList[0]  =~ "fatal: not a git repository"
                redraw
                call gitTools#tools#Error("[gitTools.vim] '".a:cmd."' ERROR: not a git repository")
                return 1
            endif
        endif
    endif

    redraw
    call gitTools#tools#WindowSplit()

    " Open result file
    silent exec "edit ".a:resfile

    "echom "Lines1: '".getline(".")."' Lines:".line("$")
    if getline(".") == "" && line("$") == 1
        silent! quit
        call gitTools#tools#Warn("[gitTools.vim] '".a:cmd."' empty result")
        return 1
    endif

    " Rename buffer
    silent! exec("0file")
    silent! exec("bd! ".a:name)
    silent! exec("file! ".a:name)
    silent! call delete(a:resfile)

    " Add header
    let l:list = [ " [gitTools.vim] ".a:cmd." " ]
    let l:header = gitTools#tools#EncloseOnRectangle(l:list, "bold", "")
    normal gg
    silent put=l:header
    normal ggdd3jp

    call gitTools#tools#WindowSplitEnd()
    redraw

    " Set buffer parameters
    setl noswapfile
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    setl nonu
    return 0
endfunction

