" Script Name: gitTools/menu.vim
 "Description: 
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies:
"
"

"- functions -------------------------------------------------------------------


" Open menu to manage a selection list.
" Arg1: menu header to be displayed, not selectable.
" Arg2: list of selectable options.
" Arg3: callback to be called, expected function is: callbackName(selectedOption).
" Arg4: default text to be selected, place cursor on line matching this text.
function! gitTools#menu#OpenMenu(headerList, optionsList, callbackFunction, selectText)

    let s:GitToolsMenuList = a:optionsList
    let s:GitToolsMenuCallback = a:callbackFunction
    let s:GitToolsHeaderLines = len(a:headerList)
    let s:GitToolsMenuReturnWinNr = win_getid()

    if s:gitToolsMenuDefaultWindowPos != ""
        call gitTools#tools#WindowSplitMenu(s:gitToolsMenuDefaultWindowPos)
        call gitTools#tools#WindowSplit()
    else
        let w:winSize = winheight(0)
        silent new
    endif

    "----------------------------------
    " Write down each header lines:
    "----------------------------------
    if a:headerList != []
        for l:line in a:headerList
            silent put = l:line

            if exists('g:HiLoaded')
                let l:colorId = ""

                if g:gitTools_menu_headerColor != ""
                    let l:colorId = g:gitTools_menu_headerColor
                endif

                if s:GitToolsMenuHeaderColor != ""
                    let l:colorId = s:GitToolsMenuHeaderColor
                endif

                " Colorize header lines.
                if l:line != "" && l:colorId != ""
                    let l:text = substitute(l:line, '[', '\\[', "g")

                    let g:HiCheckPatternAvailable = 0
                    silent! call hi#config#PatternColorize(l:text, l:colorId)
                    let g:HiCheckPatternAvailable = 1
                endif
            endif
        endfor
        let s:GitToolsMenuHeaderColor = ""
    else
        silent put = "Select option:"
    endif

    let l:pos = s:GitToolsHeaderLines + 1
    let i = 0

    "----------------------------------
    " Write down each menu line:
    "----------------------------------
    let l:defaultLineText = ""

    for l:line in a:optionsList
        let isComment = "no"

        " Check if line is a comment:
        for l:list in s:GitToolsMenuCommentsList
            if matchstr(l:line, "^".l:list[0]) != ""
                " Remove comment word.
                let l:line = substitute(l:line, "^".l:list[0], "", "")

                let isComment = "yes"
                break
            endif
        endfor

        "silent put = l:line
        "let i += 1

        if l:isComment == "yes"
            " Apply comment color:
            if exists('g:HiLoaded')
                let g:HiCheckPatternAvailable = 0
                silent! call hi#config#PatternColorize(l:line, l:list[1])
                let g:HiCheckPatternAvailable = 1
            endif
        else
            let i += 1

            if s:gitToolsMenuShowLineNumbers == "yes"
                " Check if curren option is the default one.
                if l:line == a:selectText
                    let l:pos = l:i + s:GitToolsHeaderLines
                    let l:line = "> ".l:i.") ".l:line
                    let l:defaultLineText = l:line
                else
                    let l:line = "  ".l:i.") ".l:line
                endif

                let s:gitToolsMenuShowLineNumbers = "yes"
            endif
        endif

        silent put = l:line
    endfor

    "----------------------------------
    " Change window properties and title
    "----------------------------------
    silent normal ggdd
    setl nowrap
    set buflisted
    set bufhidden=delete
    set buftype=nofile
    setl noswapfile
    set cursorline
    setl nomodifiable
    silent! exec '0file | file _gitTools_menu_'

    " Move window to bottom
    if s:gitToolsMenuDefaultWindowPos == ""
        wincmd J
    endif

    "----------------------------------
    " Resize window depending on content.
    "----------------------------------
    if s:gitToolsMenuDefaultWindowPos != ""
        call gitTools#tools#WindowSplitEnd()
    else
        if exists("g:GitTools_menuMaxLines")
            if l:i < g:GitTools_menuMaxLines
                let l:n = l:i + 2
                silent exe "resize ".l:n
            else
                silent exe "resize ".g:GitTools_menuMaxLines
            endif
        endif
    endif

    "----------------------------------
    " Colorize default selected line.
    "----------------------------------
    let l:colors = g:gitTools_menu_defaultLineColor.s:GitToolsMenuDefaultLineColor

    if exists('g:HiLoaded') && l:colors != "" && l:defaultLineText != ""
        let l:colorId = ""

        if g:gitTools_menu_defaultLineColor != ""
            let l:colorId = g:gitTools_menu_defaultLineColor
        endif

        if s:GitToolsMenuDefaultLineColor != ""
            let l:color = s:GitToolsMenuDefaultLineColor
        endif

        if l:defaultLineText != "" && l:colorId != ""
            "let l:line = getline(".")
            let l:text = substitute(l:defaultLineText, '[', '\\[', "g")

            let g:HiCheckPatternAvailable = 0
            silent! call hi#config#PatternColorize(l:text, l:colorId)
            let g:HiCheckPatternAvailable = 1
        endif

        let s:GitToolsMenuDefaultLineColor = ""
    endif

    "----------------------------------
    " Colorize special patterns.
    "----------------------------------
    if exists('g:HiLoaded')
        for l:config in s:gitToolsMenuColorList
            let l:list = split(l:config)
            let l:pattern = l:list[0]
            let l:color = l:list[1]

            if l:pattern != "" && l:color != ""
                let g:HiCheckPatternAvailable = 0
                silent! call hi#config#PatternColorize(l:pattern, l:color)
                let g:HiCheckPatternAvailable = 1
            endif
        endfor
        let s:gitToolsMenuColorList = []
    endif

    if exists('g:HiLoaded')
        silent! call hi#hi#Refresh()
    endif

    "----------------------------------
    " Highlight using search highlight the default selected line.
    "----------------------------------
    if g:gitTools_menu_highlightDefaultLine == "yes" || s:GitToolsMenuHighlightDefaultLine == "yes"
        let l:line = getline(".")
        "let l:pattern = "^".l:line."$"
        let l:pattern = l:line

        silent! call search(l:pattern, 'W', 0, 500)
        let @/=l:pattern
        silent! hlsearch
        silent! normal n

        let s:GitToolsMenuHighlightDefaultLine = "no"
    endif

    silent call s:MapKeys()

    augroup GitToolsMenuAutoCmd
        silent autocmd!
        silent exec "silent autocmd! winleave _gitTools_menu_ call gitTools#menu#UnmapKeysAndQuit()"
    augroup END

    "----------------------------------
    " Position cursor on default line.
    "----------------------------------
    silent exe "normal gg".l:pos."G"
endfunction


function! gitTools#menu#SetHeaderColor(color)
    let s:GitToolsMenuHeaderColor = a:color
endfunction


function! gitTools#menu#SetDefaultLineColor(color)
    let s:GitToolsMenuDefaultLineColor = a:color
endfunction


function! gitTools#menu#SetHighlightDefaultLine(state)
    let s:GitToolsMenuHighlightDefaultLine = a:state
endfunction


function! gitTools#menu#AddCommentLineColor(word, color)
    let s:GitToolsMenuCommentsList += [[ a:word, a:color ]]
endfunction


function! gitTools#menu#AddPatternColor(pattern, color)
    let s:gitToolsMenuColorList += [ a:pattern." ".a:color ]
endfunction


function! gitTools#menu#ShowLineNumbers(status)
    let s:gitToolsMenuShowLineNumbers = a:status
endfunction


function! gitTools#menu#SelectWindowPosition(defaultWindowPos)
    let s:gitToolsMenuDefaultWindowPos = a:defaultWindowPos
endfunction



" Select option.
function! gitTools#menu#Select()
    "echom "gitTools#menu#Select()"
    redraw

    if line(".") <= s:GitToolsHeaderLines
        call gitTools#tools#Warn("Line not selectable")
        return
    endif

    let l:pos = line(".") - s:GitToolsHeaderLines - 1

    let l:text = s:GitToolsMenuList[l:pos]
    let l:text = substitute(l:text, "\"", "\\\"", "g")

    for l:list in s:GitToolsMenuCommentsList
        if l:text =~ l:list[0]
            call gitTools#tools#Warn("Line not selectable")
            return
        endif
    endfor

    if l:text == ""
        call gitTools#tools#Warn("Empty line")
        return
    endif

    let l:callback = s:GitToolsMenuCallback

    silent call gitTools#menu#UnmapKeysAndQuit()

    "echom "gitTools#menu#Select() call ".l:callback."(\"".l:text."\")"
    exec("call ".l:callback."('".l:text."')")
endfunction


function! s:MapKeys()
    "echom "s:MapKeys()"
    silent! nmap <ENTER> :call gitTools#menu#Select()<CR>
    silent! nmap q       :call gitTools#menu#UnmapKeysAndQuit()<CR>
endfunction


function! s:UnmapKeys()
    "echom "s:UnmapKeys()"
    silent! nunmap <ENTER>
    silent! nunmap q
endfunction


function! gitTools#menu#UnmapKeysAndQuit()
    "echom "gitTools#menu#UnmapKeysAndQuit()"

    if expand("%") == "_gitTools_menu_"
        "echom "gitTools#menu#UnmapKeysAndQuit() quit"
        call s:UnmapKeys()
        silent! quit!
    endif

    let s:GitToolsMenuCommentsList = []
    let s:gitToolsMenuDefaultWindowPos = ""
    redraw

    " Return to the original window.
    call win_gotoid(s:GitToolsMenuReturnWinNr)
endfunction

"call gitTools#menu#Open("Select branch", ["branch 1", "branch 2"], "gitTools#menu#Test")
"call gitTools#menu#Test("branch 2")
"function! gitTools#menu#Test(text)
    "echom "gitTools#menu#Test(".a:text.")"
    "call confirm("callback: ".a:text)
"endfunction


"- variables -------------------------------------------------------------------

let s:GitToolsMenuCommentsList = []
"let s:GitToolsMenuHeaderColor = "b*"
"let s:GitToolsMenuDefaultLineColor = "y*"
let s:GitToolsMenuHeaderColor = ""
let s:GitToolsMenuDefaultLineColor = ""
let s:GitToolsMenuHighlightDefaultLine = "no" " yes/no
let s:gitToolsMenuColorList = []
let s:gitToolsMenuShowLineNumbers = "yes"
let s:gitToolsMenuDefaultWindowPos = ""

