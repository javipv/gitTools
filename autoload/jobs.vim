" Script Name: jobs.vim
 "Description: run system commands in background.
"
" Copyright:   (C) 2017-2021 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: jpLib.vim (optional)
"
" NOTES:
"

" Get the plugin reload command
function! jobs#Reload()
    let l:pluginPath = substitute(s:plugin_path, "autoload", "plugin", "")
    let l:autoloadFile = s:plugin_path."/".s:plugin_name
    let l:pluginFile = l:pluginPath."/".s:plugin_name
    return "silent! unlet g:VimJobsLoaded | so ".l:autoloadFile." | so ".l:pluginFile
endfunction


" Edit plugin files
" Cmd: Jobsedit
function! jobs#Edit()
    let l:plugin = substitute(s:plugin_path, "autoload", "plugin", "")
    silent exec("tabnew ".s:plugin)
    silent exec("vnew   ".l:plugin."/".s:plugin_name)
endfunction


function! s:Initialize()
    let s:LogLevel = 0
    let s:jobsRunningDict = {}
    let s:jobsHistoryDict = {}
endfunction


function! s:Error(mssg)
    echohl ErrorMsg | echom s:plugin.": ".a:mssg | echohl None
endfunction


function! s:Warn(mssg)
    echohl WarningMsg | echom a:mssg | echohl None
endfunction


" Debug function. Log message
function! s:LogLevel(level,func,mssg)
    if s:LogLevel >= a:level
        echom "["s:plugin_name." : ".a:func." ] ".a:mssg
    endif
endfunction


" Debug function. Log message and wait user key
function! s:LogLevelStop(level,func,mssg)
    if s:LogLevel >= a:level
        call input("[".s:plugin_name." : ".a:func." ] ".a:mssg." (press key)")
    endif
endfunction


func! jobs#Verbose(level)
    if a:level == ""
        call s:LogLevel(0, expand('<sfile>'), "Verbose level: ".s:LogLevel)
        return
    endif
    let s:LogLevel = a:level
    call s:LogLevel(0, expand('<sfile>'), "Set verbose level: ".s:LogLevel)
endfun


function! s:JobHistList(jobsDict)
    if empty(a:jobsDict)
        call s:Warn("No jobs history found.")
        return 1
    endif
    let jobIdList = [] 
    let n = 1

    let format  = "%' '-3s) %' '-11s %s "
    let format1 = "%' '-3d) %' '-11s \"%s\" "

    echo printf(l:format,  "Pos", "Time", "Cmd")
                "
    for jobList in items(a:jobsDict)
        let jobId    = l:jobList[0]
        let jobCmd   = l:jobList[1][0]
        let starTime = l:jobList[1][5]
        let endTime  = l:jobList[1][8]

        let timeList = reltime([l:starTime, l:endTime])
        let time     = l:timeList[0]
        if l:time >= 3600
            let l:time = l:time / 3600.0
            let timeStr = printf("%.1f", l:time)." h"
        elseif l:time >= 60
            let l:time = l:time / 60.0
            let timeStr = printf("%.1f", l:time)." m"
        else
            let timeStr = printf("%.f", l:time)." s"
        endif

        echo printf(l:format1, l:n, l:timeStr, l:jobCmd)
        let n += 1
    endfor
    return 0
endfunction


function! s:JobList(jobsDict,winId)
    if empty(a:jobsDict)
        call s:Warn("No jobs found running in background.")
        return
    endif
    let jobIdList = [] 
    let n = 1

    let format  = "%' '-3s) %' '-8s %' '-6s %' '-11s %s "
    let format1 = "%' '-3d) %' '-8s %' '-6s %' '-11s \"%s\" "

    echo printf(l:format,  "Pos", "JobId", "Status", "Time", "Cmd")
                "
    for jobList in items(a:jobsDict)
        let jobId    = l:jobList[0]
        let jobCmd   = l:jobList[1][0]
        let winId    = l:jobList[1][1]
        let starTime = l:jobList[1][5]
        let job      = l:jobList[1][7]

        if a:winId != "" && a:winId != l:winId
            continue
        endif

        let status   = job_status(l:job)

        let timeList = reltime([l:starTime, localtime()])
        let time     = l:timeList[0]
        if l:time >= 60
            let timeStr = printf("%.1f", l:time / 60.0)." m"
        else
            let timeStr = printf("%.f", l:time)." s"
        endif

        if l:status == "dead" | echohl ErrorMsg | endif

        echo printf(l:format1, l:n, l:jobId, l:status, l:timeStr, l:jobCmd)

        if l:status == "dead"
            echohl None
            call s:JobCancel(l:job)
        else
            let jobIdList += [ l:jobId ] 
        endif
        let n += 1
    endfor
    return l:jobIdList
endfunction


function! s:JobCancel(jobId)
    if empty(s:jobsRunningDict)
        call s:Warn("No jobs running in backgraund.")
        return
    endif

    if !has_key(s:jobsRunningDict, a:jobId)
        return 1
    endif

    let jobCfgList = s:jobsRunningDict[a:jobId]
    let winId      = l:jobCfgList[1]
    let result     = l:jobCfgList[4]
    let script     = l:jobCfgList[5]
    let name       = l:jobCfgList[6]
    let job        = l:jobCfgList[7]

    " Add to jobs history list
    let l:jobCfgList += [ localtime() ] " Add end time
    call extend(s:jobsHistoryDict, { a:jobId : l:jobCfgList })

    " Remove from the running jobs list
    call remove(s:jobsRunningDict, a:jobId)
    call delete(l:script)
    call delete(l:result)

    if exists("w:jobsWinList")
        let n = index(w:jobsWinList, l:name)
        if l:n >= 0
            call remove(w:jobsWinList, l:n)
        endif
    endif
    if exists("w:jobsTabList")
        let n = index(w:jobsTabList, l:name)
        if l:n >= 0
            call remove(w:jobsTabList, l:n)
        endif
    endif

    silent! call job_stop(l:job)
    call s:Warn("Cancel job ".l:job)
endfunction


" Check if there's a job already running on background for this window
" If name is not empty, search only for jors in bg with the
" provided name runngin on current window.
function! jobs#IsOnWindow(name)
    if !exists("w:jobsWinList")
        return 0
    endif
    if a:name == "" && len(w:jobsWinList) > 0
        return 1
    endif
    let l:n = index(w:jobsWinList, a:name)
    call s:LogLevel(1, expand('<sfile>'), "position:".l:n)
    if (l:n > 0)
        return 1
    endif
    return 0
endfunction


" Check if job already running in background on thi tab
" If name is not empty, search only for jors in bg with the
" provided name runngin on current tab.
function! jobs#IsOnTab(name)
    if !exists("w:jobsTabList")
        return 0
    endif
    if a:name == "" && len(w:jobsTabdDict) > 0
        return 1
    endif
    if (index(w:jobsTabList, a:name) >= 0)
        return 1
    endif
    return 0
endfunction


function! s:MountCallbackCall(list, resfile)
    if len(a:list) == 0
        call s:LogLevel(1, expand('<sfile>'), "Callback: empty")
        return ""
    endif

    let n = 0

    for arg in a:list
        silent! call s:LogLevel(2, expand('<sfile>'), "arg". l:n .": ". l:arg)

        if l:n == 0
            let l:callback = l:arg ."("
        else
            let l:callback .= "\"". l:arg ."\", "
        endif

        let n += 1
        silent! call s:LogLevel(2, expand('<sfile>'), "Callback: ". l:callback)
    endfor

    let l:callback .= "\"". a:resfile ."\")"
    call s:LogLevel(1, expand('<sfile>'), "Callback: ". l:callback)
    return l:callback
endfunction


" Run system command. 
" Arg1: system command.
" Arg2: callback function to process the system results.
" Arg3: if true run the system call on backgraund.
" Arg4: command name, used to search for commands of the same type already running on background.
function! jobs#RunCmd0(command,callbackList,async,name)
    " Make sure we're running VIM version 8 or higher.
    if g:jobs_run_in_background == 0 || a:async == 0
        echo a:command." (fg)"

        " Launch command in foreground
        let l:result = tempname()
        let command = a:command." > ".l:result

        echo "This may take a while..."
        call system(l:command)

        if len(a:callbackList) != 0
            execute "call ". s:MountCallbackCall(a:callbackList,l:result)
        endif
        call delete(l:result)
    else
        if g:jobs_hidePsswd == 1
            " Hide passwords from command line. 
            " Admitted formats: "password MY_PASSWORD", "password=MY_PASSWORD".
            let l:modifiedJobCmd = substitute(a:command, "password[ =]\\([a-zA-Z0-9\-\.\*\/?,;':\"~!@#$%^&*()_+='|]\\)*", "password ********", "")

            " DEBUG: Test substitute command on vim's command line:
            "   echo substitute("cmd --password mypass./*,:12 --option1 --option2", "password[ =]\\([a-zA-Z0-9\-\.\*\/?,;':\"~!@#$%^&*()_+='|]\\)*", "password ********", "")
            "   echo substitute("cmd --password=mypass./*,:12 --option1 --option2", "password[ =]\\([a-zA-Z0-9\-\.\*\/?,;':\"~!@#$%^&*()_+='|]\\)*", "password ********", "")
            "   echo substitute("cmd --password mypass./*,:12", "password[ =]\\([a-zA-Z0-9\-\.\*\/?,;':\"~!@#$%^&*()_+='|]\\)*", "password ********", "")
            "   echo substitute("cmd --password=mypass./*,:12", "password[ =]\\([a-zA-Z0-9\-\.\*\/?,;':\"~!@#$%^&*()_+='|]\\)*", "password ********", "")

            echo l:modifiedJobCmd." (bg)"
        else
            echo a:command." (bg)"
            let l:modifiedJobCmd = a:command
        endif

        let  result = tempname()
        let  script = tempname()
        let  command  = "( ".a:command." ) 2>&1"
        call system("echo '".l:command."' > ".l:script)
        call system("chmod 744 ".l:script)

        call s:LogLevel(1, expand('<sfile>'), l:script)
        call s:LogLevel(1, expand('<sfile>'), system("cat ".l:script))

        let l:callback = s:MountCallbackCall(a:callbackList, l:result)
        "echom "callback: ".l:callback
        call s:LogLevel(1, expand('<sfile>'), "Job start: ".l:modifiedJobCmd." Cmd: ".l:script." File: ".l:result)

        " Launch the job.
        let jobCfgList = [ l:modifiedJobCmd, win_getid(), l:callback, l:result, l:script, localtime(), a:name ]
        call s:LogLevel(1, expand('<sfile>'), "Job start: ".l:modifiedJobCmd." Cmd: ".l:script." File: ".l:result)
        let job = job_start(l:script, {'exit_cb': 'jobs#SystemCmdCallback0', 'out_io': 'file', 'out_name': l:result})
        let l:jobCfgList += [ l:job ]
        let jobId = split(job,' ')[1]
        call extend(s:jobsRunningDict, { l:jobId : l:jobCfgList })
        "sleep 500ms
        sleep

        if job_status(l:job) != "dead" && a:name != ""
            if !exists("w:jobsWinList")
                let w:jobsWinList = []
            endif
            if !exists("w:jobsTabList")
                let w:jobsTabList = []
            endif
            let w:jobsWinList += [ a:name ]
            let w:jobsTabList += [ a:name ]
        "else
            "call s:Error("Job ".a:name." failed (".a:command.")")
        endif
    endif
endfunction


" Check the system command status, launch the callback function on finish.
function! jobs#SystemCmdCallback0(job,message)
    call s:LogLevelStop(1, expand('<sfile>'), "job1:".a:job." mssg:".a:message)
    if job_status(a:job) ==# "run"
        "call s:Error("Job ".a:job." failed. ".a:message)
        return
    endif
    
    let jobId = split(a:job,' ')[1]
    call s:LogLevelStop(1, expand('<sfile>'), "jobId1:".l:jobId)

    if !has_key(s:jobsRunningDict, l:jobId)
        "call s:Error("Job ".a:job." failed. ".a:message)
        return 1
    endif
    
    let jobCfgList = s:jobsRunningDict[l:jobId]
    let command  = l:jobCfgList[0]
    let winId    = l:jobCfgList[1]
    let callback = l:jobCfgList[2]
    let result   = l:jobCfgList[3]
    let script   = l:jobCfgList[4]
    let time     = l:jobCfgList[5]
    let jobName  = l:jobCfgList[6]
    let baseWinId = win_getid()
    
    if l:winId != ""
        cal s:LogLevelStop(1, expand('<sfile>'), "Goto window:".l:winId)
        if win_gotoid(l:winId) != 1
            call s:Error("Can't find the window associated to this job")
            return 1
        endif
    endif

    echom "callback: ".l:callback
    if l:callback != ""
        cal s:LogLevelStop(1, expand('<sfile>'), "Launch callback:".l:callback)
        execute "call ".l:callback
    endif

    " Add to jobs history list
    let l:jobCfgList += [ localtime() ] " Add end time
    call extend(s:jobsHistoryDict, { l:jobId : l:jobCfgList })

    call delete(l:script)
    call delete(l:result)
    " Remove from the running jobs list
    call remove(s:jobsRunningDict, l:jobId)

    if exists("w:jobsWinList")
        let n = index(w:jobsWinList, l:jobName)
        if l:n >= 0
            cal s:LogLevel(1, expand('<sfile>'), "Remove job:".l:n." from win list")
            call remove(w:jobsWinList, l:n)
        endif
    endif
    if exists("w:jobsTabList")
        let n = index(w:jobsTabList, l:jobName)
        if l:n >= 0
            cal s:LogLevel(1, expand('<sfile>'), "Remove job:".l:n." from tab list")
            call remove(w:jobsTabList, l:n)
        endif
    endif
    return 1
endfunction




" Run system command. 
" Arg1: system command.
" Arg2: callback function to process the system results.
" Arg3: if true run the system call on backgraund.
" Arg4: command name, used to search for commands of the same type already running on background.
function! jobs#RunCmd(command,callback,async,name)
    " Make sure we're running VIM version 8 or higher.
    if g:jobs_run_in_background == 0 || a:async == 0
        echo a:command." (fg)"

        " Launch command in foreground
        let l:result = tempname()
        let command = a:command." > ".l:result

        echo "This may take a while..."
        call system(l:command)

        if a:callback != ""
            "echomsg "Launch callback:"s:callback."\"".l:result."\")"
            execute "call ".a:callback."\"".l:result."\")" 
        endif
        call delete(l:result)
    else
        echo a:command." (bg)"

        let  result = tempname()
        let  script = tempname()
        let  command  = "( ".a:command." ) 2>&1"
        call system("echo '".l:command."' > ".l:script)
        call system("chmod 744 ".l:script)

        call s:LogLevel(1, expand('<sfile>'), l:script)
        call s:LogLevel(1, expand('<sfile>'), system("cat ".l:script))

        " Launch the job.
        let jobCfgList = [ a:command, win_getid(), a:callback , l:result, l:script, localtime(), a:name ]
        call s:LogLevel(1, expand('<sfile>'), "Job start: ".a:command." Cmd: ".l:script." File: ".l:result)
        let job = job_start(l:script, {'exit_cb': 'jobs#SystemCmdCallback', 'out_io': 'file', 'out_name': l:result})
        let l:jobCfgList += [ l:job ]
        let jobId = split(job,' ')[1]
        call extend(s:jobsRunningDict, { l:jobId : l:jobCfgList })
        "sleep 500ms
        sleep

        if job_status(l:job) != "dead" && a:name != ""
            if !exists("w:jobsWinList")
                let w:jobsWinList = []
            endif
            if !exists("w:jobsTabList")
                let w:jobsTabList = []
            endif
            let w:jobsWinList += [ a:name ]
            let w:jobsTabList += [ a:name ]
        "else
            "call s:Error("Job ".a:name." failed (".a:command.")")
        endif
    endif
endfunction


" Check the system command status, launch the callback function on finish.
function! jobs#SystemCmdCallback(job,message)
    call s:LogLevelStop(1, expand('<sfile>'), "job1:".a:job." mssg:".a:message)
    if job_status(a:job) ==# "run"
        "call s:Error("Job ".a:job." failed. ".a:message)
        return
    endif
    
    let jobId = split(a:job,' ')[1]
    call s:LogLevelStop(1, expand('<sfile>'), "jobId1:".l:jobId)

    if !has_key(s:jobsRunningDict, l:jobId)
        "call s:Error("Job ".a:job." failed. ".a:message)
        return 1
    endif
    
    let jobCfgList = s:jobsRunningDict[l:jobId]
    let command  = l:jobCfgList[0]
    let winId    = l:jobCfgList[1]
    let callback = l:jobCfgList[2]
    let result   = l:jobCfgList[3]
    let script   = l:jobCfgList[4]
    let time     = l:jobCfgList[5]
    let jobName  = l:jobCfgList[6]
    let baseWinId = win_getid()
    
    if l:winId != ""
        cal s:LogLevelStop(1, expand('<sfile>'), "Goto window:".l:winId)
        if win_gotoid(l:winId) != 1
            call s:Error("Can't find the window associated to this job")
            return 1
        endif
    endif

    if l:callback != ""
        cal s:LogLevelStop(1, expand('<sfile>'), "Launch callback:".l:callback."\"".l:result."\")")
        execute "call ".l:callback."\"".l:result."\")" 
    endif

    " Add to jobs history list
    let l:jobCfgList += [ localtime() ] " Add end time
    call extend(s:jobsHistoryDict, { l:jobId : l:jobCfgList })

    call delete(l:script)
    call delete(l:result)
    " Remove from the running jobs list
    call remove(s:jobsRunningDict, l:jobId)

    if exists("w:jobsWinList")
        let n = index(w:jobsWinList, l:jobName)
        if l:n >= 0
            cal s:LogLevel(1, expand('<sfile>'), "Remove job:".l:n." from win list")
            call remove(w:jobsWinList, l:n)
        endif
    endif
    if exists("w:jobsTabList")
        let n = index(w:jobsTabList, l:jobName)
        if l:n >= 0
            cal s:LogLevel(1, expand('<sfile>'), "Remove job:".l:n." from tab list")
            call remove(w:jobsTabList, l:n)
        endif
    endif
    return 1
endfunction


" Show list with all jobs running in background.
" Stop the selected job.
function! jobs#Stop()
    if empty(s:jobsRunningDict)
        call s:Warn("No jobs running in backgraund.")
        return
    endif

    let jobIdList = s:JobList(s:jobsRunningDict,"")
    let pos = input("Remove position: ")
    echo " "

    for n in split(l:pos)
        if l:n != "" && l:n <= len(l:jobIdList)
            let n -= 1 
            call s:JobCancel(l:jobIdList[l:n])
        endif
    endfor
    return
endfunction


" Show list with all jobs running in background.
function! jobs#Status()
    if empty(s:jobsRunningDict)
        call s:Warn("No jobs running in backgraund.")
        return
    endif
    let jobIdList =  s:JobList(s:jobsRunningDict,"")
    call input("")
endfunction


" Show list with all jobs running in background on currnet window
function! jobs#StatusCurrentWindow()
    if empty(s:jobsRunningDict)
        call s:Warn("No jobs running in backgraund.")
        return
    endif
    let jobIdList = s:JobList(s:jobsRunningDict,win_getid())
    call input("")
endfunction


" Show job history
function! jobs#History()
    if empty(s:jobsHistoryDict)
        call s:Warn("No jobs history found.")
        return
    endif
    let jobIdList =  s:JobHistList(s:jobsHistoryDict)
    call input("")
endfunction


" Stop all jobs running in background
function! jobs#StopAll()
    let n = 0
    if !empty(s:jobsRunningDict)
        for jobList in items(s:jobsRunningDict)
            call s:JobCancel(l:jobList[0])
            let n += 1
        endfor
    endif
    let s:jobsRunningDict = {}
    let w:jobsWinList = []
    echo "Jobs stopped:".l:n
endfunction


function! jobs#Help()
    echo "jobs.vim"
    echo "  "
    echo " Jobsl  : show all jobs running."
    echo " Jobsw  : show all jobs running on current window."
    echo " Jobshy : show jobs history."
    echo " Jobsk  : show all jobs running, kill selected one."
    echo " Jobska : kill all running jobs."
    echo " Jobsv  : change verbosity level (0 is default)."
    echo " "
    call input("(Press key)")
endfunction


function! jobs#Menu(...)
    " Check jpLib.vim plugin installed
    if empty(glob(s:plugin_path."/jpLib.vim"))
        call s:Error("missing plugin jpLib.vim (".s:plugin_path."/jpLib.vim".")")
        call input("")
    endif

    let l:selection = ""
    if a:0 >= 1
        let l:selection = a:1
    endif

    let l:options  = []
    let l:options += [ [ "#jobs.vim commands:"                            , ""        , "" ] ]
    let l:options += [ [ "Show all jobs running (Jobsl)"                  , "Jobsl" , "" ] ]
    let l:options += [ [ "Show all jobs running on current window (Jobsw)", "Jobsw" , "" ] ]
    let l:options += [ [ "Show jobs history (Jobshy)"                     , "Jobshy", "" ] ]
    let l:options += [ [ "Show all jobs running kill selected one (Jobsk)", "Jobsk" , "" ] ]
    let l:options += [ [ "Kill all running jobs (Jobska)"                 , "Jobska", "" ] ]
    let l:options += [ [ "Change verbosity level. 0 is default (Jobsv)"   , "Jobsv"   , "" ] ]

    call jpLib#OptionsMenu(l:options, l:selection)
endfunction


" Create menu items for the specified modes.
function! jobs#CreateMenus(modes, submenu, target, desc, cmd)
    "let s:LogLevel = 4
    " Build up a map command like
    let plug = a:target
    let plug_start = 'noremap <silent> ' . ' :call JobsMenu("'
    let plug_end = '", "' . a:target . '")<cr>'

    " Build up a menu command like
    let menuRoot = get(['', 'JobsMenu', '&JobsUtils', "&Plugin.&JobsUtils".a:submenu], 3, '')
    let menu_command = 'menu ' . l:menuRoot . '.' . escape(a:desc, ' ')

    if strlen(a:cmd)
        let menu_command .= '<Tab>' . a:cmd
    endif

    let menu_command .= ' ' . (strlen(a:cmd) ? plug : a:target)
    "let menu_command .= ' ' . (strlen(a:cmd) ? a:target)

    call s:LogLevel(1, expand('<sfile>'), "menu_command :".l:menu_command)

    " Execute the commands built above for each requested mode.
    for mode in (a:modes == '') ? [''] : split(a:modes, '\zs')
        if strlen(a:cmd)
            execute mode . plug_start . mode . plug_end
            call s:LogLevel(1, expand('<sfile>'), "execute ". mode . plug_start . mode . plug_end)
        endif
        " Check if the user wants the menu to be displayed.
        if g:jobs_mode != 0
            call s:LogLevel(1, expand('<sfile>'), "execute " . mode . menu_command)
            execute mode . menu_command
        endif
    endfor
    "let s:LogLevel = 0
endfunction


"- Release tools ------------------------------------------------------------
"

" Create a vimball release with the plugin files.
" Commands: Jobsvba
function! jobs#NewVimballRelease()
    let text  = ""
    let text .= "plugin/jobs.vim\n"
    let text .= "autoload/jobs.vim\n"

    silent tabedit
    silent put = l:text
    silent! exec '0file | file vimball_files'
    silent normal ggdd

    let l:plugin_name = substitute(s:plugin_name, ".vim", "", "g")
    let l:releaseName = l:plugin_name."_".g:jobs_version.".vmb"

    let l:workingDir = getcwd()
    silent cd ~/.vim
    silent exec "1,$MkVimball! ".l:releaseName." ./"
    silent exec "vertical new ".l:releaseName
    silent exec "cd ".l:workingDir
endfunction




"- initializations ------------------------------------------------------------

let  s:plugin = expand('<sfile>')
let  s:plugin_path = expand('<sfile>:p:h')
let  s:plugin_name = expand('<sfile>:t')

if !exists("s:initialized")
    call s:Initialize()
    let s:initialized = 1
endif

