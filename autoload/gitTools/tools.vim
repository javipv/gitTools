" Script Name: gitTools.vim
 "Description: 
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: jobs.vim, git
"
" NOTES:
"

"- functions -------------------------------------------------------------------

" Check if the repository is available
" Return: 1 if available otherwhise return 0.
function! gitTools#tools#isGitAvailable()
    let l:desc   = system(g:gitTools_gitCmd." branch")
    "echom "isGitAvailable: ".l:desc

    if l:desc == "" || l:desc =~ "fatal: "
        let l:desc   = substitute(l:desc,'','','g')
        let l:desc   = substitute(l:desc,'\n','','g')
        return l:desc
    else
        return 1
    endif
endfunction


function! gitTools#tools#CheckGitUserAndPsswd()
    if g:gitTools_userAndPsswd != 1
        return ""
    endif

    " Get git user:
    if g:gitTools_gitUser == ""
        let g:gitTools_gitUser = input("Git user: ")
    endif
    if g:gitTools_gitUser == ""
        call gitTools#tools#Error("Not valid git user.")
        return ""
    endif

    " Get git password:
    let l:tmp = ""
    if exists("g:gitTools_tmp")
        if g:gitTools_tmp != ""
            let l:tmp = g:gitTools_tmp
        endif
    endif
    " Set git password:
    if l:tmp == ""
        let l:tmp = inputsecret("Git user: ".g:gitTools_gitUser.". Enter password: ")
        if g:gitTools_storeGitPsswd == 1
            echo ""
            echo ""
            echo "[gitTools.vim] Git password set for current session."
            let g:gitTools_tmp = l:tmp
        endif
    endif
    if l:tmp == ""
        call gitTools#tools#Error("Not valid git password.")
        return ""
    endif

    return " --non-interactive --no-auth-cache --username ".g:gitTools_gitUser." --password ".l:tmp
endfunction


" Set upser and password
" Command: Gitpwd
function! gitTools#tools#SetUserAndPsswd()
    if g:gitTools_gitUser != ""
        if confirm("Change git user: ".g:gitTools_gitUser."?", "&yes\n&no", 2) == 1
            let g:gitTools_gitUser = ""
        endif
        echo ""
        echo ""
    endif
    silent! unlet g:gitTools_tmp
    call gitTools#tools#CheckGitUserAndPsswd()
endfunction


function! gitTools#tools#Error(mssg)
    echohl ErrorMsg | echom "[GitTools] ".a:mssg | echohl None
endfunction


function! gitTools#tools#Warn(mssg)
    echohl WarningMsg | echom a:mssg | echohl None
endfunction

function! gitTools#tools#LowWarn(mssg)
    echohl WarningMsg | echon "WARNING: " | echohl None
    "echon a:mssg
    echo printf("%s\n", a:mssg)
endfunction

function! gitTools#tools#Attention(mssg)
    echohl DiffAdd | echo a:mssg | echohl None
endfunction

function! gitTools#tools#SetLogLevel(level)
    let s:LogLevel = a:level
endfunction


" Debug function. Log message
function! gitTools#tools#LogLevel(level,func,mssg)
    if s:LogLevel >= a:level
        echom "[GitTools : ".a:func."] ".a:mssg
    endif
endfunction


" Debug function. Log message and wait user key
function! gitTools#tools#LogLevelStop(level,func,mssg)
    if s:LogLevel >= a:level
        call input("[GitTools : ".a:func."] ".a:mssg." (press key)")
    endif
endfunction


func! gitTools#tools#Verbose(level)
    if a:level == ""
        call s:LogLevel(0, expand('<sfile>'), "Verbose level: ".s:LogLevel)
        return
    endif
    let s:LogLevel = a:level
    call gitTools#tools#LogLevel(0, expand('<sfile>'), "Set verbose level: ".s:LogLevel)
endfun


function! gitTools#tools#SetSyntax(ext)
    if a:ext == "h"
        let l:ext = "cpp"
    elseif a:ext == "hpp"
        let l:ext = "cpp"
    else
        let l:ext = a:ext
    endif
    "silent exec("set syntax=".l:ext)
    silent exec("set ft=".l:ext)
endfunction


function! gitTools#tools#GetSyntax()
    let l:ext = expand("%:e")
    if l:ext == "h"
        return "cpp"
    elseif l:ext == "hpp"
        return "cpp"
    else
        return l:ext
    endif
endfunction


function! gitTools#tools#WindowSplitMenu(default)
    let w:winSize = winheight(0)
    "echo "w:winSize:".w:winSize | call input("continue")
    let text =  "split hor&izontal\n&split vertical\nnew &tab\ncurrent &window"
    let w:split = confirm("", l:text, a:default)
    redraw
    call gitTools#tools#LogLevel(1, expand('<sfile>'), "Choosed split:".w:split)
endfunction


function! gitTools#tools#WindowSplit()
    if !exists('w:split')
        return
    endif

    let l:split = w:split
    let l:winSize = w:winSize

    call gitTools#tools#LogLevel(1, expand('<sfile>'), "New split:".w:split)

    if w:split == 1
        silent exec("sp! | enew")
    elseif w:split == 2
        silent exec("vnew")
    elseif w:split == 3
        silent exec("tabnew")
    elseif w:split == 4
        silent exec("enew")
    endif

    let w:split = l:split
    let w:winSize = l:winSize
endfunction


function! gitTools#tools#WindowSplitEnd()
    if exists('w:split')
        if w:split == 1
            if exists('w:winSize')
                "echo "w:winSize:".w:winSize | call input("continue")
                let lines = line('$') + 2
                if l:lines <= w:winSize
                    "echo "resize:".l:lines | call input("continue")
                    exe "resize ".l:lines + 2
                else
                    "echo "resize:".w:winSize | call input("continue")
                    exe "resize ".w:winSize
                endif
            endif
            exe "normal! gg"
        endif
    endif
    silent! unlet w:winSize
    silent! unlet w:split
endfunction


function! gitTools#tools#WindowSplitType(type)
    call gitTools#tools#WindowSplitMenu(a:type)
    call gitTools#tools#WindowSplit()
    call gitTools#tools#WindowSplitEnd()
endfunction


"function! gitTools#tools#PathToFile(path)
    "return gitTools#tools#GetPathAsFilename(a:path)
"endfunction

" Turn a path to a filename showing the path and file.
" Return: for input /dir1/dir2/dir3/filename.ext return dir1_dir2_dir3_filename.ext
function! gitTools#tools#GetPathAsFilename(path)
    if a:path == ""
        return ""
    endif
    let path = a:path
    let path = substitute(path, getcwd(), '', 'g')
    let path = substitute(path, '/', '_', 'g')
    let path = substitute(path, '-$', '', '')
    let path = substitute(path, '_-', '', '')
    let path = substitute(path, '-_', '', '')
    return l:path
endfunction


function! gitTools#tools#SystemCmd(command,callbackList,async)
    "if !exists("g:loaded_jobs")
    if !exists("g:VimJobsLoaded")
        call gitTools#tools#Error("Plugin jobs.vim not loaded.")
        return
    endif

    let jobName = "gitTools"

    if g:gitTools_runInBackground == 0 || a:async == 0
        let l:async = 0
    else
        let l:async = 1
    endif
    
    " Do not add command with user password from history
    if g:gitTools_userAndPsswd != 1
        let cmd = "let @a = \"".a:command."\" \| normal G! \| exec(\"put a\")"
        call histadd(':', l:cmd)
    endif
    call jobs#RunCmd0(a:command,a:callbackList,l:async,l:jobName)

endfunction


" Remove leading and trailing spaces.
" Remove end of line characters.
" Return: string without leading trailing white spaces.
func! gitTools#tools#TrimString(string)
    let l:tmp = a:string
    let l:tmp = substitute(l:tmp,'^\s\+','','g')
    let l:tmp = substitute(l:tmp,'\s\+$','','g')
    let l:tmp = substitute(l:tmp,'','','g')
    let l:tmp = substitute(l:tmp,'\n','','g')
    return l:tmp
endfunc


" Enclose the given lines on list on a rectangle.
" Arg1: linesList, list with every line to be enclosed inside the rectangle.
" Arg2: rectangleType, bold, hashtag, equals, normal.
"       Bold:    ┏━━━━━━━┓
"                ┃       ┃
"                ┗━━━━━━━┛
"       Hashtag: #########
"                #       #
"                #########
"       Equals:  =========
"                ||     ||
"                =========
"       Normal:  ┌───────┐
"                │       │
"                └───────┘
" Arg3: [OPTIONAL] len, force minimum rectangle length to this value.
" Return: string with the text enclosed on rectangle.
function! gitTools#tools#EncloseOnRectangle(linesList,rectangleType,len)
    if a:rectangleType == "bold"
        let l:cornerTL='┏' | let l:cornerTR='┓' | let l:vertical='┃' | let l:horizontal='━' | let l:cornerBL='┗' | let l:cornerBR='┛'
    elseif a:rectangleType == "hashtag"
        let l:cornerTL='#' | let l:cornerTR='#' | let l:vertical='#' | let l:horizontal='#' | let l:cornerBL='#' | let l:cornerBR='#'
    elseif a:rectangleType == "equals"
        let l:cornerTL='=' | let l:cornerTR='=' | let l:vertical='||' | let l:horizontal='=' | let l:cornerBL='=' | let l:cornerBR='='
    else
        let l:cornerTL="┌" | let l:cornerTR="┐" | let l:vertical="│" | let l:horizontal='─' | let l:cornerBL='└' | let l:cornerBR='┘'
    endif

    if a:len != ""
        let maxlen = a:len
    else
        let maxlen = 0
        for line in a:linesList
            let len = strlen(l:line)
            if l:len > l:maxlen | let l:maxlen = l:len | endif
        endfor
    endif

    let config  = l:cornerTL
    let config .= repeat(l:horizontal,l:maxlen)
    let config .= l:cornerTR."\n"

    for line in a:linesList
        let config .= l:vertical.l:line
        let len = l:maxlen - strlen(l:line)
        let config .= repeat(' ', l:len)
        let config .= l:vertical."\n"
    endfor

    let config .= l:cornerBL
    let config .= repeat(l:horizontal,l:maxlen)
    let config .= l:cornerBR."\n"

    return l:config
endfunction




"- initializations ------------------------------------------------------------

let s:LogLevel = 0

