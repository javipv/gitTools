" Script Name: gitTools/cherrypick.vim
 "Description: 
"
" Copyright:   (C) 2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: jobs.vim
"
"

"- functions -------------------------------------------------------------------


" Perform cherry picking of commit
" Arg1: cherry-pick options (--edit, --no-commit, etc).
" Arg2: [OPTIONAL] hash commit number.
" Command: Gitcp, GitcpNC, Gitcpe
function! gitTools#cherrypick#CherryPick(options, ...) range
    let l:res = gitTools#tools#isGitAvailable()
    if l:res != 1
        call gitTools#tools#Error("ERROR: ".l:res)
        return
    endif

    if a:0 >= 1
        " Use hash values passed as parameters.
        let l:hash = join(a:000)
    else
        let l:linesNum = a:lastline - a:firstline
        "echom "Range ".l:linesNum." ".a:lastline." ".a:firstline

        if l:linesNum != 0
            " Use line range, scan lines selected and search commit lines.
            " Get hash from selected lines
            let l:hash = ""
            if l:linesNum != 0
                let l:n = str2nr(a:firstline)
                while l:n <= str2nr(a:lastline)
                    let l:line = gitTools#tools#TrimString(getline(l:n))
                    "echom "Line ".l:n.": ".l:line
                    let l:n += 1

                    if l:line =~ "commit"
                        " Get hash from current line
                        let l:lineList = split(l:line)
                        "echom "Add hash: ".l:hash
                        let l:hash .= l:lineList[1]." "
                    endif
                endwhile
            endif
        else
            " Use current line
            let l:line = getline(".")
            if l:line =~ "commit"
                " Get hash from current line
                let l:lineList = split(l:line)
                let l:hash = l:lineList[1]
            else
                " Get hash from word under cursor
                let l:hash = expand("<cword>")
            endif
        endif
    endif

    if l:hash == ""
        call gitTools#tools#Error("Hash number not found")
        return
    endif

    let l:hash = substitute(l:hash, '', "", "g")
    let l:hash = substitute(l:hash, '\n', "", "g")

    " CHeck revision number lenght:
    if len(l:hash) < 11
        call gitTools#tools#Error("Wrong hash number lenght ".l:hash." (expected lenght >= 12) for: '".l:hash."'")
        return
    endif

    " Check contains both numbers and letters:
    let l:numbers = substitute(l:hash, '[^0-9]*', '', 'g')
    let l:letters = substitute(l:hash, '[^a-zA-Z]*', '', 'g')

    if l:numbers == "" || l:letters == ""
        call gitTools#tools#Warn("Found a weird hash number: '".l:hash."'")
        call confirm("Proceed?")
    endif

    let l:optionNames = substitute(a:options, "--", "_", "g")
    let name = "_gitCherryPick__".l:optionNames."__".l:hash.".diff"

    let command  = g:gitTools_gitCmd." cherry-pick ".a:options." ".l:hash

    let l:branch = gitTools#branch#Current()
    echo l:command
    call confirm("Perform cherry piciking to branch: ".l:branch."?")

    let callback = ["gitTools#cherrypick#CherryPickCallback", l:name, l:command]
    call gitTools#tools#SystemCmd(l:command, l:callback, 1)
    redraw
    echo l:command." ... in progress on background (Check state with :Jobsl)"
endfunction


function! gitTools#cherrypick#CherryPickCallback(name, command, resfile)
    if !exists('a:resfile') || empty(glob(a:resfile)) 
        call gitTools#tools#Warn("Git cherry-pick empty")
        return
    endif

    silent exec "new ".a:resfile

    " Add header
    let l:textList = [ " [gitTools.vim] ".a:command ]
    let l:header = gitTools#tools#EncloseOnRectangle(l:textList, "bold", "")
    silent put=l:header

    " Rename buffer
    silent! exec("0file")
    silent! exec("bd! ".a:name)
    silent! exec("file! ".a:name)

    put =  readfile(a:resfile)
    silent exec("normal ggdd")
    silent exec("normal %s///g")
    call   delete(a:resfile)

    let w:split = 1
    call gitTools#tools#WindowSplitEnd()

    " Set buffer parameters
    setl noswapfile
    setl nomodifiable
    setl buflisted
    setl bufhidden=delete
    setl buftype=nofile
    setl nonu

    redraw
endfunction


