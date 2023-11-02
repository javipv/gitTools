" Script Name: gitTools/blame.vim
 "Description: 
"
" Copyright:   (C) 2017-2021 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: jobs.vim
"
"

"- functions -------------------------------------------------------------------


" Git blame
" Commands: Gitbl.
function! gitTools#blame#Blame(opt)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let file = expand("%")
    let name = expand("%:t")
    let path = expand("%:h")

    let pos = line('.')
    let ext = gitTools#tools#GetSyntax()

    let path = gitTools#tools#GetPathAsFilename(l:path)
    let name = "_gitBlame___".l:path.".".l:ext

    let l:gitCmd  = g:gitTools_gitCmd
    "let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()

    let command  = l:gitCmd." blame ".a:opt." ".l:file
    let callback = ["gitTools#blame#BlameEnd", l:pos, l:ext, l:name]

    call gitTools#tools#WindowSplitMenu(2)

    "let l:resfile = system(l:command)
    call gitTools#tools#SystemCmd(l:command, l:callback, 1)
endfunction


function! gitTools#blame#BlameEnd(pos,ext,name,resfile)
    if exists('a:resfile') && !empty(glob(a:resfile)) 
        " On vertical split synchronize scroll
        if exists('w:split')
            if w:split == 2 | set crb! | endif
        endif

        silent exec("normal zz")
        let l:split = w:split
        let l:winh = winheight(0)
        if l:split == 1 || split == 2
            " synchronize scroll and cursor
            set cursorbind
            set scrollbind
        endif
        call gitTools#tools#WindowSplit()
        put = readfile(a:resfile)
        silent! exec("normal ggdd")

        " Set syntax highlight
        silent exec("set ft=".a:ext)

        " Rename buffer
        silent! exec("0file")
        silent! exec("bd! ".a:name)
        silent! exec("file! ".a:name)
        call gitTools#tools#WindowSplitEnd()

        if l:split == 1 || split == 2
            " synchronize scroll and cursor
            set cursorbind
            set scrollbind

            " Autocommand to reset cursor and scroll sync on buffer exit.
            silent exec("silent! autocmd! BufLeave ".a:name." call s:BlameExit()")
        endif

        " Restore previous position
        silent exec("normal ".a:pos."G")
        silent exec("normal zz")

        if l:split == 1             " Horizontal split:
            " Resize to half original window: 
            silent exe "resize ".l:winh/2
        elseif l:split == 2         " Vertical split:
            " Resize window:
            " Check resize widht: 
            "silent normal 0f)
            silent normal 05W
            let l:width = col('.')+2
            " whant to show on screen.
            let l:winw = winwidth(0)
            if l:winw > l:width
                echom "resize to ".l:width
                silent exe "vertical resize ".l:width
            endif
            silent normal 0
        endif
        redraw
    else
        call gitTools#tools#Warn("Git blame empty")
    endif
endfunction

" Reset cursor and scroll bind on buffer exit.
function! s:BlameExit()
    windo set noscb
    windo set nocrb
endfunction


