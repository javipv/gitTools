" Script Name: gitTools/tag.vim
 "Description: 
"
" Copyright:   (C) 2023-2024 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: jobs.vim
"
"

"- functions -------------------------------------------------------------------


"=================================================================================
" GIT TAG -n
"=================================================================================

" Show git tags on buffer. Get tags asynchronously.
" Args: [pattern], show only tags matching pattern.
" Commands: Gitt
function! gitTools#tag#Show(options, ...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let w:gitTools_options = a:options
    let l:cmd = "git tag -n ".join(a:000)
    let l:tags = system(l:cmd)
    let l:tagsList = split(l:tags, "\n")

    if len(l:tagsList) == 0
        call gitTools#tools#Error("ERROR: empty tag list.")
        return
    endif

    echo l:cmd
    call gitTools#tools#WindowSplitMenu(1)

    " Lauch command on background with Jobs.vim plugin.
    let l:callback = [ "gitTools#tag#ShowEnd", l:cmd ]
    call gitTools#tools#SystemCmd(l:cmd, l:callback, 1)
    redraw
    echo l:cmd." ... in progress on background (Check state with :Jobsl)"
endfunction

function! gitTools#tag#ShowEnd(cmd, output)
    if !exists('a:output')
        call gitTools#tools#Warn("Git result not found. ".a:cmd)
    endif

    if empty(glob(a:output)) 
        call gitTools#tools#Warn("Git result empty. ".a:cmd)
    endif

    " Open result file
    "silent exec "new ".a:output
    redraw
    call gitTools#tools#WindowSplit()

    " Open result file
    silent exec "edit ".a:output

    " Add header on top
    let l:textList = [ " [gitTools.vim] ".a:cmd." " ]
    let l:text = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
    normal ggO
    put=l:text
    normal ggdd

    " Set buffer parameters
    setl noswapfile
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    setl nonu

    " Change name
    let l:date = strftime("%y%m%d_%H%M")
    let l:filename = "_".l:date."_gitShowTags"

    silent exec("0file")
    silent! exec("file ".l:filename)

    call gitTools#tools#WindowSplitEnd()
endfunction


"=================================================================================
" GIT TAG -n (menu)
"=================================================================================

" Show git tags on menu.
" Args: [pattern], show only tags matching pattern.
" Commands: Gittm
function! gitTools#tag#Menu(options, ...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let w:gitTools_options = a:options
    let l:cmd = "git tag -n ".join(a:000)
    let l:tags = system(l:cmd)
    let l:tagsList = split(l:tags, "\n")

    if len(l:tagsList) == 0
        call gitTools#tools#Error("ERROR: empty tag list.")
        return
    endif

    let l:header = [ "[gitTools] Git tags:" ]
    let l:callback = "gitTools#tag#MenuEnd"

    call gitTools#menu#AddCommentLineColor("#", "b*")
    call gitTools#menu#OpenMenu(l:header, l:tagsList, l:callback, "")
endfunction

function! gitTools#tag#MenuEnd(tagLine)
    if a:tagLine == ""
        return
    endif

    let l:tagList = split(a:tagLine)
    let l:tag = l:tagList[0]
    let @" = l:tag
    echo "[gitTools.vim] Tag name: ".l:tag." saved to default yank buffer"
endfunction


"=================================================================================
" GIT TAG -A
"=================================================================================

" Add git tag.
" Arg1: [name], add a new tag with name.
" Arg2: [hash], add the tag from the commit represented with hash.
" Commands: Gitta
function! gitTools#tag#Add(options, ...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let l:optionsName = ""
    if a:options != ""
        let l:optionsName = substitute(a:options, "-", "", "g")
    endif

    let l:tag = ""
    let l:hash = ""
    let l:mssg = ""
    let l:command = g:gitTools_gitCmd." tag"
    let l:tagName = ""

    if a:options != ""
        let l:command .= " ".a:options
    endif

    if len(a:000) >= 1
        let l:tag = gitTools#tools#TrimString(a:1)
    else
        let l:tag = input("[gitTools.vim] Add tag with name: ")
        redraw
    endif

    if l:tag == ""
        call gitTools#tools#Error("ERROR: empty tag name.")
        return
    endif

    if len(a:000) >= 2
        let l:hash = gitTools#tools#TrimString(a:2)
    else
        redraw
        let l:hash = input("[gitTools.vim] Add new tag ".l:tag." from hash: (press enter to use current commint hash) ")
    endif

    let l:tagName .= "_".l:tag
    let l:command .= " -a ".l:tag

    if l:hash != ""
        let l:command .= " ".l:hash
        let l:tagName .= "_".l:hash
    endif

    let l:mssg = input("[gitTools.vim] Add new tag ".l:tag." with message: (press enter to skip) ")
    let l:command .= " -m \"".l:mssg."\""

    redraw
    echo l:command
    let l:result = system(l:command)

    if l:result == ""
        redraw
        echo "[gitTools.vim] ".l:command." --> Added"
    else
        let l:textList = [ " [gitTools.vim] ".l:command." FAILED" ]
        let l:text = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
        let l:text .= "\n"
        let l:text .= l:result

        silent new
        silent put = l:text
        normal ggdd

        call gitTools#tools#WindowSplitEnd()
        redraw

        silent exec("0file")
        silent! exec("file _git_tag_add")

        " Set buffer parameters
        setl noswapfile
        setl nomodifiable
        setl buflisted
        setl bufhidden=delete
        setl buftype=nofile
        setl nonu
    endif
endfunction


"=================================================================================
" GIT TAG -D
"=================================================================================

" Delete git tag.
" Arg1: [name], add a new tag with name.
" Commands: Gittd
function! gitTools#tag#Delete(options, ...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let l:tagName = ""
    let w:gitTools_options = a:options
    let w:gitTools_launchTagDeleteMenu = "no"

    if len(a:000) >= 1
        let l:tag = gitTools#tools#TrimString(a:1)
        call gitTools#tag#DeleteTagName(l:tag)
    else
        let l:tags = system("git tag -n")
        let l:tagsList = split(l:tags, "\n")

        if len(l:tagsList) == 0
            call gitTools#tools#Error("ERROR: empty tag list.")
            return
        endif

        let l:header = [ "[gitTools] Git tag delete. Select tag:" ]
        let l:callback = "gitTools#tag#DeleteTagName"

        if len(l:tagsList) > 1
            let w:gitTools_launchTagDeleteMenu = "yes"
        endif
        let l:tagsList += [ "# ATTENTION! Tags will be deleted on local." ]

        call gitTools#menu#SetHeaderColor("r*")
        call gitTools#menu#AddCommentLineColor("#", "r*")
        call gitTools#menu#OpenMenu(l:header, l:tagsList, l:callback, "")
    endif
endfunction


function! gitTools#tag#DeleteTagName(tagLine)
    if a:tagLine == ""
        return
    endif

    let l:tagList = split(a:tagLine)
    let l:tag     = l:tagList[0]
    let l:command = g:gitTools_gitCmd." tag"

    if w:gitTools_options != ""
        let l:command .= " ".a:gitTools_options
    endif

    if l:tag == ""
        call gitTools#tools#Error("ERROR: empty tag name.")
        return
    endif

    call confirm("ATTENTION! Tag: ".l:tag." will be deleted.")

    let l:command .= " -d ".l:tag

    redraw
    echo l:command
    let l:result = system(l:command)

    redraw
    echo "[gitTools.vim] ".l:command
    echo l:result

    if w:gitTools_launchTagDeleteMenu == "yes"
        call gitTools#tag#Delete("")
    endif
endfunction



"=================================================================================
" GIT PUSH (--TAGS)
"=================================================================================

" Perform git push TAG-NAME or git push --tags, or git push --delete TAG-NAME.
" Cmd: Gittpush, Gittpushd
function! gitTools#tag#Push(options, ...)
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    let s:options = a:options

    if len(a:000) >= 1
        call gitTools#tag#PushTag(a:1)
    else
        let l:cmd = "git tag -n ".join(a:000)
        let l:tags = system(l:cmd)

        if l:tags == ""
            call gitTools#tools#Error("ERROR: empty tag list.")
            return
        endif

        if len(split(l:tags, "\n")) == 0
            call gitTools#tools#Error("ERROR: empty tag list.")
            return
        endif

        if a:options =~ "delete"
            call gitTools#menu#SetHeaderColor("r*")
            call gitTools#menu#AddCommentLineColor("#", "r*")

            let l:header = [ "[gitTools] Push delete tag:" ]
            let l:tagsMenu  = l:tags
            let l:tagsMenu .= "# ATTENTION! Tags will be deleted on remote.\n"
        else
            call gitTools#menu#AddCommentLineColor("#", "b*")

            let l:header = [ "[gitTools] Push tag:" ]
            let l:tagsMenu  = "ALL  \t\t\tpush with option --tags\n"
            let l:tagsMenu .= l:tags
        endif

        let l:tagsList = split(l:tagsMenu, "\n")
        let l:callback = "gitTools#tag#PushTag"

        call gitTools#menu#OpenMenu(l:header, l:tagsList, l:callback, "")
    endif
endfunction


function! gitTools#tag#PushTag(tagLine)
    let l:tagList = split(a:tagLine)
    let l:tag = l:tagList[0]

    if s:options =~ "delete"
        if a:tagLine == "" | return | endif

        call confirm("ATTENTION: Tag ".l:tag." will be DELETED!")
        let l:text = "DELETE tag: ".l:tag
        let l:cmd = g:gitTools_gitCmd." push ".g:gitTools_origin." --delete ".l:tag
    else
        if l:tag == "" || l:tag == "ALL"
            let l:text = "Push all tags?"
            let l:cmd = g:gitTools_gitCmd." push --tags"
        else
            let l:text = "Push tag ".l:tag."?"
            let l:cmd = g:gitTools_gitCmd." push ".g:gitTools_origin." ".l:tag
        endif
    endif

    echo l:cmd
    if confirm(l:text, "&yes\n&no", 2) != 1
        return
    endif

    " Lauch command on background with Jobs.vim plugin.
    let l:callback = [ "gitTools#tag#PushEnd", l:cmd ]
    call gitTools#tools#SystemCmd(l:cmd, l:callback, 1)
    redraw
    echo l:cmd." ... in progress on background (Check state with :Jobsl)"
endfunction


" Recover result of git push command launched on background with Jobs.vim plugin.
function! gitTools#tag#PushEnd(cmd, output)
    if !exists('a:output')
        call gitTools#tools#Warn("Git result not found. ".a:cmd)
    endif

    if empty(glob(a:output)) 
        call gitTools#tools#Warn("Git result empty. ".a:cmd)
    endif

    " Open result file
    silent exec "new ".a:output

    " Add header on top
    let l:textList = [ " [gitTools.vim] ".a:cmd." " ]
    let l:text = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
    normal ggO
    put=l:text
    normal ggdd

    " Set buffer parameters
    setl noswapfile
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    setl nonu

    " Change name
    let l:date = strftime("%y%m%d_%H%M")
    let l:filename = "_".l:date."_gitPushTags"

    silent exec("0file")
    silent! exec("file ".l:filename)

    " Resize window
    let l:lastRow = line("$")
    if l:lastRow < winheight(0)
        silent exec("resize ".l:lastRow)
    endif
endfunction

