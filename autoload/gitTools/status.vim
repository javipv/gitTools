" Script Name: gitTools/status.vim
 "Description: save/restore/compare the file changes.
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies:  hi.vim
"
" NOTES:
"

" Show on a new window the git status lines matching the selected filter
" pattern.
" Arg1: path, file or path to check with git status
" Arg2: git commmand options (-uno --branch --show-stash...).
" Commands: Gitst, Gitsta, Gitstf, Gitstd.
function! gitTools#status#GetStatus(path, options)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let l:gitCmd  = "LC_ALL=C ".g:gitTools_gitCmd
    let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()
    let l:gitOptions = "-u --branch --show-stash ".a:options

    let command  = l:gitCmd." status ".l:gitOptions." ".a:path 
    let callback = ["gitTools#status#GetStatusEnd", a:path, a:options, l:command]

    if expand("%s") =~ "_gitStatus___" && getline(2) =~ "gitTools.vim" && getline(2) =~ "git status"
        " Current buffer already shows git status
    else
        echo l:command
        call gitTools#tools#WindowSplitMenu(1)
    endif

    call gitTools#tools#SystemCmd(l:command, l:callback, 1)

    redraw
    echo l:command." ... in progress on background (Use :Jobsl to check status)"
endfunction


function! gitTools#status#GetStatusEnd(path, options, command, resfile)
    if !exists('a:resfile') || empty(glob(a:resfile)) 
        call gitTools#tools#Warn("Git reset empty")
        return
    endif

    " Check fatal error
    let fileList = readfile(a:resfile)

    if l:fileList[0]  =~ "fatal: not a git repository"
        redraw
        call gitTools#tools#Error("ERROR: not a git repository")
        return
    endif

    if expand("%s") =~ "_gitStatus___" && getline(2) =~ "gitTools.vim" && getline(2) =~ "git status"
        " Current buffer already shows git status
        let w:winSize = winheight(0)
        let w:split = 4
        let l:sameWindow = 1
    else
        let l:sameWindow = 0
        "call gitTools#tools#WindowSplitMenu(1)
    endif

    call gitTools#tools#WindowSplit()

    " Add the log info
    "silent put =  readfile(a:resfile)
    silent put = l:fileList
    normal ggdd
    call   delete(a:resfile)

    " Add header on top
    let l:textList = []
    let l:textList += [ " [gitTools.vim] ".a:command." " ]
    let l:textList += [ " ==========================================================" ]
    let l:textList += [ " Available commands:" ]
    let l:textList += [ " Place cursor on line showing git file's status then:" ]
    let l:textList += [ " - Use :Gita to add to the staging area." ]
    let l:textList += [ " - Use :Gitu to remove from staging area." ]
    let l:textList += [ " - Use :GitR to restore discarding the changes." ]
    let l:textList += [ " - Use :Gitrm to remove from repository." ]
    let l:textList += [ " - Use :Gitmv to change the path." ]
    let l:textList += [ " - Use :GitRM to remove from disk." ]
    let l:text = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
    normal ggO
    put=l:text
    normal ggdd

    " Resize window to fit content.
    call gitTools#tools#WindowSplitEnd()
    redraw

    " Apply color highlighting:
    if l:sameWindow != 1
        if a:options =~ "s"
            call s:ApplyShortStatusColorHighlighting()
        else
            call s:ApplyStatusColorHighlighting()
        endif
    else
        if exists('g:HiLoaded')
            silent! call hi#hi#Refresh()  
        endif
    endif

    " Search main block text to iterate with next (n) key
    call s:SearchBlocks()

    " Rename window
    let l:flatpath = gitTools#tools#GetPathAsFilename(a:path)
    if l:flatpath != ""
        let l:flatpath = "__".l:flatpath
    endif

    "let l:currentBranch = gitTools#info#GetCurrentBranch()
    let l:currentBranch = gitTools#branch#Current()

    let l:date = strftime("%y%m%d_%H%M")
    let l:filename = "_".l:date."_gitStatus___".l:currentBranch.l:flatpath.".txt"

    silent exec("0file")
    silent! exec("file ".l:filename)
    setlocal bt=nofile

    " Set buffer parameters
    setl noswapfile
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    setl nonu

    " Check for merge files to be deleted
    let l:n = 0
    "   search(pattern, W:do not wrap to the start, 0:end line not set, 2000:2sec timeout).
    let l:searchList = [ "_BACKUP_", "_LOCAL_", "_BASE_", "_REMOTE_" ]
    for l:search in l:searchList
        normal gg
        while search(l:search, 'W', 0, 2000) != 0
            let l:n += 1
        endwhile
    endfor
    normal gg

    if l:n != 0
        call gitTools#tools#Warn("ATTENTTION: ".l:n." merge files found! (Use :Gitmrm to delete them).")
    endif
endfunction


" Show on a new window the git status lines matching the selected filter
" pattern.
" Arg1: path, file or path to check with git status
" Arg2: filter keep pattern.
"   Keep only files in conflict: "^C ".
"   Keep only modified files: "^M ".
"   Keep only modified, added or deleted files: "^M \|^A \|^D ".
" Arg3: filter remove pattern.
"   Remove only files not added to the repository: "^? ".
"   Remove only files with modified permissions: "^X ".
"   Remove both files not added and permission changes: "^? \|^X ".
" Arg4: git commmand options (-uno --branch --show-stash...).
" Commands: Gitst, Gitsta, Gitstf, Gitstd.
function! gitTools#status#GetStatusFilter(path, filter, remove, options)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let l:gitCmd  = g:gitTools_gitCmd
    let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()
    let l:gitOptions = "-s --branch --show-stash ".a:options

    "let command  = l:gitCmd." status -s --branch --show-stash ".a:path 
    let command  = l:gitCmd." status ".l:gitOptions." ".a:path 
    let callback = ["gitTools#status#GetStatusFilterEnd", a:path, a:filter, a:remove]
    call gitTools#tools#WindowSplitMenu(1)
    call gitTools#tools#SystemCmd(l:command, l:callback, 1)
endfunction

function! gitTools#status#GetStatusFilterEnd(path, filter, remove, resfile)
    if !exists('a:resfile') || empty(glob(a:resfile)) 
        call gitTools#tools#Warn("Git status ". a:path .". No modifications found.")
        return
    endif

    call gitTools#tools#WindowSplit()
    put = readfile(a:resfile)

    " Filter window content.
    if a:filter != ""
        silent exec "g!/". a:filter ."/d"
        let l:filter0 = a:filter
    else
        let l:filter = ""
        let l:filter0 = "none"
    endif

    " Filter window content.
    if a:remove != ""
        silent exec "g/". a:remove ."/d"
    endif

    let noResults = 0
    if line('$') == 1 && getline(".") == ""
        let noResults = 1
    endif
    if line('$') == 2 && getline(1) == "" && getline(2) == ""
        let noResults = 1
    endif

    " Close window if empty
    if l:noResults == 1
        if a:filter == "" && a:remove == ""
            call gitTools#tools#Warn("Git status ". a:path .". No modifications found.")
        else
            call gitTools#tools#Warn("Git status ". a:path .". No modifications found. (Keep: ". a:filter .". Remove: ". a:remove.")" )
        endif
        quit
        return
    endif

    let l:lines0 = line('$')

    call delete(a:resfile)

    " Rename window
    let l:flatpath = gitTools#tools#GetPathAsFilename(a:path)
    let l:filename = "_gitStatusFiltered___".l:flatpath.".txt"
    silent exec("0file")
    silent! exec("file ".l:filename)
    setlocal bt=nofile

    " Add header on top
    normal ggO
    if a:filter == "" && a:remove == ""
        let text = "[gitTools.vim] git status '".a:path."' (".l:lines0." results)"
    else
        let text = "[gitTools.vim] git status '".a:path."' Filter: keep:'".l:filter0."', remove:'".a:remove."' (".l:lines0." results)"
    endif
    put=l:text
    normal ggdd

    " Resize window to fit content.
    call gitTools#tools#WindowSplitEnd()
    redraw
    call s:ApplyShortStatusColorHighlighting()

    " Search main block text to iterate with next (n) key
    call s:SearchBlocks()

    au BufLeave <buffer> bdelete g:scratch_buffer
    call CreateScratchWindow()
endfunction


" Get a list of files added modified or deleted on the repository.
" Arg1: path to be checked with git status.
" Return: list with the required files.
function! gitTools#status#GetListOfFilesAddedModifiedDeleted(path)
    return gitTools#status#GetStatusFilesList(a:path, '^[MAD]\|^[A-Z?! ][MAD]')
endfunction


" Get a list of files added modified, deleted or unmerged on the repository.
" Arg1: path to be checked with git status.
" Return: list with the required files.
function! gitTools#status#GetListOfFilesAddedModifiedDeletedUnmerged(path)
    return gitTools#status#GetStatusFilesList(a:path, '^[UMAD]\|^[A-Z?! ][UMAD]')
endfunction


" Get a list of unmerged files on the repository.
" Arg1: path to be checked with git status.
" Return: list with the required files.
function! gitTools#status#GetListOfFilesUnmerged(path)
    "return gitTools#status#GetStatusFilesList(a:path, "^U\|[A-Z?! ]U\|^AA\|^DD")
    return gitTools#status#GetStatusFilesList(a:path, 'DD\|AU\|UD\|UA\|DU\|AA\|UU')
endfunction


" Get files from git status that match the selected filter pattern.
" Arg1: path to be checked with git status.
" Arg2: pattern to keep from the result: 
"   Keep only files in conflict: "^C ".
"   Keep only modified files: "^M ".
"   Keep only modified, added or deleted files: "^M \|^A \|^D ".
" Return: list with all files.
function! gitTools#status#GetStatusFilesList(path, filter)
    let l:list = []
    let l:gitCmd  = g:gitTools_gitCmd
    let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()
    let text = system(l:gitCmd." status -s ". a:path)
    "echom "Git status: ".l:text

    if l:text == "" 
        return l:list
    endif

    silent new
    normal ggO
    silent put=l:text
    normal ggdd

    if a:filter != ""
        "echom "Filter: ".a:filter
        silent exec "v/".a:filter."/d"
    endif
    silent exec "g/^$/d"

    if line('$') == 1 && getline(".") != ""
        " Only one file
        let @z = ""
        silent normal 0lwviW"zy
        let files = @z
        "echom "File: ".l:files
        let list = [ l:files ]
    else
        " Get last column. File paths.
        let @z = ""
        silent normal gg0lwG$"zy
        let l:files = @z
        "echom "files:".l:files
        let l:list = split(l:files, "\n")
    endif

    "echom "Git status list: "l:list
    silent quit!
    return l:list
endfunction



" Get files from git status that match the selected filter pattern.
" Arg1: filter pattern.
"   Keep only files in conflict: "^C ".
"   Keep only modified files: "^M ".
"   Keep only modified, added or deleted files: "^M \|^A \|^D ".
" Return: string with all files.
"function! gitTools#status#GetStatusFilesString(path, filter)
    "let l:list = []
    "let l:gitCmd  = g:gitTools_gitCmd
    "let l:gitCmd .= gitTools#tools#CheckGitUserAndPsswd()

    "" Short format (-s). Get only modified files (-uno).
    "" Use porcelain 1, guaranteed not to change in a backwards-incompatible way between Git versions.
    "let text = system(l:gitCmd." status -suno --porcelain=1 ".a:path)

    "if l:text == "" 
        "return ""
    "endif

    "silent new
    "normal ggO
    "silent put=l:text
    "normal ggdd

    "if a:filter != ""
        "silent exec "g!/". a:filter ."/d"
    "endif

    "silent exec "g/^$/d"

    "if line('$') == 1 && getline(".") == ""
        "" Empty file
        "let l:res = ""
    "else
        ""silent normal gg0WG$"zy
        ""silent normal gg0f/bG$"zy
        "silent normal gg0lwG$"zy
        "let files = @z
        "let l:res = substitute(l:files, "\n", " ", "g")

        "if l:res =~ "not a working copy"
            "call gitTools#tools#Error("Not a git working copy")
            "return ""
        "endif
    "endif

    "silent exec("bd!")
    "return l:res
"endfunction
"
"

function! s:ApplyShortStatusColorHighlighting()
    if exists('g:HiLoaded')
        let g:HiCheckPatternAvailable = 0
        silent! call hi#config#PatternColorize("#.*]", "w")
        silent! call hi#config#PatternColorize("ahead.*,", "g")
        silent! call hi#config#PatternColorize("behind.*]", "r")

        "silent! call hi#config#PatternColorize(" C ", "m*")          " Conflicted
        "silent! call hi#config#PatternColorize("?.*left",    "m2*")  " Conflicted. Merge file.
        "silent! call hi#config#PatternColorize("?.*right",   "m3*")  " Conflicted. Merge file.
        "silent! call hi#config#PatternColorize("?.*working", "m1*")  " Conflicted. Merge file.
        "silent! call hi#config#PatternColorize("?.*mine",    "m1*")  " Conflicted. Merge file.
        "silent! call hi#config#PatternColorize("?.*original","m1*")  " Conflicted. Merge file.
        "silent! call hi#config#PatternColorize("?.*second",  "m3*")  " Conflicted. Merge file.
        "silent! call hi#config#PatternColorize("?.*first",   "m2*")  " Conflicted. Merge file.
        "silent! call hi#config#PatternColorize("! ",         "r4@")  " Ignored
        "silent! call hi#config#PatternColorize("\\~ ",       "v2@")  " Obstructed by some item of different kind
        "
        " Added to staging area
        silent! call hi#config#PatternColorize("A[MICRT? ] ","g")  
        silent! call hi#config#PatternColorize("[MICRT? ]A ","g")  
        silent! call hi#config#PatternColorize("AA ",        "m1*") " Unmerged
        silent! call hi#config#PatternColorize(" A ",        "g*") 
        silent! call hi#config#PatternColorize("A ",         "g*") 
        " Copied
        silent! call hi#config#PatternColorize("C[A-Z? ] ",  "y3") 
        silent! call hi#config#PatternColorize("[A-Z? ]C ",  "y3") 
        silent! call hi#config#PatternColorize("CC ",        "y3*")
        silent! call hi#config#PatternColorize(" C ",        "y3*")
        silent! call hi#config#PatternColorize("C ",         "y3*")
        " Deleted
        silent! call hi#config#PatternColorize("D[A-Z? ] ",  "o")  
        silent! call hi#config#PatternColorize("[A-Z? ]D ",  "o")  
        silent! call hi#config#PatternColorize("DD ",        "m1*") " Unmerged
        silent! call hi#config#PatternColorize(" D ",        "o*") 
        silent! call hi#config#PatternColorize("D ",         "o*") 
        " Ignored
        silent! call hi#config#PatternColorize("I[A-Z?] ",   "y")  
        silent! call hi#config#PatternColorize("[A-Z?]I ",   "y")  
        silent! call hi#config#PatternColorize("II ",        "y*") 
        silent! call hi#config#PatternColorize(" I ",        "y*") 
        silent! call hi#config#PatternColorize("I ",         "y*") 
        " Modified
        silent! call hi#config#PatternColorize("M[A-Z?] ",   "b")  
        silent! call hi#config#PatternColorize("[A-Z?]M ",   "b")  
        silent! call hi#config#PatternColorize("MM ",        "b*") 
        silent! call hi#config#PatternColorize(" M ",        "b*") 
        silent! call hi#config#PatternColorize("M ",         "b*") 
        " Renamed
        silent! call hi#config#PatternColorize("R[A-Z?] ",   "y")  
        silent! call hi#config#PatternColorize("[A-Z?]R ",   "y")  
        silent! call hi#config#PatternColorize("RR ",        "y*") 
        silent! call hi#config#PatternColorize(" R ",        "y*") 
        silent! call hi#config#PatternColorize("R ",         "y*") 
        " File type changed
        silent! call hi#config#PatternColorize("T[A-Z?] ",  "y2") 
        silent! call hi#config#PatternColorize("[A-Z?]T ",   "y2") 
        silent! call hi#config#PatternColorize("TT ",        "y2*")
        silent! call hi#config#PatternColorize("T ",         "y2*")
        silent! call hi#config#PatternColorize(" T ",        "y2*")
        " Updated but unmerged
        silent! call hi#config#PatternColorize("U[A-Z?] ",   "m1*")  
        silent! call hi#config#PatternColorize("[A-Z?]U ",   "m1*")  
        silent! call hi#config#PatternColorize("UU ",        "m1*") 
        silent! call hi#config#PatternColorize("U ",         "m1*") 
        silent! call hi#config#PatternColorize(" U ",        "m1*") 
        " Unversioned directory
        silent! call hi#config#PatternColorize("X[A-Z?] ",   "w7")
        silent! call hi#config#PatternColorize("[A-Z?]X ",   "w7")
        silent! call hi#config#PatternColorize("XX ",        "w7*")
        silent! call hi#config#PatternColorize("X ",         "w7*")
        silent! call hi#config#PatternColorize(" X ",        "w7*")
        " Unversioned file
        silent! call hi#config#PatternColorize("?[A-Z? ] ",  "w8") 
        silent! call hi#config#PatternColorize("[A-Z? ]? ",  "w8") 
        silent! call hi#config#PatternColorize("?? ",        "w8*")
        silent! call hi#config#PatternColorize("? ",         "w8*")
        silent! call hi#config#PatternColorize(" ? ",        "w8*")
        " Ignored file
        silent! call hi#config#PatternColorize("![A-Z? ] ",  "w6") 
        silent! call hi#config#PatternColorize("[A-Z? ]! ",  "w6") 
        silent! call hi#config#PatternColorize("!! ",        "w6*")
        silent! call hi#config#PatternColorize("! ",         "w6*")
        silent! call hi#config#PatternColorize(" ! ",        "w6*")
        let g:HiCheckPatternAvailable = 1
    endif
endfunction


function! s:ApplyStatusColorHighlighting()
    if exists('g:HiLoaded')
        let g:HiCheckPatternAvailable = 0

        silent! call hi#config#PatternColorize("Changes to be committed:", "g2!")
        silent! call hi#config#PatternColorize("Changes not staged for commit:", "y1!")
        silent! call hi#config#PatternColorize("Untracked files:", "o1!")
        silent! call hi#config#PatternColorize("Unmerged paths:" , "m1!")

        silent! call hi#config#PatternColorize("#.*]", "w")
        silent! call hi#config#PatternColorize("ahead.*,", "g")
        silent! call hi#config#PatternColorize("behind.*]", "r")
        "
        silent! call hi#config#PatternColorize("modified: ", "b*")  
        silent! call hi#config#PatternColorize("both added: ", "b*")  
        silent! call hi#config#PatternColorize("new file:" , "g*")  
        silent! call hi#config#PatternColorize("unmerged " , "m1*")
        silent! call hi#config#PatternColorize("deleted:"  , "r1*")

        silent! call hi#config#PatternColorize("renamed:"  , "y*")  
        silent! call hi#config#PatternColorize("typechange:", "y1*")  

        silent! call hi#config#PatternColorize("_BACKUP_", "o!*")  
        silent! call hi#config#PatternColorize("_LOCAL_" , "o!*")  
        silent! call hi#config#PatternColorize("_BACKUP_", "o!*")  
        silent! call hi#config#PatternColorize("_REMOTE_", "o!*")  

        let g:HiCheckPatternAvailable = 1
    endif
endfunction


function! s:SearchBlocks()
    "let l:patterns = "Changes to be committed:\\|Unmerged paths:\\|Changes not staged for commit:\\|Untracked files:"
    let l:patterns = "Changes to be committed:"
    let l:patterns .= "\\|Unmerged paths:"
    let l:patterns .= "\\|Changes not staged for commit:"
    let l:patterns .= "\\|Untracked files:"
    let l:patterns .= "\\|_LOCAL_\\|_REMOTE_\\|_BACKUP_"

    silent execute "normal! gg"

    silent! call search(l:patterns, 'W', 0, 500)

    " Set search history
    let @/ = l:patterns

    redraw
    call gitTools#tools#Attention("INFO: use forward/backward search to move between blocks")
endfunction

