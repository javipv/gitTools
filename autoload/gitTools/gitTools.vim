" Script Name: gitTools.vim
 "Description: 
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: jobs.vim
"
" NOTES:
"

"- functions -------------------------------------------------------------------

" Get the plugin reload command
function! gitTools#gitTools#Reload()
    let l:pluginPath = substitute(s:plugin_path, "autoload/gitTools", "plugin", "")
    let s:initialized = 0
    let l:cmd  = ""
    let l:cmd .= "unlet g:loaded_gittools "
    let l:cmd .= " | so ".s:plugin_path."/blame.vim"
    let l:cmd .= " | so ".s:plugin_path."/branch.vim"
    let l:cmd .= " | so ".s:plugin_path."/checkout.vim"
    let l:cmd .= " | so ".s:plugin_path."/cherrypick.vim"
    let l:cmd .= " | so ".s:plugin_path."/commands.vim"
    let l:cmd .= " | so ".s:plugin_path."/commit.vim"
    let l:cmd .= " | so ".s:plugin_path."/conflict.vim"
    let l:cmd .= " | so ".s:plugin_path."/describe.vim"
    let l:cmd .= " | so ".s:plugin_path."/diff.vim"
    let l:cmd .= " | so ".s:plugin_path."/diffFile.vim"
    let l:cmd .= " | so ".s:plugin_path."/diffTools.vim"
    let l:cmd .= " | so ".s:plugin_path."/directory.vim"
    let l:cmd .= " | so ".s:plugin_path."/fetch.vim"
    let l:cmd .= " | so ".s:plugin_path."/generic.vim"
    let l:cmd .= " | so ".s:plugin_path."/grep.vim"
    let l:cmd .= " | so ".s:plugin_path."/fetch.vim"
    let l:cmd .= " | so ".s:plugin_path."/gitTools.vim"
    let l:cmd .= " | so ".s:plugin_path."/help.vim"
    let l:cmd .= " | so ".s:plugin_path."/info.vim"
    let l:cmd .= " | so ".s:plugin_path."/log.vim"
    let l:cmd .= " | so ".s:plugin_path."/menu.vim"
    let l:cmd .= " | so ".s:plugin_path."/merge.vim"
    let l:cmd .= " | so ".s:plugin_path."/misc.vim"
    let l:cmd .= " | so ".s:plugin_path."/remote.vim"
    let l:cmd .= " | so ".s:plugin_path."/show.vim"
    let l:cmd .= " | so ".s:plugin_path."/status.vim"
    let l:cmd .= " | so ".s:plugin_path."/stash.vim"
    let l:cmd .= " | so ".s:plugin_path."/reset.vim"
    let l:cmd .= " | so ".s:plugin_path."/tagvim"
    let l:cmd .= " | so ".s:plugin_path."/tools.vim"
    let l:cmd .= " | so ".s:plugin_path."/utils.vim"
    let l:cmd .= " | so ".s:plugin_path."/vimdiff.vim"
    let l:cmd .= " | so ".l:pluginPath."/gitTools.vim"
    let l:cmd .= " | let g:loaded_gittools = 1"
    return l:cmd
endfunction


" Edit plugin files
" Cmd: Gitedit
function! gitTools#gitTools#Edit()
    let l:plugin = substitute(s:plugin_path, "autoload/gitTools", "plugin", "")
    silent exec("tabnew ".s:plugin)
    silent exec("vnew   ".l:plugin."/".s:plugin_name)
endfunction


function! s:Initialize()
    "call gitTools#tools#SetLogLevel(0)
    let s:jobsRunningDict = {}
endfunction


" Change background/foreground execution of the git commands.
" Arg1: [options]. 
"   - Change current mode when aragument is b/f (f:foreground, b:background).
"   - Show current mode when aragument is '?'.
"   - Toogle the background/foregraund execution mode when no argument provided.
" Commands: Gitbg
function! gitTools#gitTools#BackgroundMode(options)
    if a:options =~ "b" || a:options =~ "f"
        if a:options =~ "f"
            let g:gitTools_runInBackground = 0
        else
            let g:gitTools_runInBackground = 1
        endif
    elseif a:options == ""
        if g:gitTools_runInBackground == 1
            let g:gitTools_runInBackground = 0
        else
            let g:gitTools_runInBackground = 1
        endif
    endif

    if g:gitTools_runInBackground == 1
        let l:mode = "background"
    else
        let l:mode = "foreground"
    endif

    echo "[".s:plugin_name."] run commands in ".l:mode."."
endfunction


"- GUI menu  ------------------------------------------------------------
"
" Create menu items for the specified modes.
function! gitTools#gitTools#CreateMenus(modes, submenu, target, desc, cmd)
    " Build up a map command like
    let plug = a:target
    let plug_start = 'noremap <silent> ' . ' :call GitTools("'
    let plug_end = '", "' . a:target . '")<cr>'

    " Build up a menu command like
    let menuRoot = get(['', 'GitTools', '&GitTools', "&Plugin.&GitTools".a:submenu], 3, '')
    let menu_command = 'menu ' . l:menuRoot . '.' . escape(a:desc, ' ')

    if strlen(a:cmd)
        let menu_command .= '<Tab>' . a:cmd
    endif

    let menu_command .= ' ' . (strlen(a:cmd) ? plug : a:target)

    call gitTools#tools#LogLevel(1, expand('<sfile>'), l:menu_command)

    " Execute the commands built above for each requested mode.
    for mode in (a:modes == '') ? [''] : split(a:modes, '\zs')
        if strlen(a:cmd)
            execute mode . plug_start . mode . plug_end
            call gitTools#tools#LogLevel(1, expand('<sfile>'), "execute ". mode . plug_start . mode . plug_end)
        endif
        " Check if the user wants the menu to be displayed.
        if g:gitTools_mode != 0
            call gitTools#tools#LogLevel(1, expand('<sfile>'), "execute " . mode . menu_command)
            execute mode . menu_command
        endif
    endfor
endfunction


"- Release tools ------------------------------------------------------------
"

" Create a vimball release with the plugin files.
" Commands: Gitvba
function! gitTools#gitTools#NewVimballRelease()
    let text  = ""
    let l:text .= "plugin/gitTools.vim\n"
    let l:text .= "autoload/gitTools/blame.vim\n"
    let l:text .= "autoload/gitTools/branch.vim\n"
    let l:text .= "autoload/gitTools/checkout.vim\n"
    let l:text .= "autoload/gitTools/cherrypick.vim\n"
    let l:text .= "autoload/gitTools/commands.vim\n"
    let l:text .= "autoload/gitTools/commit.vim\n"
    let l:text .= "autoload/gitTools/conflict.vim\n"
    let l:text .= "autoload/gitTools/describe.vim\n"
    let l:text .= "autoload/gitTools/diff.vim\n"
    let l:text .= "autoload/gitTools/diffFile.vim\n"
    let l:text .= "autoload/gitTools/diffTools.vim\n"
    let l:text .= "autoload/gitTools/directory.vim\n"
    let l:text .= "autoload/gitTools/generic.vim\n"
    let l:text .= "autoload/gitTools/grep.vim\n"
    let l:text .= "autoload/gitTools/gitTools.vim\n"
    let l:text .= "autoload/gitTools/help.vim\n"
    let l:text .= "autoload/gitTools/info.vim\n"
    let l:text .= "autoload/gitTools/log.vim\n"
    let l:text .= "autoload/gitTools/menu.vim\n"
    let l:text .= "autoload/gitTools/merge.vim\n"
    let l:text .= "autoload/gitTools/misc.vim\n"
    let l:text .= "autoload/gitTools/remote.vim\n"
    let l:text .= "autoload/gitTools/show.vim\n"
    let l:text .= "autoload/gitTools/status.vim\n"
    let l:text .= "autoload/gitTools/stash.vim\n"
    let l:text .= "autoload/gitTools/tag.vim\n"
    let l:text .= "autoload/gitTools/tools.vim\n"
    let l:text .= "autoload/gitTools/reset.vim\n"
    let l:text .= "autoload/gitTools/utils.vim\n"
    let l:text .= "autoload/gitTools/vimdiff.vim\n"
    let l:text .= "plugin/jobs.vim\n"
    let l:text .= "autoload/jobs.vim\n"

    silent tabedit
    silent put = l:text
    silent! exec '0file | file vimball_files'
    silent normal ggdd

    let l:plugin_name = substitute(s:plugin_name, ".vim", "", "g")
    let l:releaseName = l:plugin_name."_".g:gitTools_version.".vmb"

    let l:workingDir = getcwd()
    silent cd ~/.vim
    silent exec "1,$MkVimball! ".l:releaseName." ./"
    silent exec "vertical new ".l:releaseName
    silent exec "cd ".l:workingDir
    "call gitTools#tools#WindowSplitEnd()
endfunction


"- initializations ------------------------------------------------------------
"
let  s:plugin = expand('<sfile>')
let  s:plugin_path = expand('<sfile>:p:h')
let  s:plugin_name = expand('<sfile>:t')

call s:Initialize()

