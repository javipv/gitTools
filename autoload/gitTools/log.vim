" Script Name: gitTools/log.vim
 "Description: 
"
" Copyright:   (C) 2017-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: jobs.vim
"
"

"- functions -------------------------------------------------------------------


" Get the git log history for the selected path.
" Args: path or options ex: -v, --verbose -p -10. 
" Commands: Gitl, Gitlp
function! gitTools#log#GetHistory(...)
    let l:options = ""
    let l:optionNames = ""
    let l:filepath = ""

    if len(a:000) != 0
        for l:arg in a:000
            if filereadable(l:arg)
                "echom "Path:".l:arg
                let l:filepath = substitute(l:arg, getcwd(), "", "g")
            else
                "echom "Option:".l:arg
                let l:options .= l:arg." "
                let l:arg = substitute(l:arg, "-", "", "g")
                let l:arg = substitute(l:arg, " ", "_", "g")

                if l:optionNames == ""
                    let l:optionNames = "_"
                endif
                let l:optionNames .= l:arg
            endif
        endfor
    endif

    if l:filepath != ""
        let l:filepath = expand("%")
    endif
    "echom "Use path: ".l:filepath
    "echom "Options: ".l:optionNames

    let pathName = substitute(l:filepath, "\/", "_", "g")

    let l:gitCmd  = g:gitTools_gitCmd
    let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()

    let l:date = strftime("%y%m%d_%H%M")
    let l:branch = gitTools#branch#Current()

    let name     = "_".l:date."_gitLog".l:optionNames."___".l:branch.l:pathName.".log"
    let command  = l:gitCmd." log ". l:options . l:filepath
    let callback = ["gitTools#log#GitLogFileEnd", l:name, l:command]

    echo l:command
    call gitTools#tools#WindowSplitMenu(4)

    call gitTools#tools#SystemCmd(l:command, l:callback, 1)
endfunction

function! gitTools#log#GitLogFileEnd(name, cmd, resfile)
    if !exists('a:resfile') || empty(glob(a:resfile)) 
        call gitTools#tools#Warn("Git log search empty")
        return
    endif

    let fileList = readfile(a:resfile)

    if l:fileList[0]  =~ "fatal: not a git repository"
        call gitTools#tools#Error("ERROR: not a git repository")
        return
    endif

    call gitTools#tools#WindowSplit()

    " Rename buffer
    silent! exec("0file")
    silent! exec("bd! ".a:name)
    silent! exec("file! ".a:name)

    " Add header
    let l:textList = [ " [gitTools.vim] ".a:cmd ]
    let l:header = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
    silent put=l:header

    " Add the log info
    silent put =  readfile(a:resfile)
    normal ggdd

    call delete(a:resfile)
    call gitTools#tools#WindowSplitEnd()
    redraw
    set ft=diff

    call s:SetSyntaxAndHighlighting("")

    " Set buffer parameters
    setl noswapfile
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    setl nonu
endfunction


" When placed on a git log file, get each commit number.
" Return: list containing all commit numbers.
function! gitTools#log#GitLogFileGetCommitNumberList()
    let list = []

    let @z=""
    silent g/^r.*\|.*(.*).*lines/y Z
    silent new
    silent put=@Z
    silent! g/^$/d
    silent! %s/ |.*$//g
    "silent bd!

    if line('$') == 1 && getline(".") == ""
        " Empty file
    else
        let @z=""
        silent normal ggVG"zy
        let revNum = @z
        let list = split(l:revNum, "\n")
    endif

    quit
    return l:list
endfunction


" Get git log and git diff from the given revision number.
" Arg1: rev. Revision number: r34567 or 34567.
" Arg2: mode. Use new_tab to open each revison on new tab.
function! s:GitLogFileGetRevisionDiff(rev, mode)
    let l:rev = substitute(a:rev, '[^0-9]*', '', 'g')
    let prev = l:rev - 1
    let name = "_r".l:rev.".diff"

    let l:gitCmd  = g:gitTools_gitCmd
    let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()

    let command  = l:gitCmd." log -vr ".l:rev." --diff" 
    "let command  = "git log -vr ".l:rev." --diff" 
    let text = system(l:command)

    if l:text == "" 
        echo "Failed"
        return 1
    endif

    if a:mode == "new_tab"
        silent tabnew
        normal ggO
        silent put=l:text
        normal ggdd

        " Rename buffer
        silent! exec("0file")
        silent! exec("bd! ".l:name)
        silent! exec("file! ".l:name)

        silent exec("set syntax=diff")
        silent exec("normal gg")
    else
        normal GO
        silent put=l:text
    endif
endfunction


" When placed on the git log file open all revisions.
" Commands: Gitlr
" PENDING: adapt for git
function! gitTools#log#GetRevDiff(num)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    if expand("%") !~ "_gitLog_.*\.log"
        echo "First launch one of following commands: Gitl, Gitls, Gitlf, Gitld or Gitlp, to get the revision log."
        call gitTools#tools#Error("Current file is not an git log file!")
        return
    endif

    let l:filename = expand("%")

    " Get all revision numbers
    let l:list = gitTools#log#GitLogFileGetCommitNumberList()
    if len(l:list) == 0
        call gitTools#tools#Error("No revision number found on current buffer!")
        return
    endif

    redraw
    echo "Number of commits: ".len(l:list)
    echo "Commits found: ".join(l:list)
    if a:num != ""
        call confirm("Open the first ".a:num." revisions. Continue?")
        let max = str2nr(a:num)
    else
        call confirm("Open each revision diff. Continue?")
        let max = len(l:list)
    endif

    if confirm("Open each revision on new tab?", "&yes\n&no", 1) == 2
        let l:mode = "same_tab"
        silent tabnew
        " Rename buffer
        let l:newname = substitute(l:filename, 'gitLog', 'gitLogRevDiff_'.l:max.'Rev_', "g")
        if l:newname != ""
            silent! exec("0file")
            silent! exec("bd! ".l:newname)
            silent! exec("file! ".l:newname)
        endif
    else
        let l:mode = "new_tab"
    endif

    redraw
    " Perform git log and git diff for each revision.
    let n=1
    for rev in l:list
        echo l:n."/".l:max.") Getting ".l:rev." log and diff..."
        call s:GitLogFileGetRevisionDiff(l:rev, l:mode)
        let n+=1
        if a:num != "" && l:n > l:max | break | endif
    endfor
endfunction


" Search the git log for commit number
" Arg1: [commitNum] number of commits to search
" Commands: Gitlr
"function! gitTools#log#GetRevision(commitNum)
    "echo "Get log changes."

    "let l:gitCmd  = g:gitTools_gitCmd
    "let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()

    "" Get git log from last x commits
    "let l:command = l:gitCmd." log "
    "echo "This may take a while ..."

    "let l:name = "_gitLog.log"

    "let callback = ["gitTools#log#GetRevisionEnd", l:name]

    "call gitTools#tools#WindowSplitMenu(4)
    "call gitTools#tools#SystemCmd(l:command,l:callback,1)
"endfunction

"function! gitTools#log#GetRevisionEnd(name,resfile)
    "if exists('a:resfile') && !empty(glob(a:resfile)) 
        "call gitTools#tools#WindowSplit()
        "" Rename buffer
        "silent! exec("0file")
        "silent! exec("bd! ".a:name)
        "silent! exec("file! ".a:name)
        "silent put =  readfile(a:resfile)
        "silent exec("normal gg")
        "call   delete(a:resfile)
        "normal gg
        "call gitTools#tools#WindowSplitEnd()
        "redraw
        "call s:SetSyntaxAndHighlighting("")
    "else
        "call gitTools#tools#Warn("Git log search empty")
    "endif
"endfunction


" Search the git log for pattern
" Arg1: pattern to search.
" Commands: Gitls
function! gitTools#log#SearchPattern(pattern)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let l:pattern = a:pattern

    if l:pattern == ""
        call gitTools#tools#Warn("Argument 1: search pattern not found.")
        return
    endif

    let l:name = "_gitLog_search___".l:pattern.".log"

    let l:gitCmd  = g:gitTools_gitCmd
    let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()

    let command  = l:gitCmd." log --grep='".l:pattern."'"
    let callback = ["gitTools#log#GitLogSearchPatternEnd", l:name, l:command]

    echo l:command
    call gitTools#tools#WindowSplitMenu(4)

    echo "This may take a while ..."
    call gitTools#tools#SystemCmd(l:command,l:callback,1)
endfunction

function! gitTools#log#GitLogSearchPatternEnd(name, command, resfile)
    if exists('a:resfile') && !empty(glob(a:resfile)) 
        call gitTools#tools#WindowSplit()

        " Rename buffer
        silent! exec("0file")
        silent! exec("bd! ".a:name)
        silent! exec("file! ".a:name)

        " Add header
        let l:textList = [ " [gitTools.vim] ".a:command ]
        let l:header = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
        silent put=l:header

        " Add the git log search info
        put =  readfile(a:resfile)

        call   s:SetSyntaxAndHighlighting("")
        silent exec("normal gg")
        call   delete(a:resfile)
        normal gg
        call gitTools#tools#WindowSplitEnd()
        redraw

        " Set buffer parameters
        setl noswapfile
        setl nomodifiable
        setl buflisted
        setl bufhidden=delete
        setl buftype=nofile
        setl nonu
    else
        call gitTools#tools#Warn("Git log search pattern empty")
    endif
endfunction



" Get log and diff from the selected revision.
" Arg1: hash commit number to search.
" Command: Gitr
function! gitTools#log#GetLogAndDiff(hash)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    if a:hash == ""
        let l:line = gitTools#tools#TrimString(getline("."))
        if l:line =~ "commit"
            " Get hash from current line
            let l:lineList = split(l:line)
            "echom "Add hash: ".l:hash
            let l:hash = l:lineList[1]
        else
            let l:hash = expand("<cword>")
        endif
    else
        let l:hash = a:hash
    endif

    " CHeck revision number lenght:
    if len(l:hash) < 11
        call gitTools#tools#Error("Wrong revision number lenght ".l:hash." (expected lenght >= 12)")
        return
    endif

    " Check contains both numbers and letters:
    let l:numbers = substitute(l:hash, '[^0-9]*', '', 'g')
    let l:letters = substitute(l:hash, '[^a-zA-Z]*', '', 'g')

    if l:numbers == "" || l:letters == ""
        call gitTools#tools#Warn("Found a weird revision number ".l:hash)
        call confirm("Proceed?")
    endif

    let name = "_gitShowRev_".l:hash.".diff"
    echo "Getting ".l:hash." log and diff"

    let l:gitCmd  = g:gitTools_gitCmd
    let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()

    let l:command  = l:gitCmd." show --src-prefix='' --dst-prefix='' ".l:hash
    
    let l:callback = ["gitTools#log#GetLogAndDiffCallback", l:name, l:command]

    echo l:command
    call gitTools#tools#WindowSplitMenu(4)
    call gitTools#tools#SystemCmd(l:command,l:callback,1)
endfunction


function! gitTools#log#GetLogAndDiffCallback(name, command, resfile)
    if !exists('a:resfile') || empty(glob(a:resfile)) 
        call gitTools#tools#Warn("Git log and diff empty")
        return
    endif

    call   gitTools#tools#WindowSplit()
    call   gitTools#tools#LogLevel(1, expand('<sfile>'), "name=".a:name)

    " Add header
    let l:textList = [ " [gitTools.vim] ".a:command ]
    let l:header = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
    silent put=l:header

    " Rename buffer
    silent! exec("0file")
    silent! exec("bd! ".a:name)
    silent! exec("file! ".a:name)

    put =  readfile(a:resfile)

    call   s:SetSyntaxAndHighlighting("diff")
    silent exec("normal gg")
    call   delete(a:resfile)
    call   gitTools#tools#WindowSplitEnd()

    " Comment header and log lines
    normal ggdd0/diffkI# 

    " Set buffer parameters
    setl noswapfile
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    setl nonu

    redraw
endfunction


" Set file type and if hi.vim plugin is available: apply a color highlighting.
" Arg1: syntax, file syntax (c, cpp, py, sh, diff...).
"   Leave empty ("") to not apply any file type syntax.
function! s:SetSyntaxAndHighlighting(syntax)
    if exists('g:HiLoaded')
        let g:HiCheckPatternAvailable = 0
        silent! call hi#config#PatternColorize("commit " , "w*")
        silent! call hi#config#PatternColorize("Author: ", "c*")
        silent! call hi#config#PatternColorize("Date: "  , "o2*")
        silent! call hi#config#PatternColorize("Merge: " , "o*")
        silent! call hi#config#PatternColorize("http>>:>>\ ", "b_&")
        let g:HiCheckPatternAvailable = 1
    endif

    if a:syntax != ""
        silent exec("set ft=".a:syntax)
        if exists('g:HiLoaded')
            call hi#hi#Refresh()
        endif
    endif
endfunction


" Get the git reflog.
" Commands: Gitrl
function! gitTools#log#GetRefLog(options)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let l:gitCmd  = g:gitTools_gitCmd
    let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()

    let name     = "_gitRefLog.log"
    let command  = l:gitCmd." reflog ".a:options
    let callback = ["gitTools#log#GitRefLogEnd", l:name, l:command]

    echo l:command
    call gitTools#tools#WindowSplitMenu(4)
    call gitTools#tools#SystemCmd(l:command, l:callback, 1)
endfunction


function! gitTools#log#GitRefLogEnd(name, cmd, resfile)
    if exists('a:resfile') && !empty(glob(a:resfile)) 
        call gitTools#tools#WindowSplit()

        " Rename buffer
        silent! exec("0file")
        silent! exec("bd! ".a:name)
        silent! exec("file! ".a:name)

        " Add header
        let l:textList = [ " [gitTools.vim] ".a:cmd ]
        let l:header1 = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
        silent put=l:header1

        silent put =  readfile(a:resfile)

        silent exec("normal gg")
        call   delete(a:resfile)
        normal ggdd
        call gitTools#tools#WindowSplitEnd()
        redraw
        "call s:SetSyntaxAndHighlighting("")

        " Set buffer parameters
        setl noswapfile
        setl nomodifiable
        setl buflisted
        setl bufhidden=delete
        setl buftype=nofile
        setl nonu

        if exists('g:HiLoaded')
            let g:HiCheckPatternAvailable = 0
            silent! call hi#config#PatternColorize(": commit: "      , "c")
            silent! call hi#config#PatternColorize(": commit (merge): ", "c")
            silent! call hi#config#PatternColorize(": pull.*: .*"    , "v")
            silent! call hi#config#PatternColorize(": reset.*: .*"   , "o2")
            silent! call hi#config#PatternColorize(": checkout.*: .*", "b1")
            silent! call hi#config#PatternColorize(": clone.*: .*"   , "w")
            let g:HiCheckPatternAvailable = 1
        endif
    else
        call gitTools#tools#Warn("Git ref log search empty")
    endif
endfunction


" Show git log graph.
" Args: options, git log command's options.
" Cmd: gitlg
function! gitTools#log#Graph(options)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    "let l:command = "git log --graph --decorate --oneline ".a:options"
    let l:command = g:gitTools_gitCmd." log --graph ".a:options." "
    echo l:command
    call gitTools#tools#WindowSplitMenu(3)
    call gitTools#tools#WindowSplit()

    " Add header
    let l:textList = [ " [gitTools.vim] ".l:command ]
    let l:header1 = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
    silent put=l:header1

    echo l:command
    silent exec("r! ".l:command)
    call gitTools#tools#WindowSplitEnd()

    " Rename buffer
    "let name = "_gitLog_graph.diff"
    let l:date = strftime("%y%m%d_%H%M")
    let l:branch = gitTools#branch#Current()
    let l:optionNames = ""
    if a:options != ""
        let l:optionNames = "-".a:options
        let l:optionNames = substitute(l:optionNames, "--", "",  "g")
        let l:optionNames = substitute(l:optionNames, " ",  "-", "g")
    endif
    let name     = "_".l:date."_gitLog_graph".l:optionNames."__".l:branch.".log"

    silent! exec("0file")
    silent! exec("bd! ".l:name)
    silent! exec("file! ".l:name)

    normal ggdd

    " Set buffer parameters
    setl noswapfile
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    setl nonu

    if exists('g:HiLoaded')
        let g:HiCheckPatternAvailable = 0
        silent! call hi#config#PatternColorize("HEAD"      , "g2")
        silent! call hi#config#PatternColorize(" Merge "   , "o2")
        silent! call hi#config#PatternColorize(" Pull "    , "m2")
        silent! call hi#config#PatternColorize(" Commit "  , "c")
        silent! call hi#config#PatternColorize(" Reset "   , "o2")
        silent! call hi#config#PatternColorize(" Checkout ", "b1")
        silent! call hi#config#PatternColorize(" Clone "   , "w")
        silent! call hi#config#PatternColorize(" Branch "  , "m2")

        let l:numList = [ "", "1", "2", "3", "4" ]
        let l:colorList = [ "y", "g", "b", "m", "c", "o", "r", "v", "w" ]
        let l:pattern1 = "^"
        let l:pattern2 = "^"
        let l:pattern3 = "^"

        for l:num in l:numList
            for l:color in l:colorList
                silent! call hi#config#PatternColorize(l:pattern1."[|*]", l:color.l:num)
                let pattern1 .= "[|*][/\_ ]"

                if l:color != "y"
                    silent! call hi#config#PatternColorize(l:pattern2."[|*/\ ][/\]", l:color.l:num)
                    let pattern2 .= "[|*][/\_ ]"

                    silent! call hi#config#PatternColorize(l:pattern3."[/\]", l:color.l:num)
                    let pattern3 .= "[|*-] "
                endif
            endfor
        endfor

        silent! call hi#config#PatternColorize(" [a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-z0-9][a-f0-9][a-f0-9]\ ", "w4")
        let g:HiCheckPatternAvailable = 1
    endif
endfunction

