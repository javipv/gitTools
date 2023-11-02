" Script Name: jobs.vim
" Description: run system commands in background.
" Tool to be used on other plugins to launch system commands in background.
" Includes several commands to check the commands in progress (Jobsl).
" Stop all commands in background (Jobska)
" Choose wich commands in background to stop (Jobsk)
" Showw all commands in background related to current vim window (Jobshw)
" Showw all commands history (Jobshy)
"
" Example:
"    function! svnTools#Blame()
"        let file = expand("%")
"        let name = expand("%:t")
"        let pos = line('.')
"        let ext = s:GetSyntax()
"    
"        let command  = "svn blame -v ".l:file
"        let callback = ["svnTools#SvnBlameEnd", l:pos, l:ext, l:name]
"        let l:async = 1
"    
"        call jobs#RunCmd(a:command, a:callback, l:async, "svn")
"    endfunction
"    
"    function! svnTools#SvnBlameEnd(pos,ext,name,resfile)
"        if exists('a:resfile') && !empty(glob(a:resfile)) 
"            " Process the svn blame file
"        else
"            echo "ERROR. Svn blame empty"
"        endif
"    endfunction
"
" Copyright:   (C) 2017-2020 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: jpLib.vim (optional)
"
" NOTES:
"
" Version:      0.1.2
" Changes:
" 0.1.2 	
" - Rename gloval variable g:loaded_jobs to g:VimJobsLoaded
" 0.1.1 	Fry, 28 May 21.     JPuigdevall
" - New: hide passwords, prevent showing command passwords on the command
"   line, instead replace the password with * characters. Use option: g:jobs_hidePsswd 
"   to dissable it.
" 0.1.0 	Wed, 15 Jul 20.     JPuigdevall
" - Change the callback variable to a list conatining the function name and
"   arguments.
" 0.0.1 	Fry, 22 Jun 20.     JPuigdevall

if exists('g:VimJobsLoaded')
    finish
endif
let g:VimJobsLoaded = 1
let s:save_cpo = &cpo
set cpo&vim

let g:jobs_version = "0.1.2"


"- configuration --------------------------------------------------------------

let g:jobs_version                = get(g:, 'jobs_version', "0.1.0")
let g:jobs_run_in_background      = get(g:, 'jobs_run_in_background', 1)
let g:jobs_return_to_base_window  = get(g:, 'jobs_return_to_base_window', 1)
" Do not show the password on the commands, replace with *******
let g:jobs_hidePsswd              = get(g:, 'jobs_hidePsswd', 1)

if (v:version < 800 || !has("job"))
    " +job option needed for job_start, job_stop, job_status functions.
    " Dissable running job in background
    let g:jobs_run_in_background = 0
endif

let g:jobs_mode            = get(g:, 'jobs_mode', 3)


"- commands -------------------------------------------------------------------

command! -nargs=0 JobsKill    call jobs#Stop()
command! -nargs=0 Jobsk       call jobs#Stop()

command! -nargs=0 JobsList    call jobs#Status()
command! -nargs=0 Jobsl       call jobs#Status()

command! -nargs=0 JobsHist    call jobs#History()
command! -nargs=0 Jobshy      call jobs#History()

command! -nargs=0 JobsListWin call jobs#StatusCurrentWindow()
command! -nargs=0 Jobsw       call jobs#StatusCurrentWindow()

command! -nargs=0 JobsKillAll call jobs#StopAll()
command! -nargs=0 Jobska      call jobs#StopAll()

command! -nargs=0 Jobsh       call jobs#Help()

command! -nargs=? Jobsv       call jobs#Verbose("<args>")

command! -nargs=* Jobs        call jobs#Menu(<f-args>)

" Release functions:
command! -nargs=0  Jobsvba    call jobs#NewVimballRelease()

" Edit plugin:
command! -nargs=0  Jobsedit   call jobs#Edit()


"- mappings -------------------------------------------------------------------
"
if !hasmapto('Jobsl', 'n')
    nmap <unique> <leader>jl :Jobsl<CR>
endif


"- abbreviations -------------------------------------------------------------------

" DEBUG functions: reload plugin
cnoreabbrev _jobsrl    <C-R>=jobs#Reload()<CR>

"- menus -------------------------------------------------------------------

if has("gui_running")
    call jobs#CreateMenus('cn' , '' , ':Jobsl ' , 'Show all running jobs'                     , ':Jobsl')
    call jobs#CreateMenus('cn' , '' , ':Jobsw ' , 'Show all jobs running for current window'  , ':Jobsw')
    call jobs#CreateMenus('cn' , '' , ':Jobshy' , 'Show all jobs history'                     , ':Jobshy')
    call jobs#CreateMenus('cn' , '' , ':'       , '-Sep-'                                      , '')
    call jobs#CreateMenus('cn' , '' , ':Jobsk ' , 'Show the running jobs. Choose job to kill' , ':Jobsk')
    call jobs#CreateMenus('cn' , '' , ':Jobska' , 'Kill all running jobs'                     , ':Jobska')
    call jobs#CreateMenus('cn' , '' , ':'       , '-Sep2-'                                     , '')
    call jobs#CreateMenus('cn' , '' , ':Jobsv ' , 'Change verbosity level'                    , ':Jobsv')
endif




let &cpo = s:save_cpo
unlet s:save_cpo
